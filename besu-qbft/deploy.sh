#!/bin/bash

# This script sets up a Besu validator node for the Studio Blockchain
# Usage: ./deploy.sh <validator_number> <ip_address>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <validator_number> <ip_address>"
    echo "Example: $0 1 167.86.95.117"
    exit 1
fi

VALIDATOR_NUM=$1
IP_ADDRESS=$2

echo "Setting up validator $VALIDATOR_NUM with IP $IP_ADDRESS"

# Stop and disable the old Geth validator service
echo "Stopping and disabling the old Geth validator service..."
systemctl stop geth-studio-validator || true
systemctl disable geth-studio-validator || true
sed -i 's/Restart=always/Restart=no/' /etc/systemd/system/geth-studio-validator.service || true
systemctl daemon-reload

# Install prerequisites
echo "Installing prerequisites..."
apt-get update
apt-get install -y openjdk-21-jdk jq curl wget tar

# Download and install Besu
echo "Downloading and installing Besu..."
BESU_VER=$(curl -s https://api.github.com/repos/hyperledger/besu/releases/latest | jq -r .tag_name)
curl -L -o besu-${BESU_VER}.tar.gz https://github.com/hyperledger/besu/releases/download/${BESU_VER}/besu-${BESU_VER}.tar.gz
tar -xzf besu-${BESU_VER}.tar.gz
rm -rf /opt/besu
mv besu-${BESU_VER} /opt/besu
ln -sf /opt/besu/bin/besu /usr/local/bin/besu

# Create directories
echo "Creating directories..."
mkdir -p /opt/besu/data /opt/besu/keys

# Copy genesis file
echo "Copying genesis file..."
cp studio-qbft/genesis.json /opt/besu/genesis.json

# Copy validator keys
echo "Copying validator keys..."
cp studio-qbft/Node-${VALIDATOR_NUM}/keys/* /opt/besu/keys/

# Create systemd service
echo "Creating systemd service..."
cp studio-qbft/besu-validator.service /etc/systemd/system/besu-validator.service
sed -i "s/IP_ADDRESS/${IP_ADDRESS}/" /etc/systemd/system/besu-validator.service

# Add bootnodes parameter for non-bootnode validators
if [ "$VALIDATOR_NUM" -ne 1 ]; then
    # Get the enode URL of the bootnode (validator 1)
    BOOTNODE_IP="167.86.95.117"
    BOOTNODE_PUBKEY=$(cat studio-qbft/Node-1/keys/key.pub | sed 's/^0x//')
    BOOTNODE_ENODE="enode://${BOOTNODE_PUBKEY}@${BOOTNODE_IP}:30303"
    
    # Add the bootnode to the service file
    sed -i "/--sync-mode=FULL/a --bootnodes=${BOOTNODE_ENODE} \\\\" /etc/systemd/system/besu-validator.service
fi

# Enable and start the service
echo "Enabling and starting the service..."
systemctl daemon-reload
systemctl enable besu-validator
systemctl start besu-validator

echo "Validator $VALIDATOR_NUM setup complete!"
echo "Check the status with: systemctl status besu-validator"
echo "View logs with: journalctl -u besu-validator -f"
