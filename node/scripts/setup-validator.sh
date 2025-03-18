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
    "$SCRIPT_DIR/account.sh"
    
    # Get validator account
    VALIDATOR_ACCOUNT=$(cat "$DATADIR/validator-address.txt" 2>/dev/null || echo "")
    
    # Setup network configuration
    log "INFO" "Setting up network configuration..."
    "$SCRIPT_DIR/network.sh"
    
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
