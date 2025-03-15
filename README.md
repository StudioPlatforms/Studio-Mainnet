# Studio Blockchain Mainnet

This repository contains all the necessary files and instructions to set up and run a validator node for the Studio Blockchain network.

## What is Studio Blockchain?

Studio Blockchain is a custom Ethereum-compatible blockchain built for specific use cases. It uses the Clique Proof of Authority (PoA) consensus mechanism, which is more energy-efficient than Proof of Work and allows for faster block times.

## Network Information

- **Network ID**: 240241
- **Block Time**: 5 seconds
- **Consensus**: Clique Proof of Authority (PoA)
- **RPC URL**: https://mainnet.studio-blockchain.com
- **WebSocket URL**: wss://mainnet.studio-blockchain.com:8547

## Repository Structure

- `node/genesis.json`: The genesis block configuration
- `node/scripts/`: Scripts for initializing and running the node
  - `init.sh`: Initialization script
  - `start.sh`: Node startup script
  - `monitor_blockchain.sh`: Monitoring script
- `systemd/`: Systemd service files for running the node as a service
- `docs/`: Documentation
  - `validator-setup-instructions.md`: Instructions for setting up a validator node

## Setting Up a Validator Node

For detailed instructions on setting up a validator node, see [Validator Setup Instructions](docs/validator-setup-instructions.md).

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.
