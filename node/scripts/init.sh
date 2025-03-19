#!/bin/bash
echo "Initializing Studio Blockchain Mainnet Network..."

# Create data directory
mkdir -p ~/studio-mainnet/node/data

# Create password file
echo "E30m20b20" > ~/studio-mainnet/node/password.txt
chmod 600 ~/studio-mainnet/node/password.txt

# Create new account or import existing one
echo "Creating validator account..."
geth --datadir ~/studio-mainnet/node/data account new --password ~/studio-mainnet/node/password.txt

# Save the address
VALIDATOR_ADDRESS=$(geth --datadir ~/studio-mainnet/node/data account list | head -n 1 | grep -o '0x[0-9a-fA-F]\+')
echo "$VALIDATOR_ADDRESS" > ~/studio-mainnet/node/address.txt

# Update genesis.json with the new validator address
# This step is only needed if you're creating a new validator address
# If you're using the original validator, you can skip this step
if [ "$VALIDATOR_ADDRESS" != "0x856157992B74A799D7A09F611f7c78AF4f26d309" ]; then
    echo "WARNING: You're using a new validator address. This will create a different blockchain!"
    echo "If you want to use the original validator, you need to import the original private key."
    echo "Press Ctrl+C to abort or Enter to continue with the new validator."
    read
    
    # Update extradata in genesis.json
    # This is a simplified approach - for production, use a proper JSON parser
    VALIDATOR_ADDRESS_NO_PREFIX=${VALIDATOR_ADDRESS:2}
    sed -i "s/856157992B74A799D7A09F611f7c78AF4f26d309/$VALIDATOR_ADDRESS_NO_PREFIX/g" ~/studio-mainnet/node/genesis.json
    
    # Update alloc in genesis.json
    sed -i "s/\"0x856157992B74A799D7A09F611f7c78AF4f26d309\"/\"$VALIDATOR_ADDRESS\"/g" ~/studio-mainnet/node/genesis.json
fi

# Initialize the genesis block
echo "Initializing blockchain with genesis block..."
geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json

# Create static-nodes.json file
mkdir -p ~/studio-mainnet/node/data/geth
echo "[]" > ~/studio-mainnet/node/data/geth/static-nodes.json

echo "Mainnet initialization complete!"
echo "Your validator address is: $(cat ~/studio-mainnet/node/address.txt)"
echo ""
echo "To start the node, run: ./start.sh"
