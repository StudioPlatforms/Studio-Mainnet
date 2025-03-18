#!/bin/bash

echo "Starting Studio Blockchain Mainnet Node..."

# Get the validator address
VALIDATOR_ADDRESS=$(cat ~/studio-mainnet/node/address.txt)
echo "Validator address: $VALIDATOR_ADDRESS"

# Start the blockchain node
geth --datadir ~/studio-mainnet/node/data \
--networkid 240241 \
--port 30303 \
--http \
--http.addr "0.0.0.0" \
--http.port 8545 \
--http.corsdomain "*" \
--http.vhosts "*" \
--http.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--ws \
--ws.addr "0.0.0.0" \
--ws.port 8546 \
--ws.origins "*" \
--ws.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--mine \
--miner.gasprice "0" \
--miner.gaslimit "30000000" \
--allow-insecure-unlock \
--unlock $VALIDATOR_ADDRESS \
--password ~/studio-mainnet/node/password.txt \
--syncmode full \
--miner.etherbase $VALIDATOR_ADDRESS \
--rpc.allow-unprotected-txs \
--txpool.pricelimit "0" \
--txpool.accountslots "16" \
--txpool.globalslots "16384" \
--txpool.accountqueue "64" \
--txpool.globalqueue "1024" \
--verbosity 3
