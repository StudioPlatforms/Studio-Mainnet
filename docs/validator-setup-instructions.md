# Validator Setup Instructions

This document provides detailed instructions for setting up a validator node for the Studio Blockchain network using Hyperledger Besu with QBFT consensus.

## System Requirements

- **CPU**: 4+ cores
- **RAM**: 8+ GB
- **Storage**: 100+ GB SSD (will grow over time)
- **Network**: Stable internet connection with 10+ Mbps
- **Operating System**: Ubuntu 20.04 LTS or later / Debian 11 or later
- **Ports**: 30303 (TCP/UDP) for P2P communication, 8545 (TCP) for RPC

## Installation Steps

### 1. Update System and Install Dependencies

```bash
apt-get update
apt-get upgrade -y
apt-get install -y openjdk-21-jdk jq curl tar wget git
```

### 2. Clone the Repository

```bash
git clone https://github.com/StudioPlatforms/Studio-Mainnet.git
cd Studio-Mainnet/besu-qbft
```

### 3. Make Scripts Executable

```bash
chmod +x deploy.sh deploy-local.sh package.sh
```

### 4. Run the Deployment Script

For a new validator, run:

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

If you're deploying on the current server, you can use:

```bash
./deploy-local.sh
```

### 5. Verify Installation

Check if the validator service is running:

```bash
systemctl status besu-validator
```

View the logs:

```bash
journalctl -u besu-validator -f
```

## Manual Installation

If you prefer to install manually or need to customize the installation, follow these steps:

### 1. Install Java

```bash
apt-get update
apt-get install -y openjdk-21-jdk
```

### 2. Install Other Dependencies

```bash
apt-get install -y jq curl tar wget
```

### 3. Download and Install Hyperledger Besu

```bash
wget https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/25.4.1/besu-25.4.1.tar.gz
tar -xzf besu-25.4.1.tar.gz
mkdir -p /usr/local/bin/
cp -r besu-25.4.1/bin/besu /usr/local/bin/
```

### 4. Create Directories

```bash
mkdir -p /opt/besu/data
mkdir -p /opt/besu/keys
```

### 5. Copy Configuration Files

```bash
cp genesis.json /opt/besu/
cp static-nodes.json /opt/besu/data/
```

### 6. Generate or Copy Validator Keys

For a new validator, generate a new key:

```bash
besu --node-private-key-file=/opt/besu/keys/nodekey public-key export --to=/tmp/publickey.txt
```

Or copy an existing key:

```bash
cp Node-X/keys/nodekey /opt/besu/keys/
```

### 7. Create Systemd Service

Create a file at `/etc/systemd/system/besu-validator.service` with the following content:

```
[Unit]
Description=Besu Validator Node
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/besu \
  --data-path=/opt/besu/data \
  --genesis-file=/opt/besu/genesis.json \
  --node-private-key-file=/opt/besu/keys/nodekey \
  --rpc-http-enabled=true \
  --rpc-http-api=ETH,NET,QBFT \
  --rpc-http-cors-origins="*" \
  --p2p-port=30303 \
  --rpc-http-port=8545 \
  --min-gas-price=1000 \
  --min-priority-fee=1000 \
  --nat-method=NONE
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### 8. Enable and Start the Service

```bash
systemctl daemon-reload
systemctl enable besu-validator
systemctl start besu-validator
```

## Network Configuration

### Firewall Configuration

Make sure the following ports are open:

- **30303 TCP/UDP**: For P2P communication with other validators
- **8545 TCP**: For RPC communication (optional, can be restricted to localhost)

For UFW:

```bash
ufw allow 30303/tcp
ufw allow 30303/udp
# Only if you need remote RPC access
# ufw allow 8545/tcp
```

For iptables:

```bash
iptables -A INPUT -p tcp --dport 30303 -j ACCEPT
iptables -A INPUT -p udp --dport 30303 -j ACCEPT
# Only if you need remote RPC access
# iptables -A INPUT -p tcp --dport 8545 -j ACCEPT
```

### Static IP Configuration

It's recommended to use a static IP address for your validator. If your server has a dynamic IP, consider using a service like DynDNS or setting up a static IP with your provider.

## Monitoring

### Basic Monitoring

Check the validator status:

```bash
systemctl status besu-validator
```

View the logs:

```bash
journalctl -u besu-validator -f
```

Check the current block number:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
```

Check the number of connected peers:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545
```

### Advanced Monitoring

For advanced monitoring, consider setting up:

- **Prometheus**: For metrics collection
- **Grafana**: For visualization
- **Alertmanager**: For alerts

## Backup and Recovery

### Backing Up Validator Keys

Regularly backup your validator keys:

```bash
cp /opt/besu/keys/nodekey /path/to/backup/
```

Store the backup in a secure location.

### Backing Up Data Directory

If needed, you can backup the data directory:

```bash
tar -czf besu-data-backup.tar.gz /opt/besu/data
```

### Recovery

To recover from a backup:

1. Stop the validator service:
   ```bash
   systemctl stop besu-validator
   ```

2. Restore the keys:
   ```bash
   cp /path/to/backup/nodekey /opt/besu/keys/
   ```

3. If needed, restore the data directory:
   ```bash
   rm -rf /opt/besu/data
   mkdir -p /opt/besu/data
   tar -xzf besu-data-backup.tar.gz -C /
   ```

4. Start the validator service:
   ```bash
   systemctl start besu-validator
   ```

## Troubleshooting

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

### Checking Logs

To check the logs for errors:

```bash
journalctl -u besu-validator -n 100 | grep ERROR
```

### Restarting the Service

If you encounter issues, try restarting the service:

```bash
systemctl restart besu-validator
```

## Upgrading

To upgrade Hyperledger Besu:

1. Stop the validator service:
   ```bash
   systemctl stop besu-validator
   ```

2. Download and install the new version:
   ```bash
   wget https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/NEW_VERSION/besu-NEW_VERSION.tar.gz
   tar -xzf besu-NEW_VERSION.tar.gz
   cp -r besu-NEW_VERSION/bin/besu /usr/local/bin/
   ```

3. Start the validator service:
   ```bash
   systemctl start besu-validator
   ```

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com
