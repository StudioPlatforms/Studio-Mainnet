#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Installation
# 
# This script installs the dependencies and Geth for running
# a validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to install dependencies
install_dependencies() {
    log "STEP" "Installing dependencies"
    
    # Check if we're on a Debian/Ubuntu system
    if command_exists apt-get; then
        log "INFO" "Detected Debian/Ubuntu system"
        
        # Update package lists
        log "INFO" "Updating package lists"
        sudo apt-get update
        
        # Install required packages
        log "INFO" "Installing required packages"
        sudo apt-get install -y build-essential curl wget git jq net-tools
        
        # Install monitoring tools if enabled
        if [ "$MONITORING" = true ]; then
            log "INFO" "Installing monitoring tools"
            sudo apt-get install -y prometheus prometheus-node-exporter
        fi
        
        # Install NTP for time synchronization
        log "INFO" "Installing NTP for time synchronization"
        sudo apt-get install -y ntp
        sudo systemctl enable ntp
        sudo systemctl start ntp
    # Check if we're on a RHEL/CentOS/Fedora system
    elif command_exists yum || command_exists dnf; then
        log "INFO" "Detected RHEL/CentOS/Fedora system"
        
        # Determine package manager
        local pkg_manager="yum"
        if command_exists dnf; then
            pkg_manager="dnf"
        fi
        
        # Install required packages
        log "INFO" "Installing required packages"
        sudo $pkg_manager install -y make gcc gcc-c++ curl wget git jq net-tools
        
        # Install monitoring tools if enabled
        if [ "$MONITORING" = true ]; then
            log "INFO" "Installing monitoring tools"
            sudo $pkg_manager install -y prometheus prometheus-node-exporter
        fi
        
        # Install NTP for time synchronization
        log "INFO" "Installing NTP for time synchronization"
        sudo $pkg_manager install -y ntp
        sudo systemctl enable ntpd
        sudo systemctl start ntpd
    else
        log "WARN" "Unsupported package manager. Please install dependencies manually."
    fi
    
    log "INFO" "Dependencies installation completed"
}

# Function to install Geth
install_geth() {
    log "STEP" "Installing Geth"
    
    # Set default Geth version if not set
    if [ -z "$GETH_VERSION" ]; then
        GETH_VERSION="1.13.14"
        log "WARN" "GETH_VERSION not set, using default: $GETH_VERSION"
    fi
    
    # Check if geth is already installed
    if command_exists geth; then
        local installed_version=$(geth version | grep "Version:" | cut -d' ' -f2)
        log "INFO" "Geth is already installed (version $installed_version)"
        
        # If the installed version is close enough to the target version, use it
        if [[ "$installed_version" == *"$GETH_VERSION"* ]]; then
            log "INFO" "Using existing Geth installation"
            return 0
        else
            log "INFO" "Existing Geth version is different from target version"
            
            # Ask user if they want to continue with existing version
            read -p "Continue with existing Geth version? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "INFO" "Using existing Geth installation"
                return 0
            fi
        fi
    fi
    
    # Determine OS and architecture
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)
    
    # Map architecture to Geth's naming convention
    case $arch in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="arm7" ;;
        *) log "ERROR" "Unsupported architecture: $arch"; exit 1 ;;
    esac
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download and extract Geth
    log "INFO" "Downloading Geth v$GETH_VERSION for $os-$arch"
    local download_url="https://gethstore.blob.core.windows.net/builds/geth-$os-$arch-$GETH_VERSION-stable.tar.gz"
    
    if ! wget -q "$download_url"; then
        log "ERROR" "Failed to download Geth. Please check the version and try again."
        
        # If Geth is already installed, continue with existing version
        if command_exists geth; then
            log "INFO" "Continuing with existing Geth installation"
            return 0
        else
            exit 1
        fi
    fi
    
    tar -xzf "geth-$os-$arch-$GETH_VERSION-stable.tar.gz"
    cd "geth-$os-$arch-$GETH_VERSION-stable"
    
    # Install Geth
    log "INFO" "Installing Geth"
    sudo cp geth /usr/local/bin/
    
    # Verify installation
    if ! command_exists geth; then
        log "ERROR" "Failed to install Geth"
        exit 1
    fi
    
    local installed_version=$(geth version | grep "Version:" | cut -d' ' -f2)
    log "INFO" "Successfully installed Geth version $installed_version"
    
    # Clean up
    cd
    rm -rf "$temp_dir"
    
    log "INFO" "Geth installation completed"
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_dependencies
    install_geth
fi
