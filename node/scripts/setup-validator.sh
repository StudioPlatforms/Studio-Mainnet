#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Main Script
# 
# This script sets up a validator node for the Studio Blockchain
# network.
#############################################################

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions and variables
source "$SCRIPT_DIR/common.sh"

# Function to print banner
print_banner() {
    echo -e "${BLUE}"
    echo "  ____  _             _ _         ____  _            _        _           _       "
    echo " / ___|| |_ _   _  __| (_) ___   | __ ) | | ___   ___| | _____| |__   __ _(_)_ __  "
    echo " \\___ \\| __| | | |/ _\` | |/ _ \\  |  _ \\ | |/ _ \\ / __| |/ / __| '_ \\ / _\` | | '_ \\ "
    echo "  ___) | |_| |_| | (_| | | (_) | | |_) || | (_) | (__|   < (__| | | | (_| | | | | |"
    echo " |____/ \\__|\\__,_|\\__,_|_|\\___/  |____/ |_|\\___/ \\___|_|\\_\\___|_| |_|\\__,_|_|_| |_|"
    echo "                                                                                   "
    echo " Validator Node Setup                                                              "
    echo -e "${RESET}"
}

# Function to print usage information
print_usage() {
    echo -e "${BOLD}Usage:${RESET} ./setup-validator.sh [options]"
    echo
    echo "Options:"
    echo "  --help                      Show this help message"
    echo "  --datadir DIR               Data directory for the node (default: $DATADIR)"
    echo "  --network-id ID             Network ID (default: $NETWORK_ID)"
    echo "  --port PORT                 P2P port (default: $PORT)"
    echo "  --rpc-port PORT             HTTP-RPC port (default: $RPC_PORT)"
    echo "  --ws-port PORT              WS-RPC port (default: $WS_PORT)"
    echo "  --validator-name NAME       Name for this validator (default: validator-hostname)"
    echo "  --import-key KEY            Import private key instead of creating new account"
    echo "  --password PASS             Password for the validator account"
    echo "  --password-file FILE        File containing password for the validator account"
    echo "  --bootnode ENODE            Bootnode enode URL"
    echo "  --no-monitoring             Disable monitoring setup"
    echo "  --no-auto-backup            Disable automatic backups"
    echo "  --backup-interval INTERVAL  Backup interval (daily/weekly) (default: $BACKUP_INTERVAL)"
    echo "  --backup-dir DIR            Backup directory (default: $BACKUP_DIR)"
    echo
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        log "WARN" "Running as root is not recommended. Consider running as a regular user."
        
        # Ask for confirmation
        read -p "Continue as root? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Exiting. Please run as a regular user."
            exit 1
        fi
    fi
}

# Function to check if the script is being run from the repository
check_repository() {
    # Check if the script is being run from the repository
    if [ ! -f "$SCRIPT_DIR/../genesis.json" ]; then
        log "WARN" "This script should be run from the repository."
        log "INFO" "Please clone the repository and run the script from there:"
        log "INFO" "git clone https://github.com/StudioPlatforms/Studio-Mainnet.git"
        log "INFO" "cd Studio-Mainnet"
        log "INFO" "chmod +x node/scripts/*.sh"
        log "INFO" "node/scripts/setup-validator.sh"
        
        # Ask for confirmation
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Exiting. Please run from the repository."
            exit 1
        fi
    fi
}

# Function to create config.toml with static nodes
create_config_toml() {
    log "INFO" "Creating config.toml with static nodes..."
    
    mkdir -p "$DATADIR/geth"
    
    cat > "$DATADIR/geth/config.toml" << EOF
[Node.P2P]
StaticNodes = [
  "enode://673c250c3a7c91f5900cbe1bc605de2a2b94ebf0e853ceba70dc556249b76e4d4ce4b25eb13e13e32689365d50e08ff8fcf704b0827150e84164a04d58118864@173.249.16.253:30303",
  "enode://be9ff49b5a918370d80237faeca6ff260cb54431b0d71ac766e7b965b47ecca1bb0db44fb9501132a7f0449a43777e55baeeae2d00e4168484003c9bdc8d38bf@173.212.200.31:30303",
  "enode://c4f0744053f530f887f1b1ca03c79415a2fac2bbd8576d4e978f7e0e902b0c2fe1bdd5541afc087abaae9f23aa43d66a2749025fa41d7bb47be2168942bae409@161.97.92.8:30303",
  "enode://3295d5cc7495b59f511de451e71a614f84084119b0ad25c2758edca1c708eb4e32506a39ec86d42c8335828f47ca8bb48d6bbb6d131036e2af6828320e44431f@167.86.95.117:30303"
]
EOF
    
    log "INFO" "Config.toml created successfully."
}

# Function to create start.sh script
create_start_script() {
    log "INFO" "Creating start.sh script..."
    
    mkdir -p "$DATADIR/scripts"
    
    cat > "$DATADIR/scripts/start.sh" << 'EOF'
#!/bin/bash
echo "Starting Studio Blockchain Validator Node..."

VALIDATOR_ADDRESS=$(cat ~/studio-validator/address.txt)
echo "Validator address: $VALIDATOR_ADDRESS"

# Create a backup of the data directory before starting
BACKUP_DIR=~/studio-validator/backups
mkdir -p $BACKUP_DIR/daily
mkdir -p $BACKUP_DIR/weekly
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo "Creating backup of blockchain data..."
tar -czf $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-validator/data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
echo "Backup created at $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz"

# Keep only the last 5 backups to save space
ls -t $BACKUP_DIR/daily/blockchain-data-*.tar.gz | tail -n +6 | xargs -r rm

# Start the blockchain node
geth --config ~/studio-validator/data/geth/config.toml \
--datadir ~/studio-validator/data \
--networkid 240241 \
--port 30303 \
--http \
--http.addr "127.0.0.1" \
--http.port 8545 \
--http.corsdomain "*" \
--http.vhosts "*" \
--http.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--ws \
--ws.addr "127.0.0.1" \
--ws.port 8546 \
--ws.origins "*" \
--ws.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--mine \
--miner.gasprice "0" \
--miner.gaslimit "30000000" \
--allow-insecure-unlock \
--unlock $VALIDATOR_ADDRESS \
--password ~/studio-validator/password.txt \
--syncmode full \
--miner.etherbase $VALIDATOR_ADDRESS \
--rpc.allow-unprotected-txs \
--txpool.pricelimit "0" \
--txpool.accountslots "16" \
--txpool.globalslots "16384" \
--txpool.accountqueue "64" \
--txpool.globalqueue "1024" \
--verbosity 4
EOF
    
    chmod +x "$DATADIR/scripts/start.sh"
    
    log "INFO" "Start script created successfully."
}

# Function to install Geth
install_geth() {
    log "INFO" "Installing Geth..."
    
    # Check if Geth is already installed
    if command -v geth &> /dev/null; then
        log "INFO" "Geth is already installed."
        return 0
    fi
    
    # Install Geth
    log "INFO" "Downloading Geth v1.13.14..."
    
    # Create a temporary directory
    TMP_DIR=$(mktemp -d)
    
    # Download Geth
    wget -q -O "$TMP_DIR/geth.tar.gz" "https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz"
    
    # Check if download was successful
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to download Geth. Trying alternative URL..."
        wget -q -O "$TMP_DIR/geth.tar.gz" "https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz"
        
        if [ $? -ne 0 ]; then
            log "ERROR" "Failed to download Geth. Please check your internet connection and try again."
            rm -rf "$TMP_DIR"
            return 1
        fi
    fi
    
    # Extract Geth
    tar -xzf "$TMP_DIR/geth.tar.gz" -C "$TMP_DIR"
    
    # Install Geth
    cp "$TMP_DIR/geth-linux-amd64-1.13.14-2bd6bd01/geth" /usr/local/bin/
    
    # Clean up
    rm -rf "$TMP_DIR"
    
    # Verify installation
    if command -v geth &> /dev/null; then
        log "INFO" "Geth installed successfully."
        return 0
    else
        log "ERROR" "Failed to install Geth."
        return 1
    fi
}

# Function to verify genesis block hash
verify_genesis_block_hash() {
    log "INFO" "Verifying genesis block hash..."
    
    # Initialize the blockchain with the genesis file
    geth --datadir "$DATADIR" init "$DATADIR/genesis.json"
    
    # Get the genesis block hash
    GENESIS_HASH=$(geth --datadir "$DATADIR" console --exec "eth.getBlock(0).hash" 2>/dev/null)
    
    # Check if the genesis block hash is correct
    if [ "$GENESIS_HASH" != "0x625c44301fbdd241bd9fb67023904dc4c023c4a6b2747756de5d8869a60f29a8" ]; then
        log "ERROR" "Genesis block hash mismatch!"
        log "ERROR" "Expected: 0x625c44301fbdd241bd9fb67023904dc4c023c4a6b2747756de5d8869a60f29a8"
        log "ERROR" "Got: $GENESIS_HASH"
        log "ERROR" "This indicates that the genesis.json file is not the same as the one used by the network."
        log "ERROR" "Please contact the Studio Blockchain team to obtain the correct genesis.json file."
        
        # Ask for confirmation
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Exiting. Please obtain the correct genesis.json file."
            exit 1
        fi
    else
        log "INFO" "Genesis block hash verified successfully."
    fi
}

# Function to setup validator account
setup_validator_account() {
    log "INFO" "Setting up validator account..."
    
    # Create password file directory
    mkdir -p "$DATADIR"
    
    # Check if private key is provided
    if [ -n "$IMPORT_KEY" ]; then
        log "INFO" "Importing private key..."
        
        # Create password file
        if [ -n "$PASSWORD" ]; then
            echo "$PASSWORD" > "$DATADIR/password.txt"
        else
            log "INFO" "Please enter a strong password for your validator account:"
            read -s PASSWORD
            echo "$PASSWORD" > "$DATADIR/password.txt"
        fi
        
        # Make password file readable only by owner
        chmod 600 "$DATADIR/password.txt"
        
        # Create temporary file for private key
        PRIVATE_KEY_FILE=$(mktemp)
        echo "$IMPORT_KEY" > "$PRIVATE_KEY_FILE"
        
        # Import private key
        mkdir -p "$DATADIR/keystore"
        ACCOUNT_ADDRESS=$(geth account import --datadir "$DATADIR" --password "$DATADIR/password.txt" "$PRIVATE_KEY_FILE" 2>&1 | grep -o '0x[0-9a-fA-F]\{40\}')
        
        # Remove temporary file
        rm "$PRIVATE_KEY_FILE"
        
        # Check if address was extracted
        if [ -z "$ACCOUNT_ADDRESS" ]; then
            log "INFO" "Could not extract address from import output, trying to get it from keystore"
            ACCOUNT_ADDRESS=$(geth --datadir "$DATADIR" account list 2>/dev/null | grep -o '0x[0-9a-fA-F]\{40\}')
        fi
        
        # Check if address was extracted
        if [ -z "$ACCOUNT_ADDRESS" ]; then
            log "INFO" "Could not extract address from accounts list, trying to get it from keystore files"
            KEYSTORE_FILE=$(ls -1 "$DATADIR/keystore" 2>/dev/null | head -n 1)
            if [ -n "$KEYSTORE_FILE" ]; then
                ACCOUNT_ADDRESS=$(echo "$KEYSTORE_FILE" | grep -o '[0-9a-fA-F]\{40\}')
                if [ -n "$ACCOUNT_ADDRESS" ]; then
                    ACCOUNT_ADDRESS="0x$ACCOUNT_ADDRESS"
                fi
            fi
        fi
        
        # Check if address was extracted
        if [ -z "$ACCOUNT_ADDRESS" ]; then
            log "WARN" "Could not determine the imported account address"
            log "INFO" "Please enter the address of the imported account (with 0x prefix):"
            read ACCOUNT_ADDRESS
        fi
        
        # Save address to file
        echo "$ACCOUNT_ADDRESS" > "$DATADIR/address.txt"
        
        # Export validator account
        export VALIDATOR_ACCOUNT="$ACCOUNT_ADDRESS"
        
        log "INFO" "Saved password to $DATADIR/password.txt"
        log "INFO" "Saved validator address to $DATADIR/address.txt"
        
        # Check if account exists in keystore
        if [ ! -d "$DATADIR/keystore" ] || [ -z "$(ls -A "$DATADIR/keystore" 2>/dev/null)" ]; then
            log "WARN" "Validator account not found in keystore. This may indicate an issue with account creation."
        fi
    else
        log "INFO" "Please choose how you want to set up your validator account:"
        echo "1. Create a new account"
        echo "2. Import an existing private key"
        read -p "Enter your choice (1-2): " ACCOUNT_CHOICE
        
        case $ACCOUNT_CHOICE in
            1)
                log "INFO" "Creating a new account..."
                
                # Create password file
                log "INFO" "Please enter a strong password for your validator account:"
                read -s PASSWORD
                echo "$PASSWORD" > "$DATADIR/password.txt"
                
                # Make password file readable only by owner
                chmod 600 "$DATADIR/password.txt"
                
                # Create account
                mkdir -p "$DATADIR/keystore"
                ACCOUNT_ADDRESS=$(geth account new --datadir "$DATADIR" --password "$DATADIR/password.txt" 2>&1 | grep -o '0x[0-9a-fA-F]\{40\}')
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "INFO" "Could not extract address from creation output, trying to get it from keystore"
                    ACCOUNT_ADDRESS=$(geth --datadir "$DATADIR" account list 2>/dev/null | grep -o '0x[0-9a-fA-F]\{40\}')
                fi
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "INFO" "Could not extract address from accounts list, trying to get it from keystore files"
                    KEYSTORE_FILE=$(ls -1 "$DATADIR/keystore" 2>/dev/null | head -n 1)
                    if [ -n "$KEYSTORE_FILE" ]; then
                        ACCOUNT_ADDRESS=$(echo "$KEYSTORE_FILE" | grep -o '[0-9a-fA-F]\{40\}')
                        if [ -n "$ACCOUNT_ADDRESS" ]; then
                            ACCOUNT_ADDRESS="0x$ACCOUNT_ADDRESS"
                        fi
                    fi
                fi
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "WARN" "Could not determine the created account address"
                    log "INFO" "Please enter the address of the created account (with 0x prefix):"
                    read ACCOUNT_ADDRESS
                fi
                
                # Save address to file
                echo "$ACCOUNT_ADDRESS" > "$DATADIR/address.txt"
                
                # Export validator account
                export VALIDATOR_ACCOUNT="$ACCOUNT_ADDRESS"
                
                log "INFO" "Saved password to $DATADIR/password.txt"
                log "INFO" "Saved validator address to $DATADIR/address.txt"
                ;;
            2)
                log "INFO" "Please enter your private key (without 0x prefix):"
                read IMPORT_KEY
                
                # Create password file
                log "INFO" "Please enter a strong password for your validator account:"
                read -s PASSWORD
                echo "$PASSWORD" > "$DATADIR/password.txt"
                
                # Make password file readable only by owner
                chmod 600 "$DATADIR/password.txt"
                
                # Create temporary file for private key
                PRIVATE_KEY_FILE=$(mktemp)
                echo "$IMPORT_KEY" > "$PRIVATE_KEY_FILE"
                
                # Import private key
                mkdir -p "$DATADIR/keystore"
                ACCOUNT_ADDRESS=$(geth account import --datadir "$DATADIR" --password "$DATADIR/password.txt" "$PRIVATE_KEY_FILE" 2>&1 | grep -o '0x[0-9a-fA-F]\{40\}')
                
                # Remove temporary file
                rm "$PRIVATE_KEY_FILE"
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "INFO" "Could not extract address from import output, trying to get it from keystore"
                    ACCOUNT_ADDRESS=$(geth --datadir "$DATADIR" account list 2>/dev/null | grep -o '0x[0-9a-fA-F]\{40\}')
                fi
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "INFO" "Could not extract address from accounts list, trying to get it from keystore files"
                    KEYSTORE_FILE=$(ls -1 "$DATADIR/keystore" 2>/dev/null | head -n 1)
                    if [ -n "$KEYSTORE_FILE" ]; then
                        ACCOUNT_ADDRESS=$(echo "$KEYSTORE_FILE" | grep -o '[0-9a-fA-F]\{40\}')
                        if [ -n "$ACCOUNT_ADDRESS" ]; then
                            ACCOUNT_ADDRESS="0x$ACCOUNT_ADDRESS"
                        fi
                    fi
                fi
                
                # Check if address was extracted
                if [ -z "$ACCOUNT_ADDRESS" ]; then
                    log "WARN" "Could not determine the imported account address"
                    log "INFO" "Please enter the address of the imported account (with 0x prefix):"
                    read ACCOUNT_ADDRESS
                fi
                
                # Save address to file
                echo "$ACCOUNT_ADDRESS" > "$DATADIR/address.txt"
                
                # Export validator account
                export VALIDATOR_ACCOUNT="$ACCOUNT_ADDRESS"
                
                log "INFO" "Saved password to $DATADIR/password.txt"
                log "INFO" "Saved validator address to $DATADIR/address.txt"
                ;;
            *)
                log "ERROR" "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
    
    log "INFO" "Validator account setup completed"
}

# Function to create systemd service file
create_systemd_service() {
    log "INFO" "Creating systemd service file..."
    
    # Create systemd service file
    cat > /etc/systemd/system/geth-studio-validator.service << EOF
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=$DATADIR/scripts/start.sh
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
    
    # Reload systemd
    systemctl daemon-reload
    
    log "INFO" "Systemd service file created successfully."
}

# Function to run the setup steps
run_setup() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Print banner
    print_banner
    
    # Check if running as root
    check_root
    
    # Check if running from repository
    check_repository
    
    # Confirm setup
    log "INFO" "This script will set up a validator node for the Studio Blockchain network."
    log "INFO" "It will install required packages, configure the firewall, and set up the validator node."
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Setup cancelled."
        exit 0
    fi
    
    # Set default data directory if not provided
    if [ -z "$DATADIR" ]; then
        DATADIR="$HOME/studio-validator"
    fi
    
    # Create directory structure
    log "STEP" "Creating directory structure"
    mkdir -p "$DATADIR/data/geth"
    mkdir -p "$DATADIR/scripts"
    mkdir -p "$DATADIR/backups/daily"
    mkdir -p "$DATADIR/backups/weekly"
    log "INFO" "Directory structure created successfully"
    
    # Copy genesis.json
    log "STEP" "Copying genesis.json"
    cp "$SCRIPT_DIR/../genesis.json" "$DATADIR/genesis.json"
    log "INFO" "Genesis file copied successfully"
    
    # Install Geth
    install_geth
    
    # Setup validator account
    setup_validator_account
    
    # Create config.toml with static nodes
    create_config_toml
    
    # Create start.sh script
    create_start_script
    
    # Verify genesis block hash
    verify_genesis_block_hash
    
    # Create systemd service file
    create_systemd_service
    
    # Print final information
    log "STEP" "Setup Complete"
    
    log "INFO" "Your Studio Blockchain validator node has been set up successfully!"
    log "INFO" ""
    log "INFO" "Important Information:"
    log "INFO" "Validator Address: $VALIDATOR_ACCOUNT"
    log "INFO" ""
    log "INFO" "Next Steps:"
    log "INFO" "1. Contact the Studio Blockchain team at office@studio-blockchain.com with your validator address"
    log "INFO" "2. They will add your node as a validator to the network"
    log "INFO" ""
    log "INFO" "Useful Commands:"
    log "INFO" "Check service status: systemctl status geth-studio-validator"
    log "INFO" "View logs: journalctl -u geth-studio-validator -f"
    log "INFO" "Stop service: systemctl stop geth-studio-validator"
    log "INFO" "Start service: systemctl start geth-studio-validator"
    log "INFO" ""
    log "INFO" "Troubleshooting:"
    log "INFO" "1. If you see 'genesis mismatch' errors in the logs, it means your genesis block hash doesn't match the one used by the network."
    log "INFO" "   Solution: Contact the Studio Blockchain team to obtain the correct genesis.json file."
    log "INFO" "2. If you see 'Failed to unlock account' errors, it means the password provided doesn't match the one used to create the account."
    log "INFO" "   Solution: Re-import the account with the correct password."
    log "INFO" "3. If your node isn't connecting to any peers, check your network configuration and firewall settings."
    log "INFO" "   Solution: Ensure port 30303 is open for both TCP and UDP."
    log "INFO" ""
    log "INFO" "Thank you for joining the Studio Blockchain network as a validator!"
    
    # Ask if user wants to start the validator node
    read -p "Do you want to start the validator node now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Starting validator node..."
        systemctl enable geth-studio-validator
        systemctl start geth-studio-validator
        log "INFO" "Validator node started. Check status with: systemctl status geth-studio-validator"
    else
        log "INFO" "Validator node not started. You can start it later with: systemctl start geth-studio-validator"
    fi
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                print_usage
                exit 0
                ;;
            --datadir)
                DATADIR="$2"
                shift
                shift
                ;;
            --network-id)
                NETWORK_ID="$2"
                shift
                shift
                ;;
            --port)
                PORT="$2"
                shift
                shift
                ;;
            --rpc-port)
                RPC_PORT="$2"
                shift
                shift
                ;;
            --ws-port)
                WS_PORT="$2"
                shift
                shift
                ;;
            --validator-name)
                VALIDATOR_NAME="$2"
                shift
                shift
                ;;
            --import-key)
                IMPORT_KEY="$2"
                shift
                shift
                ;;
            --password)
                PASSWORD="$2"
                shift
                shift
                ;;
            --password-file)
                PASSWORD_FILE="$2"
                shift
                shift
                ;;
            --bootnode)
                BOOTNODE="$2"
                shift
                shift
                ;;
            --no-monitoring)
                MONITORING=false
                shift
                ;;
            --no-auto-backup)
                AUTO_BACKUP=false
                shift
                ;;
            --backup-interval)
                BACKUP_INTERVAL="$2"
                shift
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# Set default values
DATADIR="$HOME/studio-validator"
NETWORK_ID="240241"
PORT="30303"
RPC_PORT="8545"
WS_PORT="8546"
VALIDATOR_NAME="validator-$(hostname)"
MONITORING=true
AUTO_BACKUP=true
BACKUP_INTERVAL="daily"
BACKUP_DIR="$HOME/studio-validator/backups"

# Run the setup
run_setup "$@"
