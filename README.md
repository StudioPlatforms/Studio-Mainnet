# Studio Blockchain Mainnet

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
- **RPC URL**: https://mainnet.studio-blockchain.com
- **WebSocket URL**: wss://mainnet.studio-blockchain.com:8547

## How to Set Up a Validator Node

Follow these step-by-step instructions to set up your own validator node for the Studio Blockchain network:

### 1. System Requirements

Make sure your server meets these minimum requirements:
- Ubuntu 20.04 LTS or newer
- At least 4 CPU cores
- At least 8GB RAM
- At least 100GB disk space
- Stable internet connection

### 2. Clone This Repository

```bash
git clone https://github.com/StudioPlatforms/Studio-Mainnet.git
cd Studio-Mainnet
```

### 3. Install Dependencies

Install the required dependencies:

```bash
apt-get update
apt-get upgrade -y
apt-get install -y ufw curl wget tar git jq
```

### 4. Install Go

Install Go 1.21.6:

```bash
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
rm go1.21.6.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
source /etc/profile.d/go.sh

# Verify Go installation
go version
```

### 5. Install Geth

Install Geth 1.13.14:

```bash
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
tar -xzf geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
cp geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/bin/
rm -rf geth-linux-amd64-1.13.14-2bd6bd01*

# Verify Geth installation
geth version
```

### 6. Set Up Directory Structure

Create the necessary directories:

```bash
mkdir -p ~/studio-validator/node/{scripts,config,data}
mkdir -p ~/studio-validator/backups/{daily,weekly}
```

### 7. Copy Configuration Files

Copy the configuration files from this repository:

```bash
cp node/genesis.json ~/studio-validator/node/
cp -r node/scripts/* ~/studio-validator/node/scripts/
chmod +x ~/studio-validator/node/scripts/*.sh
```

### 8. Create Static Nodes File

Create the static-nodes.json file to connect to the main node:

```bash
mkdir -p ~/studio-validator/node/data/geth
cat > ~/studio-validator/node/data/geth/static-nodes.json << 'EOF'
[
  "enode://20b8ecf71c1929290c149d7de20408e8140984334e02a54830cf40ae8dcc1a168466949a04bc00847666d11879a9dc98594debdc9a8c20daa461bad47ad81023@62.171.162.49:30303"
]
EOF
```

### 9. Initialize the Blockchain

Run the initialization script:

```bash
cd ~/studio-validator/node/scripts
./init.sh
```

This script will:
- Ask you to create a password for your validator account
- Create a new validator account
- Initialize the blockchain with the genesis block

### 10. Set Up Systemd Services

Copy the systemd service files:

```bash
cp /path/to/Studio-Mainnet/systemd/geth-studio-validator.service /etc/systemd/system/
cp /path/to/Studio-Mainnet/systemd/blockchain-monitor-validator.service /etc/systemd/system/
```

Enable and start the services:

```bash
systemctl daemon-reload
systemctl enable geth-studio-validator.service
systemctl enable blockchain-monitor-validator.service
systemctl start geth-studio-validator
systemctl start blockchain-monitor-validator
```

### 11. Verify the Deployment

Check the status of the services:

```bash
systemctl status geth-studio-validator
systemctl status blockchain-monitor-validator
```

Check the blockchain logs:

```bash
journalctl -u geth-studio-validator -f
```

### 12. Register as a Validator

After your node is set up and running, you need to register it as a validator:

1. Get your validator address:
   ```bash
   cat ~/studio-validator/node/address.txt
   ```

2. Contact the Studio Blockchain team at office@studio-blockchain.com with your validator address to be added to the network.

## Detailed Instructions

For more detailed instructions, see [Validator Setup Instructions](docs/validator-setup-instructions.md).

## Maintenance

### Backups

The system is configured to automatically create backups:
- Daily at 2:00 AM
- Weekly on Sunday at 3:00 AM

Backups are stored in:
- `~/studio-validator/backups/daily/`
- `~/studio-validator/backups/weekly/`

### Monitoring

The monitoring script checks:
- If the node is running
- Available disk space

If any issues are detected, the script will automatically attempt to resolve them.

## Troubleshooting

### Node Not Starting

Check the logs:

```bash
journalctl -u geth-studio-validator -n 100
```

Common issues:
- Port conflicts: Check if port 30303 is already in use
- Disk space: Ensure there's enough disk space available
- Permission issues: Ensure the data directory is owned by the correct user

### Node Not Connecting to Peers

Check the static-nodes.json file:

```bash
cat ~/studio-validator/node/data/geth/static-nodes.json
```

Ensure it contains valid enode URLs. If not, update it and restart the node.

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.
