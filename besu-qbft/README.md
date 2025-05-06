# Studio Blockchain QBFT Deployment

This directory contains all the necessary files to deploy a new Studio Blockchain validator node using Hyperledger Besu with QBFT consensus.

## QBFT Consensus

QBFT (Quorum Byzantine Fault Tolerance) is an enterprise-grade consensus algorithm that provides:

- **Byzantine Fault Tolerance**: The network can tolerate up to f = (n-1)/3 faulty validators, where n is the total number of validators
- **Immediate Finality**: Once a block is added to the chain, it is final and cannot be reverted
- **High Performance**: Fast block times (5 seconds) and high throughput
- **Energy Efficiency**: No mining required, making it environmentally friendly

## Network Configuration

- **Chain ID**: 240241
- **Block Time**: 5 seconds
- **Epoch Length**: 30,000 blocks
- **Gas Limit**: 50,000,000
- **Contract Size Limit**: 1 MiB
- **Init Code Size Limit**: 1 MiB
- **Zero Base Fee**: Enabled (fee-less transactions)
- **Minimum Gas Price**: 1000 wei
- **Minimum Priority Fee**: 1000 wei

## Deployment Instructions

### Prerequisites

- Ubuntu/Debian Linux
- Root access to the server
- Internet connection

### Automated Deployment

1. Make the deployment scripts executable:
   ```bash
   chmod +x deploy.sh deploy-local.sh package.sh
   ```

2. Run the deployment script with the appropriate validator number and IP address:
   ```bash
   ./deploy.sh <validator_number> <ip_address>
   ```

   Where:
   - `<validator_number>` is a unique number for your validator. Use 8 or higher, as numbers 1-7 are reserved for the initial validators.
   - `<ip_address>` is the public IP address of your server where the validator will run.

   For example:
   ```bash
   ./deploy.sh 8 203.0.113.10
   ```

   The script will:
   - Stop and disable any existing validator service
   - Install Java and Hyperledger Besu
   - Set up the directories and copy the necessary files
   - Create and start the systemd service

3. If you're deploying on the current server, you can use the deploy-local.sh script:
   ```bash
   ./deploy-local.sh
   ```

### Manual Deployment

If you prefer to deploy manually, follow these steps:

1. Install Java 11 or later:
   ```bash
   apt-get update
   apt-get install -y openjdk-21-jdk
   ```

2. Install other dependencies:
   ```bash
   apt-get install -y jq curl tar wget
   ```

3. Download and install Hyperledger Besu:
   ```bash
   wget https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/25.4.1/besu-25.4.1.tar.gz
   tar -xzf besu-25.4.1.tar.gz
   mkdir -p /usr/local/bin/
   cp -r besu-25.4.1/bin/besu /usr/local/bin/
   ```

4. Create the necessary directories:
   ```bash
   mkdir -p /opt/besu/data
   mkdir -p /opt/besu/keys
   ```

5. Copy the genesis file:
   ```bash
   cp genesis.json /opt/besu/
   ```

6. Create a static-nodes.json file in the data directory:
   ```bash
   cp static-nodes.json /opt/besu/data/
   ```

7. Generate or copy validator keys:
   ```bash
   # For a new validator
   besu --node-private-key-file=/opt/besu/keys/nodekey public-key export --to=/tmp/publickey.txt
   
   # Or copy an existing key
   # cp Node-X/keys/nodekey /opt/besu/keys/
   ```

8. Create a systemd service file:
   ```bash
   cp besu-validator.service /etc/systemd/system/
   ```

9. Enable and start the service:
   ```bash
   systemctl daemon-reload
   systemctl enable besu-validator
   systemctl start besu-validator
   ```

## Monitoring and Troubleshooting

### Checking Validator Status

To check if your validator is running:
```bash
systemctl status besu-validator
```

To view the logs:
```bash
journalctl -u besu-validator -f
```

### Checking Blockchain Status

To check the current block number:
```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
```

To check the number of connected peers:
```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545
```

To check the validator list:
```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' http://localhost:8545
```

### Common Issues

1. **Validator not connecting to peers**:
   - Check if the static-nodes.json file is correctly placed in the data directory
   - Verify that port 30303 is open in your firewall
   - Restart the validator service

2. **Validator not producing blocks**:
   - Check if the validator is in the validator list
   - Verify that the validator is connected to other validators
   - Check the logs for any errors

3. **RPC endpoint not responding**:
   - Verify that the validator service is running
   - Check if port 8545 is open in your firewall
   - Restart the validator service

## Adding a New Validator

To add a new validator to the network:

1. Deploy a new node using the instructions above
   - Remember to use a validator number 8 or higher, as numbers 1-7 are reserved for the initial validators:
     - Validator 1: 167.86.95.117
     - Validator 2: 173.212.200.31
     - Validator 3: 161.97.92.8
     - Validator 4: 173.249.16.253
     - Validator 5: 62.171.162.49
     - Validators 6-7: Reserved for future use

2. Propose the new validator using the QBFT API:
   ```bash
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["0xNEW_VALIDATOR_ADDRESS", true],"id":1}' http://localhost:8545
   ```
3. A majority of existing validators must execute this call for the new validator to be added

## Removing a Validator

To remove a validator from the network:

1. Propose the removal using the QBFT API:
   ```bash
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["0xVALIDATOR_ADDRESS", false],"id":1}' http://localhost:8545
   ```
2. A majority of existing validators must execute this call for the validator to be removed
