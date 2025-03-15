#!/bin/bash

echo "Initializing Studio Blockchain Mainnet Network..."

# Create validator account
echo "Creating password file..."
echo "Please enter a strong password for your validator account:"
read -s PASSWORD
echo "$PASSWORD" > ~/studio-mainnet/node/password.txt
chmod 600 ~/studio-mainnet/node/password.txt

# Save the validator address
echo "0x856157992B74A799D7A09F611f7c78AF4f26d309" > ~/studio-mainnet/node/address.txt

# Initialize the blockchain with the genesis block
echo "Initializing blockchain with genesis block..."
geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json

echo "Mainnet initialization complete!"
echo "Your validator address is: 0x856157992B74A799D7A09F611f7c78AF4f26d309"
echo ""
echo "To start the node, run: ./start.sh"
