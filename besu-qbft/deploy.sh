#!/bin/bash

# This script sets up a Besu validator node for the Studio Blockchain
# Usage: ./deploy.sh <validator_number> <ip_address>

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored header
print_header() {
    echo -e "${RED}"
    echo "  ____  _             _ _         ____  _            _        _           _       "
    echo " / ___|| |_ _   _  __| (_) ___   | __ )| | ___   ___| | _____| |__   __ _(_)_ __  "
    echo " \___ \| __| | | |/ _\` | |/ _ \  |  _ \| |/ _ \ / __| |/ / __| '_ \ / _\` | | '_ \ "
    echo "  ___) | |_| |_| | (_| | | (_) | | |_) | | (_) | (__|   < (__| | | | (_| | | | | |"
    echo " |____/ \__|\__,_|\__,_|_|\___/  |____/|_|\___/ \___|_|\_\___|_| |_|\__,_|_|_| |_|"
    echo -e "${NC}"
    echo -e "${CYAN}QBFT Validator Deployment Script${NC}"
    echo -e "${CYAN}===============================${NC}"
    echo ""
}

# Function to print section header
print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info message
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check arguments
if [ "$#" -lt 2 ]; then
    print_header
    print_error "Usage: $0 <validator_number> <ip_address>"
    print_info "Example: $0 8 203.0.113.10"
    exit 1
fi

VALIDATOR_NUM=$1
IP_ADDRESS=$2

print_header
print_info "Setting up validator $VALIDATOR_NUM with IP $IP_ADDRESS"

# Stop and disable the old Geth validator service
print_section "Stopping Old Services"
systemctl stop geth-studio-validator 2>/dev/null || true
print_success "Stopped old Geth validator service"
systemctl disable geth-studio-validator 2>/dev/null || true
print_success "Disabled old Geth validator service"
sed -i 's/Restart=always/Restart=no/' /etc/systemd/system/geth-studio-validator.service 2>/dev/null || true
systemctl daemon-reload
print_success "Updated systemd configuration"

# Install prerequisites
print_section "Installing Prerequisites"
apt-get update
apt-get install -y openjdk-21-jdk jq curl wget tar
print_success "Installed all required packages"

# Download and install Besu
print_section "Installing Hyperledger Besu"
BESU_VER=$(curl -s https://api.github.com/repos/hyperledger/besu/releases/latest | jq -r .tag_name)
print_info "Downloading Besu version $BESU_VER..."
curl -L -o besu-${BESU_VER}.tar.gz https://github.com/hyperledger/besu/releases/download/${BESU_VER}/besu-${BESU_VER}.tar.gz
tar -xzf besu-${BESU_VER}.tar.gz
rm -rf /opt/besu
mv besu-${BESU_VER} /opt/besu
ln -sf /opt/besu/bin/besu /usr/local/bin/besu
print_success "Installed Besu to /opt/besu"

# Create directories
print_section "Creating Directories"
mkdir -p /opt/besu/data /opt/besu/keys
print_success "Created Besu directories"

# Copy genesis file
print_section "Configuring Blockchain"
cp genesis.json /opt/besu/genesis.json
print_success "Copied genesis file"

# Copy static-nodes.json
cp static-nodes.json /opt/besu/data/
print_success "Copied static-nodes.json"

# Handle validator keys
print_section "Setting Up Validator Keys"

# Ask if user wants to generate new keys or import existing
echo -e "${YELLOW}Do you want to:${NC}"
echo "1) Generate a new validator key (recommended)"
echo "2) Import an existing private key"
read -p "Enter your choice (1 or 2): " KEY_CHOICE

if [ "$KEY_CHOICE" == "1" ]; then
    # Generate a new private key
    print_info "Generating new validator key..."
    
    # Create a secure backup directory
    BACKUP_DIR="/root/validator-${VALIDATOR_NUM}-keys-backup"
    mkdir -p $BACKUP_DIR
    chmod 700 $BACKUP_DIR
    
    # Generate the key and export the public key in one command
    besu --data-path=/opt/besu/data \
         --node-private-key-file=/opt/besu/keys/nodekey \
         public-key export --to=/opt/besu/keys/key.pub
    
    # Backup the keys
    cp /opt/besu/keys/nodekey $BACKUP_DIR/
    cp /opt/besu/keys/key.pub $BACKUP_DIR/
    
    # Display the public key
    PUBLIC_KEY=$(cat /opt/besu/keys/key.pub)
    print_success "Generated new validator key"
    print_info "Public Key: $PUBLIC_KEY"
    
    # Export and display the validator address
    besu --node-private-key-file=/opt/besu/keys/nodekey \
         public-key export-address --to=/opt/besu/keys/address.txt
    VALIDATOR_ADDRESS=$(cat /opt/besu/keys/address.txt)
    print_info "Validator Address: $VALIDATOR_ADDRESS"
    
    # Save address to backup
    echo $VALIDATOR_ADDRESS > $BACKUP_DIR/address.txt
    
    print_info "Your private key has been backed up to: $BACKUP_DIR"
    print_info "IMPORTANT: Keep this directory secure! It contains your validator's private key."
    print_info "You will need to propose this address to be added to the validator set."
else
    # Import existing private key
    print_info "Importing existing private key..."
    read -p "Enter your private key (without 0x prefix): " PRIVATE_KEY
    
    # Save the private key
    echo $PRIVATE_KEY > /opt/besu/keys/nodekey
    chmod 600 /opt/besu/keys/nodekey
    
    # Export the public key and address in one command
    besu --node-private-key-file=/opt/besu/keys/nodekey \
         public-key export --to=/opt/besu/keys/key.pub
    
    # Display the public key
    PUBLIC_KEY=$(cat /opt/besu/keys/key.pub)
    print_success "Imported private key"
    print_info "Public Key: $PUBLIC_KEY"
    
    # Export and display the validator address
    besu --node-private-key-file=/opt/besu/keys/nodekey \
         public-key export-address --to=/opt/besu/keys/address.txt
    VALIDATOR_ADDRESS=$(cat /opt/besu/keys/address.txt)
    print_info "Validator Address: $VALIDATOR_ADDRESS"
    print_info "You will need to propose this address to be added to the validator set."
fi

# Create systemd service
print_section "Creating Systemd Service"
cp besu-validator.service /etc/systemd/system/besu-validator.service
sed -i "s/IP_ADDRESS/${IP_ADDRESS}/" /etc/systemd/system/besu-validator.service
print_success "Created systemd service"

# Add bootnodes parameter for non-bootnode validators
if [ "$VALIDATOR_NUM" -ne 1 ]; then
    print_info "Configuring bootnode connection..."
    
    # Use hardcoded bootnode enode URL for Validator 1
    BOOTNODE_ENODE="enode://3cc9ca6ca6133511ee31ec7a079379b1a77defb0d098e8c9dd84b12b443287f78cbc92f61b7959a940759f24c7ef7fddc932f08337fdd603a2b6ac14a5b00e29@167.86.95.117:30303"
    
    # Add the bootnode to the service file
    sed -i "/--sync-mode=FULL/a --bootnodes=${BOOTNODE_ENODE} \\\\" /etc/systemd/system/besu-validator.service
    print_success "Added bootnode configuration"
fi

# Enable and start the service
print_section "Starting Validator Service"
systemctl daemon-reload
systemctl enable besu-validator
systemctl start besu-validator
print_success "Started validator service"

print_section "Deployment Complete"
print_success "Validator $VALIDATOR_NUM setup complete!"
print_info "Check the status with: systemctl status besu-validator"
print_info "View logs with: journalctl -u besu-validator -f"

print_section "Next Steps"
print_info "Your validator is running but is not yet part of the validator set."
print_info "To add your validator to the network, you need to propose it using an existing validator:"
echo ""
echo "curl -X POST -H \"Content-Type: application/json\" --data '{\"jsonrpc\":\"2.0\",\"method\":\"qbft_proposeValidatorVote\",\"params\":[\"${VALIDATOR_ADDRESS}\", true],\"id\":1}' http://EXISTING_VALIDATOR_IP:8545"
echo ""
print_info "A majority of existing validators must execute this call for your validator to be added."
