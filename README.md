# Studio Blockchain Mainnet (Updated May 2025)

This repository contains all the necessary files and instructions to set up and run a validator node for the Studio Blockchain network.

## What is Studio Blockchain?

Studio Blockchain is an advanced Ethereum-compatible blockchain built with cutting-edge technology for next-generation decentralized applications. It leverages the QBFT (Quorum Byzantine Fault Tolerance) consensus mechanism, which provides Byzantine fault tolerance and is more energy-efficient than Proof of Work while allowing for faster block times.

### Key Features

- **High Performance**: Fast block times (5 seconds) and high throughput
- **Energy Efficient**: QBFT consensus requires minimal computational resources
- **Enterprise-Grade Security**: Byzantine fault tolerance ensures network security even if some validators are compromised
- **Zero Gas Fees**: Standard transactions have zero gas fees, making the blockchain more accessible for everyday users
- **Ethereum Compatibility**: Full compatibility with Ethereum tools, wallets, and smart contracts

### On-Chain Neural Networks

What sets Studio Blockchain apart is its revolutionary integration of on-chain neural networks. As the first Ethereum fork to incorporate small language learning models (LLMs) directly into its protocol, Studio Blockchain can:

- **Predict and optimize block heights** to dynamically adjust for network conditions
- **Intelligently manage transaction processing** based on real-time network analysis
- **Adapt to changing network demands** through continuous on-chain learning

This neural network integration enables a unique gas fee structure where standard transactions have zero gas fees, while a transaction priority system allows users to optionally add fees to expedite processing during high-demand periods. This creates a more accessible blockchain for everyday users while maintaining network efficiency during peak usage.
## Network Information

- **Network ID**: 240241
- **Block Time**: 5 seconds
- **Consensus**: QBFT (Quorum Byzantine Fault Tolerance)
- **Gas Model**: Zero-fee standard transactions with optional priority fees
- **RPC URL**: https://mainnet.studio-blockchain.com https://mainnet2.studio-blockchain.com https://mainnet3.studio-blockchain.com/ https://mainnet.studio-scan.com/ https://mainnet2.studio-scan.com/
- **WebSocket URL**: wss://mainnet.studio-blockchain.com:8547

## Repository Structure

- `besu-qbft/`: Contains all files needed for the QBFT blockchain
  - `genesis.json`: The genesis block configuration
  - `static-nodes.json`: Configuration for peer discovery
  - `deploy.sh`: Script for deploying a validator node
  - `deploy-local.sh`: Script for deploying a validator on the local machine
  - `package.sh`: Script for packaging files for deployment
  - `besu-validator.service`: Systemd service file for running a validator
  - `besu-validator-bootnode.service`: Systemd service file for running a bootnode validator
  - `Node-1/` to `Node-5/`: Validator key files for the initial validators
- `docs/`: Documentation
  - `validator-setup-instructions.md`: Detailed manual setup instructions
  - `troubleshooting.md`: Common issues and solutions
  - `monitoring-guide.md`: Guide for monitoring validator health

## Setting Up a Validator Node

### Prerequisites

- Ubuntu/Debian Linux
- Root access to the server
- Java 11 or later (will be installed by the setup script)

### Automated Setup (Recommended)

1. Clone this repository:
   ```bash
   git clone https://github.com/StudioPlatforms/Studio-Mainnet.git
   cd Studio-Mainnet
   ```

2. Make the scripts executable:
   ```bash
   chmod +x besu-qbft/*.sh
   ```

3. Run the deployment script:
   ```bash
   cd besu-qbft
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
   - Install Java and Hyperledger Besu
   - Set up the validator node with the correct configuration
   - Create and start the systemd service

### Manual Setup

For detailed instructions on manually setting up a validator node, see [Validator Setup Instructions](docs/validator-setup-instructions.md).

## Monitoring and Maintenance

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

## Troubleshooting

If you encounter any issues during setup or operation, see [Troubleshooting](docs/troubleshooting.md) for common issues and solutions.

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.
