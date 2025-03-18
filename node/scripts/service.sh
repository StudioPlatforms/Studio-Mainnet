#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Service Configuration
# 
# This script sets up systemd services for the validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to setup systemd services
setup_services() {
    log "STEP" "Setting up systemd services"
    
    # Create systemd directory
    mkdir -p "$HOME/.config/systemd/user"
    
    # Create start script
    create_start_script
    
    # Create systemd service file
    log "INFO" "Creating systemd service file"
    cat > "$HOME/.config/systemd/user/studio-validator.service" << EOF
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=$SCRIPTS_DIR/node/scripts/start.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

# Ensure data integrity during shutdown
KillSignal=SIGINT
TimeoutStopSec=300

[Install]
WantedBy=default.target
EOF
    
    # Create monitoring service file
    if [ "$MONITORING" = true ]; then
        log "INFO" "Creating monitoring service file"
        cat > "$HOME/.config/systemd/user/studio-validator-monitor.service" << EOF
[Unit]
Description=Studio Blockchain Validator Monitoring
After=studio-validator.service
Wants=studio-validator.service

[Service]
Type=simple
ExecStart=$SCRIPTS_DIR/health-check.sh
Restart=always
RestartSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
    fi
    
    # Reload systemd
    log "INFO" "Reloading systemd"
    systemctl --user daemon-reload
    
    # Enable services
    log "INFO" "Enabling services"
    systemctl --user enable studio-validator.service
    
    if [ "$MONITORING" = true ]; then
        systemctl --user enable studio-validator-monitor.service
    fi
    
    # Create systemd service files for root installation
    create_root_services
    
    log "INFO" "Service setup completed"
}

# Function to create start script
create_start_script() {
    log "INFO" "Creating start script"
    
    local start_script="$SCRIPTS_DIR/node/scripts/start.sh"
    
    cat > "$start_script" << EOF
#!/bin/bash

# Studio Blockchain Validator Start Script

# Load configuration
DATADIR="$DATADIR"
NETWORK_ID="$NETWORK_ID"
PORT="$PORT"
RPC_PORT="$RPC_PORT"
WS_PORT="$WS_PORT"
VALIDATOR_ACCOUNT="\$(cat "$DATADIR/validator-address.txt" 2>/dev/null || echo "")"
PASSWORD_FILE="$DATADIR/password.txt"

# Check if validator account is set
if [ -z "\$VALIDATOR_ACCOUNT" ]; then
    echo "Error: Validator account not found"
    exit 1
fi

# Check if password file exists
if [ ! -f "\$PASSWORD_FILE" ]; then
    echo "Error: Password file not found"
    exit 1
fi

# Create a backup of the data directory before starting
BACKUP_DIR="$BACKUP_DIR"
mkdir -p "\$BACKUP_DIR/startup"
TIMESTAMP=\$(date +%Y%m%d-%H%M%S)
echo "Creating backup of blockchain data..."
tar --exclude="\$DATADIR/geth/chaindata/ancient" \
    --exclude="\$DATADIR/geth/lightchaindata/ancient" \
    -czf "\$BACKUP_DIR/startup/blockchain-data-\$TIMESTAMP.tar.gz" \
    -C "\$(dirname "\$DATADIR")" "\$(basename "\$DATADIR")"
echo "Backup created at \$BACKUP_DIR/startup/blockchain-data-\$TIMESTAMP.tar.gz"

# Keep only the last 5 startup backups to save space
ls -t "\$BACKUP_DIR/startup/blockchain-data-"*.tar.gz | tail -n +6 | xargs -r rm

# Start the blockchain node
echo "Starting Studio Blockchain Validator Node..."
echo "Validator address: \$VALIDATOR_ACCOUNT"

# Check for ghost state issues before starting
if [ -d "\$DATADIR/geth/clique" ]; then
    echo "Checking for potential ghost state issues..."
    SNAPSHOT_FILES=\$(find "\$DATADIR/geth/clique" -name "*.snap" | wc -l)
    if [ "\$SNAPSHOT_FILES" -gt 1 ]; then
        echo "Warning: Multiple Clique snapshot files detected. This may indicate a potential ghost state issue."
    fi
fi

# Start geth with all necessary parameters
exec geth --datadir "\$DATADIR" \
--networkid "\$NETWORK_ID" \
--port "\$PORT" \
--http \
--http.addr "127.0.0.1" \
--http.port "\$RPC_PORT" \
--http.api "eth,net,web3,txpool,debug,clique" \
--ws \
--ws.addr "127.0.0.1" \
--ws.port "\$WS_PORT" \
--ws.api "eth,net,web3,txpool,debug,clique" \
--mine \
--miner.gasprice "0" \
--miner.gaslimit "30000000" \
--allow-insecure-unlock \
--unlock "\$VALIDATOR_ACCOUNT" \
--password "\$PASSWORD_FILE" \
--syncmode "full" \
--miner.etherbase "\$VALIDATOR_ACCOUNT" \
--rpc.allow-unprotected-txs \
--txpool.pricelimit "0" \
--txpool.accountslots "16" \
--txpool.globalslots "16384" \
--txpool.accountqueue "64" \
--txpool.globalqueue "1024" \
--metrics \
--metrics.addr "127.0.0.1" \
--metrics.port "6060" \
--verbosity 3
EOF
    
    chmod +x "$start_script"
}

# Function to create systemd service files for root installation
create_root_services() {
    log "INFO" "Creating systemd service files for root installation"
    
    # Create systemd directory
    mkdir -p "$SCRIPTS_DIR/systemd"
    
    # Create geth service file
    cat > "$SCRIPTS_DIR/systemd/geth-studio-validator.service" << EOF
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
ExecStart=$SCRIPTS_DIR/node/scripts/start.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=geth-studio-validator
LimitNOFILE=65536
LimitNPROC=65536

# Ensure data integrity during shutdown
KillSignal=SIGINT
TimeoutStopSec=300

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF
    
    # Create monitoring service file
    if [ "$MONITORING" = true ]; then
        cat > "$SCRIPTS_DIR/systemd/blockchain-monitor-validator.service" << EOF
[Unit]
Description=Studio Blockchain Validator Monitoring Service
After=geth-studio-validator.service
Wants=geth-studio-validator.service

[Service]
Type=simple
User=$USER
ExecStart=$SCRIPTS_DIR/health-check.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=blockchain-monitor-validator

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Create installation instructions
    cat > "$SCRIPTS_DIR/systemd/README.md" << EOF
# Systemd Service Installation

To install the systemd services as root, run the following commands:

1. Copy the service files to the systemd directory:
   \`\`\`
   sudo cp geth-studio-validator.service /etc/systemd/system/
   sudo cp blockchain-monitor-validator.service /etc/systemd/system/
   \`\`\`

2. Reload systemd:
   \`\`\`
   sudo systemctl daemon-reload
   \`\`\`

3. Enable and start the services:
   \`\`\`
   sudo systemctl enable geth-studio-validator.service
   sudo systemctl start geth-studio-validator
   
   sudo systemctl enable blockchain-monitor-validator.service
   sudo systemctl start blockchain-monitor-validator
   \`\`\`

4. Check the status of the services:
   \`\`\`
   sudo systemctl status geth-studio-validator
   sudo systemctl status blockchain-monitor-validator
   \`\`\`

5. View the logs:
   \`\`\`
   sudo journalctl -u geth-studio-validator -f
   sudo journalctl -u blockchain-monitor-validator -f
   \`\`\`
EOF
}

# Function to start services
start_services() {
    log "STEP" "Starting services"
    
    # Start validator service
    log "INFO" "Starting validator service"
    systemctl --user start studio-validator.service
    
    # Start monitoring service
    if [ "$MONITORING" = true ]; then
        log "INFO" "Starting monitoring service"
        systemctl --user start studio-validator-monitor.service
    fi
    
    # Check service status
    log "INFO" "Checking service status"
    systemctl --user status studio-validator.service
    
    if [ "$MONITORING" = true ]; then
        systemctl --user status studio-validator-monitor.service
    fi
    
    log "INFO" "Services started"
}

# Function to stop services
stop_services() {
    log "STEP" "Stopping services"
    
    # Stop monitoring service
    if [ "$MONITORING" = true ]; then
        log "INFO" "Stopping monitoring service"
        systemctl --user stop studio-validator-monitor.service
    fi
    
    # Stop validator service
    log "INFO" "Stopping validator service"
    systemctl --user stop studio-validator.service
    
    log "INFO" "Services stopped"
}

# Function to check service status
check_service_status() {
    log "STEP" "Checking service status"
    
    # Check validator service status
    log "INFO" "Validator service status:"
    systemctl --user status studio-validator.service
    
    # Check monitoring service status
    if [ "$MONITORING" = true ]; then
        log "INFO" "Monitoring service status:"
        systemctl --user status studio-validator-monitor.service
    fi
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If no arguments are provided, setup services
    if [ $# -eq 0 ]; then
        setup_services
    else
        # Otherwise, parse arguments
        case "$1" in
            setup)
                setup_services
                ;;
            start)
                start_services
                ;;
            stop)
                stop_services
                ;;
            restart)
                stop_services
                start_services
                ;;
            status)
                check_service_status
                ;;
            *)
                log "ERROR" "Unknown command: $1"
                echo "Usage: $0 [setup|start|stop|restart|status]"
                exit 1
                ;;
        esac
    fi
fi
