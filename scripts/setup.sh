#!/bin/bash

# Studio Blockchain Validator Node Setup Script
# This script automates the setup of a validator node for the Studio Blockchain network

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Studio Blockchain Validator Node Setup ===${NC}"
echo "This script will set up a validator node for the Studio Blockchain network."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p ~/studio-mainnet/node/data
mkdir -p ~/studio-mainnet/node/scripts

# Copy files
echo -e "${YELLOW}Copying files...${NC}"
cp ./genesis.json ~/studio-mainnet/node/
cp ./scripts/start.sh ~/studio-mainnet/node/scripts/
cp ./scripts/enhanced_monitor_blockchain.sh ~/root/

# Make scripts executable
chmod +x ~/studio-mainnet/node/scripts/start.sh
chmod +x ~/root/enhanced_monitor_blockchain.sh

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
apt-get update
apt-get install -y build-essential golang-go curl software-properties-common mailutils

# Install Go Ethereum (geth)
echo -e "${YELLOW}Installing Go Ethereum...${NC}"
add-apt-repository -y ppa:ethereum/ethereum
apt-get update
apt-get install -y ethereum

# Verify installation
geth version

# Initialize blockchain
echo -e "${YELLOW}Initializing blockchain...${NC}"
geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json

# Create validator account
echo -e "${YELLOW}Creating validator account...${NC}"
echo -e "${RED}You will be prompted to enter a password for your validator account.${NC}"
echo -e "${RED}IMPORTANT: Remember this password! You will need it to unlock your account.${NC}"
geth --datadir ~/studio-mainnet/node/data account new

# Get account address
ACCOUNT=$(geth --datadir ~/studio-mainnet/node/data account list | head -n 1 | grep -o '0x[0-9a-fA-F]\+')
echo -e "${GREEN}Your validator account address is: ${ACCOUNT}${NC}"
echo "$ACCOUNT" > ~/studio-mainnet/node/address.txt

# Create password file
echo -e "${YELLOW}Creating password file...${NC}"
echo -e "${RED}Enter your account password to create a password file:${NC}"
read -s PASSWORD
echo "$PASSWORD" > ~/studio-mainnet/node/password.txt
chmod 600 ~/studio-mainnet/node/password.txt

# Configure static nodes
echo -e "${YELLOW}Configuring static nodes...${NC}"
cp ./config/static-nodes.json.template ~/studio-mainnet/node/data/geth/static-nodes.json

# Set up systemd services
echo -e "${YELLOW}Setting up systemd services...${NC}"
cp ./config/geth-studio.service /etc/systemd/system/
cp ./config/blockchain-monitor.service /etc/systemd/system/

# Update paths in service files
sed -i "s|/root/studio-mainnet|$HOME/studio-mainnet|g" /etc/systemd/system/geth-studio.service
sed -i "s|/root/enhanced_monitor_blockchain.sh|$HOME/enhanced_monitor_blockchain.sh|g" /etc/systemd/system/blockchain-monitor.service

# Configure email for monitoring
echo -e "${YELLOW}Configuring email for monitoring...${NC}"
echo -e "${RED}Enter your email address for alerts:${NC}"
read EMAIL_ADDRESS
sed -i "s|developer@example.com|$EMAIL_ADDRESS|g" ~/root/enhanced_monitor_blockchain.sh

# Reload systemd
systemctl daemon-reload
systemctl enable geth-studio
systemctl enable blockchain-monitor

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo "Your validator node has been set up successfully."
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Start your node: systemctl start geth-studio"
echo "2. Start monitoring: systemctl start blockchain-monitor"
echo "3. Check node status: systemctl status geth-studio"
echo "4. View logs: journalctl -u geth-studio -f"
echo ""
echo -e "${RED}IMPORTANT: Make sure to back up your keystore files located in:${NC}"
echo "~/studio-mainnet/node/data/keystore/"
echo ""
echo -e "${GREEN}Thank you for joining the Studio Blockchain network!${NC}"
