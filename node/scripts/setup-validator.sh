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

# Function to modify the start script to include the --config flag
modify_start_script() {
    log "INFO" "Modifying start script to include --config flag..."
    
    # Check if the start script exists
    if [ ! -f "$SCRIPT_DIR/start.sh.template" ]; then
        log "ERROR" "Start script template not found: $SCRIPT_DIR/start.sh.template"
        return 1
    fi
    
    # Create a temporary file
    TMP_FILE=$(mktemp)
    
    # Read the template and add the --config flag
    cat "$SCRIPT_DIR/start.sh.template" | sed 's/geth --datadir/geth --config $DATADIR\/geth\/config.toml --datadir/' > "$TMP_FILE"
    
    # Move the temporary file to the destination
    mv "$TMP_FILE" "$SCRIPT_DIR/start.sh.template"
    
    log "INFO" "Start script modified successfully."
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
    
    # Create directory structure
    create_directory_structure
    
    # Copy repository files
    copy_repository_files
    
    # Check system requirements
    log "INFO" "Checking system requirements..."
    "$SCRIPT_DIR/system-check.sh"
    
    # Install dependencies and Geth
    log "INFO" "Installing dependencies and Geth..."
    "$SCRIPT_DIR/install.sh"
    
    # Setup validator account
    log "INFO" "Setting up validator account..."
    source "$SCRIPT_DIR/account.sh"
    setup_validator_account
    
    # Get validator account if not set by account.sh
    if [ -z "$VALIDATOR_ACCOUNT" ]; then
        if [ -f "$DATADIR/validator-address.txt" ]; then
            VALIDATOR_ACCOUNT=$(cat "$DATADIR/validator-address.txt")
            export VALIDATOR_ACCOUNT
            log "INFO" "Using validator account: $VALIDATOR_ACCOUNT"
        else
            log "WARN" "Validator account not found. Network setup may fail."
        fi
    fi
    
    # Create config.toml with static nodes
    create_config_toml
    
    # Modify the start script to include the --config flag
    modify_start_script
    
    # Setup network configuration
    log "INFO" "Setting up network configuration..."
    export VALIDATOR_ACCOUNT
    "$SCRIPT_DIR/network.sh"
    
    # Verify genesis block hash
    verify_genesis_block_hash
    
    # Setup monitoring
    if [ "$MONITORING" = true ]; then
        log "INFO" "Setting up monitoring..."
        "$SCRIPT_DIR/monitoring.sh"
    fi
    
    # Setup automatic backups
    if [ "$AUTO_BACKUP" = true ]; then
        log "INFO" "Setting up automatic backups..."
        "$SCRIPT_DIR/backup.sh"
    fi
    
    # Setup firewall
    log "INFO" "Setting up firewall..."
    "$SCRIPT_DIR/firewall.sh"

    # Setup services
    log "INFO" "Setting up services..."
    "$SCRIPT_DIR/service.sh"
    
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
    log "INFO" "Check service status: systemctl --user status studio-validator"
    log "INFO" "View logs: journalctl --user -u studio-validator -f"
    log "INFO" "Stop service: systemctl --user stop studio-validator"
    log "INFO" "Start service: systemctl --user start studio-validator"
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
        "$SCRIPT_DIR/service.sh" start
    else
        log "INFO" "Validator node not started. You can start it later with: systemctl --user start studio-validator"
    fi
}

# Run the setup
run_setup "$@"
