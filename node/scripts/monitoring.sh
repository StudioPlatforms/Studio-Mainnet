#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Monitoring
# 
# This script sets up monitoring for the validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to setup monitoring
setup_monitoring() {
    if [ "$MONITORING" != true ]; then
        log "INFO" "Monitoring setup skipped"
        return
    fi
    
    log "STEP" "Setting up monitoring"
    
    # Create monitoring directory
    local monitoring_dir="$SCRIPTS_DIR/monitoring"
    mkdir -p "$monitoring_dir"
    
    # Create Prometheus configuration
    log "INFO" "Creating Prometheus configuration"
    cat > "$monitoring_dir/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'geth'
    static_configs:
      - targets: ['localhost:6060']
        labels:
          instance: '$VALIDATOR_NAME'

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: '$VALIDATOR_NAME'
EOF
    
    # Create node exporter systemd service
    log "INFO" "Creating node exporter systemd service"
    cat > "$monitoring_dir/node-exporter.service" << EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=$USER
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Create monitoring setup instructions
    log "INFO" "Creating monitoring setup instructions"
    cat > "$monitoring_dir/README.md" << EOF
# Monitoring Setup Instructions

This directory contains configuration files for monitoring your validator node.

## Prometheus

1. Copy the Prometheus configuration:
   \`\`\`
   sudo cp prometheus.yml /etc/prometheus/prometheus.yml
   \`\`\`

2. Restart Prometheus:
   \`\`\`
   sudo systemctl restart prometheus
   \`\`\`

## Node Exporter

1. Copy the node exporter service:
   \`\`\`
   sudo cp node-exporter.service /etc/systemd/system/node-exporter.service
   \`\`\`

2. Enable and start the service:
   \`\`\`
   sudo systemctl enable node-exporter
   sudo systemctl start node-exporter
   \`\`\`

## Geth Metrics

Geth metrics are enabled by default with the \`--metrics\` flag in the validator service.

## Grafana Dashboard

1. Install Grafana:
   \`\`\`
   sudo apt-get install -y grafana
   sudo systemctl enable grafana-server
   sudo systemctl start grafana-server
   \`\`\`

2. Access Grafana at http://localhost:3000 (default credentials: admin/admin)

3. Add Prometheus as a data source:
   - URL: http://localhost:9090
   - Access: Server

4. Import the Ethereum Node dashboard (ID: 14053) or create your own.
EOF
    
    # Create health check script
    create_health_check_script
    
    log "INFO" "Monitoring setup completed. See $monitoring_dir/README.md for instructions."
}

# Function to create health check script
create_health_check_script() {
    log "STEP" "Creating health check script"
    
    local health_check_script="$SCRIPTS_DIR/health-check.sh"
    
    log "INFO" "Creating health check script at $health_check_script"
    cat > "$health_check_script" << EOF
#!/bin/bash

# Studio Blockchain Validator Health Check Script

# Configuration
DATADIR="$DATADIR"
VALIDATOR_ACCOUNT="\$(cat "$DATADIR/validator-address.txt" 2>/dev/null || echo "")"
EMAIL=""
DISCORD_WEBHOOK=""

# Function to send notification
send_notification() {
    local subject="\$1"
    local message="\$2"
    
    # Send email if configured
    if [ -n "\$EMAIL" ]; then
        echo "\$message" | mail -s "\$subject" "\$EMAIL"
    fi
    
    # Send Discord notification if configured
    if [ -n "\$DISCORD_WEBHOOK" ]; then
        curl -H "Content-Type: application/json" -d "{\"content\":\"\$subject: \$message\"}" "\$DISCORD_WEBHOOK"
    fi
    
    # Log to syslog
    logger -t "validator-health" "\$subject: \$message"
    
    # Print to console
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$subject: \$message"
}

# Check if validator address is set
if [ -z "\$VALIDATOR_ACCOUNT" ]; then
    send_notification "Validator Error" "Validator address not found"
    exit 1
fi

# Check if geth is running
if ! pgrep -f "geth.*--datadir $DATADIR" > /dev/null; then
    send_notification "Validator Down" "Geth process is not running"
    exit 1
fi

# Check if geth IPC file exists
if [ ! -S "$DATADIR/geth.ipc" ]; then
    send_notification "Validator Error" "Geth IPC file not found"
    exit 1
fi

# Create a temporary file for the JavaScript code
JS_FILE=\$(mktemp)

# Write JavaScript code to check node health
cat > "\$JS_FILE" << JSEOF
// Check if node is syncing
var syncing = eth.syncing;
if (syncing) {
    console.log("WARN: Node is syncing. Current block: " + eth.blockNumber + ", Highest block: " + syncing.highestBlock);
    exit();
}

// Check block height
var blockNumber = eth.blockNumber;
console.log("Current block: " + blockNumber);

// Check if node is mining
var mining = eth.mining;
console.log("Mining: " + mining);
if (!mining) {
    console.log("ERROR: Node is not mining");
    exit();
}

// Check peer count
var peerCount = net.peerCount;
console.log("Peer count: " + peerCount);
if (peerCount < 1) {
    console.log("WARN: No peers connected");
}

// Check if validator is in signers list
var signers = clique.getSigners();
var isValidator = signers.includes("\$VALIDATOR_ACCOUNT");
console.log("Is validator: " + isValidator);
if (!isValidator) {
    console.log("ERROR: Node is not in the validators list");
    exit();
}

// Check recent blocks signed by this validator
var validatorAddress = "\$VALIDATOR_ACCOUNT";
var blocksInEpoch = 30;
var blocksSigned = 0;

for (var i = 0; i < blocksInEpoch; i++) {
    if (blockNumber - i < 0) break;
    var block = eth.getBlock(blockNumber - i);
    if (block && block.miner === validatorAddress) {
        blocksSigned++;
    }
}

console.log("Blocks signed in last " + blocksInEpoch + " blocks: " + blocksSigned);
if (blocksSigned === 0) {
    console.log("WARN: No blocks signed recently");
}

// Check if there are any pending transactions
var pendingTxCount = txpool.status.pending;
console.log("Pending transactions: " + pendingTxCount);

// Check system resources
var memInfo = debug.memStats();
console.log("Memory usage: " + Math.round(memInfo.allocs / 1024 / 1024) + " MB");

// Check if we're the only validator
if (signers.length === 1 && isValidator) {
    console.log("WARN: This node is the only validator in the network");
}

// Check if we're in a ghost state (no blocks being produced)
var lastBlockTime = eth.getBlock(blockNumber).timestamp;
var currentTime = Math.floor(Date.now() / 1000);
var timeSinceLastBlock = currentTime - lastBlockTime;

console.log("Time since last block: " + timeSinceLastBlock + " seconds");
if (timeSinceLastBlock > 60) {
    console.log("ERROR: No blocks produced in the last minute. Chain may be stuck.");
}

// Check for potential ghost state issues
var signerCount = signers.length;
var expectedBlockTime = 5; // seconds
var expectedBlocksPerSigner = Math.floor(blocksInEpoch / signerCount);

if (blocksSigned < expectedBlocksPerSigner * 0.5) {
    console.log("WARN: Validator is signing fewer blocks than expected. This may indicate a ghost state issue.");
}

// Check for clique consensus issues
try {
    var cliqueSnapshot = clique.getSnapshot();
    if (cliqueSnapshot.inturn !== validatorAddress && blocksSigned > expectedBlocksPerSigner * 1.5) {
        console.log("WARN: Validator is signing more blocks than expected. This may indicate a consensus issue.");
    }
} catch (e) {
    console.log("WARN: Could not check clique snapshot: " + e.message);
}
JSEOF

# Execute the JavaScript code
RESULT=\$(geth attach "$DATADIR/geth.ipc" --exec "loadScript('\$JS_FILE')" 2>&1)
EXIT_CODE=\$?

# Clean up
rm -f "\$JS_FILE"

# Check for errors
if [ \$EXIT_CODE -ne 0 ]; then
    send_notification "Validator Error" "Failed to check validator health: \$RESULT"
    exit 1
fi

# Parse the result
if echo "\$RESULT" | grep -q "ERROR:"; then
    ERROR_MSG=\$(echo "\$RESULT" | grep "ERROR:" | head -1)
    send_notification "Validator Error" "\$ERROR_MSG"
    exit 1
fi

if echo "\$RESULT" | grep -q "WARN:"; then
    WARN_MSG=\$(echo "\$RESULT" | grep "WARN:" | head -1)
    send_notification "Validator Warning" "\$WARN_MSG"
fi

# All checks passed
exit 0
EOF
    
    chmod +x "$health_check_script"
    
    # Create cron job for health check
    log "INFO" "Setting up cron job for health check"
    
    # Remove existing cron job for health check
    crontab -l 2>/dev/null | grep -v "$health_check_script" | crontab -
    
    # Add new cron job (run every 5 minutes)
    (crontab -l 2>/dev/null ; echo "*/5 * * * * $health_check_script") | crontab -
    
    log "INFO" "Health check setup completed"
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_monitoring
fi
