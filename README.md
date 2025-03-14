# Studio Blockchain Mainnet

This repository contains all the necessary files and instructions to set up and run a validator node for the Studio Blockchain network.

## What is Studio Blockchain?

Studio Blockchain is a custom Ethereum-compatible blockchain designed for [specific use case/purpose]. It uses the Clique Proof of Authority (PoA) consensus mechanism, which is more energy-efficient than Proof of Work and allows for faster block times.

## System Requirements

### Minimum Requirements
- CPU: 4 cores
- RAM: 8 GB
- Storage: 100 GB SSD
- Network: 100 Mbps connection

### Recommended Specifications
- CPU: 8+ cores
- RAM: 16+ GB
- Storage: 500 GB SSD (NVMe)
- Network: 1 Gbps connection

## Quick Start

To set up a validator node, follow these steps:

1. Clone this repository:
   ```bash
   git clone https://github.com/studio-blockchain/studio-mainnet.git
   cd studio-mainnet
   ```

2. Run the setup script:
   ```bash
   chmod +x scripts/setup.sh
   sudo ./scripts/setup.sh
   ```

3. Start your node:
   ```bash
   sudo systemctl start geth-studio
   ```

4. Start the monitoring service:
   ```bash
   sudo systemctl start blockchain-monitor
   ```

5. Check the status of your node:
   ```bash
   sudo systemctl status geth-studio
   ```

## Manual Setup

If you prefer to set up your node manually, follow the detailed instructions in the [VALIDATOR_SETUP.md](docs/VALIDATOR_SETUP.md) file.

## Monitoring

The repository includes a monitoring script that checks if your node is running properly and sends email alerts if any issues are detected. For more information, see the [MONITORING.md](docs/MONITORING.md) file.

## Troubleshooting

If you encounter any issues, check the [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) file for common problems and solutions.

## Technical Notes

### Bootstrap Node
The `static-nodes.json.template` file contains a bootstrap node IP address (173.249.16.253) which is a permanent node on the Studio Blockchain network. This node helps your validator connect to the network initially.

### Example Validator Address
The monitoring script contains an example Ethereum address (0x856157992b74a799d7a09f611f7c78af4f26d309) which will be replaced with your own validator address during the setup process.

### Configuration Paths
The service files and scripts contain default paths that will be automatically updated during the setup process to match your system's configuration.

## Contributing

We welcome contributions to improve the Studio Blockchain network. Please see the [CONTRIBUTING.md](docs/CONTRIBUTING.md) file for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please contact us at [office@studio-blockchain.com](mailto:office@studio-blockchain.com).

## Community

Join our community:

- [Telegram](https://t.me/studioblockchain)
