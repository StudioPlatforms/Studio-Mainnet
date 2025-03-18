#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Network Configuration
# 
# This script handles the network configuration for the
# validator node, including genesis setup and peer discovery.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to download and initialize genesis
setup_genesis() {
    log "STEP" "Setting up genesis configuration"
    
    # Check if genesis file already exists
    if [ -f "$GENESIS_FILE" ]; then
        log "INFO" "Genesis file already exists at $GENESIS_FILE"
    else
        # Copy genesis file from repository
        local repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        repo_dir="$(dirname "$(dirname "$repo_dir")")"
        
        if [ -f "$repo_dir/node/genesis.json" ]; then
            log "INFO" "Copying genesis file from repository"
            cp "$repo_dir/node/genesis.json" "$GENESIS_FILE"
        else
            log "ERROR" "Genesis file not found in repository"
            exit 1
        fi
    fi
    
    # Validate genesis file
    if ! jq . "$GENESIS_FILE" > /dev/null 2>&1; then
        log "ERROR" "Invalid genesis file format"
        exit 1
    fi
    
    # Check if the genesis file contains the Clique consensus engine
    if ! jq -e '.config.clique' "$GENESIS_FILE" > /dev/null 2>&1; then
        log "ERROR" "Genesis file does not contain Clique consensus configuration"
        exit 1
    fi
    
    # Check the Clique period
    local clique_period=$(jq -r '.config.clique.period' "$GENESIS_FILE")
    if [ "$clique_period" -lt 5 ]; then
        log "WARN" "Clique period is less than 5 seconds. This may cause consensus issues."
    fi
    
    # Customize genesis file with validator address
    if [ -n "$VALIDATOR_ACCOUNT" ]; then
        log "INFO" "Customizing genesis file with validator address: $VALIDATOR_ACCOUNT"
        
        # Get validator address without 0x prefix
        local validator_address_no_prefix=${VALIDATOR_ACCOUNT#0x}
        
        # Create a temporary file
        local temp_file=$(mktemp)
        
        # Replace placeholder with validator address
        sed "s/YOUR_VALIDATOR_ADDRESS_HERE/$validator_address_no_prefix/g" "$GENESIS_FILE" > "$temp_file"
        
        # Check if the replacement was successful
        if grep -q "$validator_address_no_prefix" "$temp_file"; then
            mv "$temp_file" "$GENESIS_FILE"
            log "INFO" "Genesis file customized successfully"
        else
            rm "$temp_file"
            log "WARN" "Failed to customize genesis file. Please manually replace YOUR_VALIDATOR_ADDRESS_HERE with your validator address."
        fi
    else
        log "WARN" "Validator account not set. Please manually customize the genesis file."
    fi
    
    # Initialize the blockchain with the genesis file
    log "INFO" "Initializing blockchain with genesis file"
    if ! geth --datadir "$DATADIR" init "$GENESIS_FILE"; then
        log "ERROR" "Failed to initialize blockchain with genesis file"
        exit 1
    fi
    
    log "INFO" "Successfully initialized blockchain with genesis file"
}

# Function to setup network configuration
setup_network() {
    log "STEP" "Setting up network configuration"
    
    # Create geth directory if it doesn't exist
    mkdir -p "$DATADIR/geth"
    
    # Create static-nodes.json
    log "INFO" "Creating static-nodes.json"
    cat > "$DATADIR/geth/static-nodes.json" << EOF
[
  "enode://20b8ecf71c1929290c149d7de20408e8140984334e02a54830cf40ae8dcc1a168466949a04bc00847666d11879a9dc98594debdc9a8c20daa461bad47ad81023@62.171.162.49:30303"
]
EOF
    
    # Add bootnode to static-nodes.json if provided
    if [ -n "$BOOTNODE" ]; then
        log "INFO" "Adding bootnode to static-nodes.json"
        local temp_file=$(mktemp)
        jq --arg bootnode "$BOOTNODE" '. += [$bootnode]' "$DATADIR/geth/static-nodes.json" > "$temp_file"
        mv "$temp_file" "$DATADIR/geth/static-nodes.json"
    fi
    
    # Create trusted-nodes.json (same as static-nodes.json)
    log "INFO" "Creating trusted-nodes.json"
    cp "$DATADIR/geth/static-nodes.json" "$DATADIR/geth/trusted-nodes.json"
    
    # Create a permissioned-nodes.json file to restrict connections
    log "INFO" "Creating permissioned-nodes.json"
    cp "$DATADIR/geth/static-nodes.json" "$DATADIR/geth/permissioned-nodes.json"
    
    log "INFO" "Network configuration completed"
}

# Function to check network connectivity
check_network_connectivity() {
    log "STEP" "Checking network connectivity"
    
    # Check if the static-nodes.json file exists
    if [ ! -f "$DATADIR/geth/static-nodes.json" ]; then
        log "ERROR" "static-nodes.json file not found"
        exit 1
    fi
    
    # Get the list of static nodes
    local static_nodes=$(jq -r '.[]' "$DATADIR/geth/static-nodes.json")
    
    # Check connectivity to each node
    for node in $static_nodes; do
        local node_ip=$(echo "$node" | grep -oE '@[^:]+' | cut -c 2-)
        local node_port=$(echo "$node" | grep -oE ':[0-9]+$' | cut -c 2-)
        
        log "INFO" "Checking connectivity to $node_ip:$node_port"
        
        # Check if the node is reachable
        if command_exists nc && nc -z -w 5 "$node_ip" "$node_port" 2>/dev/null; then
            log "INFO" "Node $node_ip:$node_port is reachable"
        else
            log "WARN" "Node $node_ip:$node_port is not reachable"
        fi
    done
    
    log "INFO" "Network connectivity check completed"
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If no arguments are provided, run all functions
    if [ $# -eq 0 ]; then
        setup_genesis
        setup_network
        check_network_connectivity
    else
        # Otherwise, parse arguments
        case "$1" in
            genesis)
                setup_genesis
                ;;
            network)
                setup_network
                ;;
            check)
                check_network_connectivity
                ;;
            *)
                log "ERROR" "Unknown command: $1"
                echo "Usage: $0 [genesis|network|check]"
                exit 1
                ;;
        esac
    fi
fi
