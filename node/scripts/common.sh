#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Common Functions
# 
# This script contains common functions and variables used
# by the validator setup scripts.
#############################################################

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# Default values
NETWORK_ID=240241
DATADIR="$HOME/studio-validator/node/data"
GENESIS_FILE="$HOME/studio-validator/node/genesis.json"
STATIC_NODES_FILE="$HOME/studio-validator/node/data/geth/static-nodes.json"
GETH_VERSION="1.13.14"
MONITORING=true
AUTO_BACKUP=true
BACKUP_INTERVAL="daily"
BACKUP_DIR="$HOME/studio-validator/backups"
VALIDATOR_NAME="validator-$(hostname)"
PORT=30303
RPC_PORT=8545
WS_PORT=8546
CLIQUE_PERIOD=5
BLOCK_GAS_LIMIT=30000000
VALIDATOR_ACCOUNT=""
IMPORT_KEY=""
PASSWORD=""
PASSWORD_FILE=""
BOOTNODE=""
MAIN_VALIDATOR="0x856157992B74A799D7A09F611f7c78AF4f26d309"
SCRIPTS_DIR="$HOME/studio-validator"

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

# Function to log messages
log() {
    local level=$1
    local message=$2
    local color=$RESET
    
    case $level in
        "INFO") color=$GREEN ;;
        "WARN") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        "STEP") color=$BLUE ;;
        "DEBUG") color=$CYAN ;;
    esac
    
    # Only print DEBUG messages if DEBUG is enabled
    if [ "$level" = "DEBUG" ] && [ -z "$DEBUG" ]; then
        return
    fi
    
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${color}${level}${RESET}: ${message}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
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
                shift 2
                ;;
            --network-id)
                NETWORK_ID="$2"
                shift 2
                ;;
            --port)
                PORT="$2"
                shift 2
                ;;
            --rpc-port)
                RPC_PORT="$2"
                shift 2
                ;;
            --ws-port)
                WS_PORT="$2"
                shift 2
                ;;
            --validator-name)
                VALIDATOR_NAME="$2"
                shift 2
                ;;
            --import-key)
                IMPORT_KEY="$2"
                shift 2
                ;;
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --password-file)
                PASSWORD_FILE="$2"
                shift 2
                ;;
            --bootnode)
                BOOTNODE="$2"
                shift 2
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
                shift 2
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
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

# Function to create directory structure
create_directory_structure() {
    log "STEP" "Creating directory structure"
    
    # Create data directory
    mkdir -p "$DATADIR"
    
    # Create scripts directory
    mkdir -p "$SCRIPTS_DIR/node/scripts"
    
    # Create backup directories
    mkdir -p "$BACKUP_DIR/daily"
    mkdir -p "$BACKUP_DIR/weekly"
    
    # Create monitoring directory
    if [ "$MONITORING" = true ]; then
        mkdir -p "$SCRIPTS_DIR/monitoring"
    fi
    
    log "INFO" "Directory structure created successfully"
}

# Function to copy repository files
copy_repository_files() {
    log "STEP" "Copying repository files"
    
    # Get the directory of the setup script
    local setup_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local repo_dir="$(dirname "$(dirname "$setup_dir")")"
    
    # Copy genesis file
    cp "$repo_dir/node/genesis.json" "$SCRIPTS_DIR/node/"
    
    # Copy scripts
    cp "$repo_dir/node/scripts/"*.sh "$SCRIPTS_DIR/node/scripts/"
    chmod +x "$SCRIPTS_DIR/node/scripts/"*.sh
    
    # Copy systemd service files
    mkdir -p "$SCRIPTS_DIR/systemd"
    cp "$repo_dir/systemd/"* "$SCRIPTS_DIR/systemd/" 2>/dev/null || true
    
    log "INFO" "Repository files copied successfully"
}

# Export variables
export NETWORK_ID
export DATADIR
export GENESIS_FILE
export STATIC_NODES_FILE
export GETH_VERSION
export MONITORING
export AUTO_BACKUP
export BACKUP_INTERVAL
export BACKUP_DIR
export VALIDATOR_NAME
export PORT
export RPC_PORT
export WS_PORT
export CLIQUE_PERIOD
export BLOCK_GAS_LIMIT
export VALIDATOR_ACCOUNT
export IMPORT_KEY
export PASSWORD
export PASSWORD_FILE
export BOOTNODE
export MAIN_VALIDATOR
export SCRIPTS_DIR
export DEBUG
