#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - System Check
# 
# This script checks the system requirements for running a
# validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to check system requirements
check_system_requirements() {
    log "STEP" "Checking system requirements"
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        log "WARN" "Less than 2 CPU cores detected ($cpu_cores). Performance may be affected."
    else
        log "INFO" "CPU cores: $cpu_cores"
    fi
    
    # Check RAM
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 4096 ]; then
        log "WARN" "Less than 4GB RAM detected (${total_ram}MB). Performance may be affected."
    else
        log "INFO" "Total RAM: ${total_ram}MB"
    fi
    
    # Check disk space
    local free_space=$(df -h "$(dirname "$DATADIR")" | awk 'NR==2 {print $4}')
    log "INFO" "Free disk space: $free_space"
    
    # Check if geth is already installed
    if command_exists geth; then
        local installed_version=$(geth version | grep "Version:" | cut -d' ' -f2)
        log "INFO" "Geth is already installed (version $installed_version)"
    else
        log "INFO" "Geth is not installed, will install version $GETH_VERSION"
    fi
    
    # Check if port is already in use
    if command_exists netstat && netstat -tuln | grep -q ":$PORT "; then
        log "WARN" "Port $PORT is already in use. Please choose a different port."
    fi
    
    # Check if RPC port is already in use
    if command_exists netstat && netstat -tuln | grep -q ":$RPC_PORT "; then
        log "WARN" "RPC port $RPC_PORT is already in use. Please choose a different RPC port."
    fi
    
    # Check if WS port is already in use
    if command_exists netstat && netstat -tuln | grep -q ":$WS_PORT "; then
        log "WARN" "WS port $WS_PORT is already in use. Please choose a different WS port."
    fi
    
    # Check time synchronization
    if command_exists timedatectl; then
        if ! timedatectl status | grep -q "NTP synchronized: yes"; then
            log "WARN" "System time is not synchronized with NTP. This may cause consensus issues."
            log "INFO" "Consider installing and configuring NTP: sudo apt-get install ntp"
        else
            log "INFO" "System time is synchronized with NTP"
        fi
    else
        log "WARN" "Could not check time synchronization. Ensure your system time is accurate."
    fi
    
    # Check for potential ghost state issues
    log "INFO" "Checking for potential ghost state issues..."
    
    # Check if there are multiple validators with the same address
    if [ -d "$DATADIR/geth/clique" ]; then
        local snapshot_files=$(find "$DATADIR/geth/clique" -name "*.snap" | wc -l)
        if [ "$snapshot_files" -gt 1 ]; then
            log "WARN" "Multiple Clique snapshot files detected. This may indicate a potential ghost state issue."
        fi
    fi
    
    # Check if there are enough validators
    if [ -f "$DATADIR/geth/nodekey" ]; then
        log "INFO" "Node key exists, checking validator configuration..."
        
        # Try to get the number of signers from the clique snapshot
        if [ -d "$DATADIR/geth/clique" ]; then
            local signers_count=$(ls -1 "$DATADIR/geth/clique" | wc -l)
            if [ "$signers_count" -lt 3 ]; then
                log "WARN" "Less than 3 validators detected. For optimal Clique consensus, at least 3 validators are recommended."
            else
                log "INFO" "Detected $signers_count validators, which is good for Clique consensus."
            fi
        fi
    fi
    
    log "INFO" "System requirements check completed"
}

# Run the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_system_requirements
fi
