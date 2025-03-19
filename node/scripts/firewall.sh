#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Firewall Configuration
#
# This script configures the firewall for the validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to configure the firewall
configure_firewall() {
    log "STEP" "Configuring firewall"

    # Check if ufw is installed
    if ! command_exists ufw; then
        log "INFO" "Installing ufw"
        if command_exists apt-get; then
            sudo apt-get install -y ufw
        elif command_exists yum; then
            sudo yum install -y ufw
        elif command_exists dnf; then
            sudo dnf install -y ufw
        else
            log "WARN" "Could not install ufw. Please install it manually."
            return 1
        fi
    fi

    # Configure ufw
    log "INFO" "Configuring ufw"
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow P2P port
    log "INFO" "Allowing P2P port: $PORT"
    sudo ufw allow $PORT/tcp
    sudo ufw allow $PORT/udp
    
    # Allow RPC port if external access is needed
    if [ "$RPC_ADDR" != "127.0.0.1" ]; then
        log "INFO" "Allowing RPC port: $RPC_PORT"
        sudo ufw allow $RPC_PORT/tcp
    else
        log "INFO" "RPC port is bound to localhost, not opening in firewall"
    fi
    
    # Allow WS port if external access is needed
    if [ "$WS_ADDR" != "127.0.0.1" ]; then
        log "INFO" "Allowing WS port: $WS_PORT"
        sudo ufw allow $WS_PORT/tcp
    else
        log "INFO" "WS port is bound to localhost, not opening in firewall"
    fi
    
    # Enable ufw
    log "INFO" "Enabling ufw"
    sudo ufw --force enable
    
    # Check ufw status
    log "INFO" "Firewall status:"
    sudo ufw status
    
    log "INFO" "Firewall configuration completed"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_firewall
fi
