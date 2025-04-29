# Studio Blockchain Mainnet (Updated March 2025)


This repository contains all the necessary files and instructions to set up and run a validator node for the Studio Blockchain network.

## What is Studio Blockchain?

Studio Blockchain is an advanced Ethereum-compatible blockchain built with cutting-edge technology for next-generation decentralized applications. It leverages the Clique Proof of Authority (PoA) consensus mechanism, which is more energy-efficient than Proof of Work and allows for faster block times.

### On-Chain Neural Networks

What sets Studio Blockchain apart is its revolutionary integration of on-chain neural networks. As the first Ethereum fork to incorporate small language learning models (LLMs) directly into its protocol, Studio Blockchain can:

- **Predict and optimize block heights** to dynamically adjust for network conditions
- **Intelligently manage transaction processing** based on real-time network analysis
- **Adapt to changing network demands** through continuous on-chain learning

This neural network integration enables a unique gas fee structure where standard transactions have zero gas fees, while a transaction priority system allows users to optionally add fees to expedite processing during high-demand periods. This creates a more accessible blockchain for everyday users while maintaining network efficiency during peak usage.

## Network Information

- **Network ID**: 240241
- **Block Time**: 5 seconds
- **Consensus**: Clique Proof of Authority (PoA) with Neural Network Optimization
- **Gas Model**: Zero-fee standard transactions with optional priority fees
- **RPC URL**: https://mainnet.studio-blockchain.com https://mainnet2.studio-blockchain.com https:// https://mainnet3.studio-blockchain.com/ https://mainnet.studio-scan.com/ https://mainnet2.studio-scan.com/
- **WebSocket URL**: wss://mainnet.studio-blockchain.com:8547

## Repository Structure

- `node/genesis.json`: The genesis block configuration template (requires customization with your validator address)
- `node/scripts/`: Scripts for setting up and running the validator node
  - `setup-validator.sh`: Main setup script
  - `common.sh`: Common functions and variables
  - `system-check.sh`: System requirements checking
  - `install.sh`: Installation of dependencies and Geth
  - `account.sh`: Account creation and management
  - `network.sh`: Network configuration
  - `monitoring.sh`: Monitoring setup
  - `backup.sh`: Backup configuration
  - `service.sh`: Service creation and management
- `systemd/`: Systemd service files for running the node as a service
- `docs/`: Documentation
  - `validator-setup-instructions.md`: Detailed manual setup instructions
  - `troubleshooting.md`: Common issues and solutions
  - `monitoring-guide.md`: Guide for monitoring validator health

## Setting Up a Validator Node

### Automated Setup (Recommended)

1. Clone this repository:
   ```bash
   git clone https://github.com/StudioPlatforms/Studio-Mainnet.git
   cd Studio-Mainnet
   ```

2. Make the scripts executable:
   ```bash
   chmod +x node/scripts/*.sh
   ```

3. Run the setup script:
   ```bash
   ./node/scripts/setup-validator.sh
   ```

   The script will guide you through the setup process and handle:
   - Installing dependencies and Geth
   - Creating a validator account (or importing an existing one)
   - Setting up network configuration
   - Configuring monitoring and backups
   - Creating systemd services

### Manual Setup

For detailed instructions on manually setting up a validator node, see [Validator Setup Instructions](docs/validator-setup-instructions.md).

## Validator Account Options

When setting up your validator, you have two options for your validator account:

1. **Create a new account**: The setup script will create a new Ethereum account for your validator.
2. **Import an existing private key**: If you already have an Ethereum account, you can import it using your private key.

## Monitoring and Maintenance

The setup includes comprehensive monitoring tools and automatic backup procedures to ensure your validator runs smoothly. For more information, see [Monitoring Guide](docs/monitoring-guide.md).

## Troubleshooting

If you encounter any issues during setup or operation, see [Troubleshooting](docs/troubleshooting.md) for common issues and solutions.

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.
