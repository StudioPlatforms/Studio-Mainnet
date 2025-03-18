# Studio Blockchain Validator Node Setup Instructions

This document provides step-by-step instructions for setting up a validator node for the Studio Blockchain network and connecting it to the main node.

## System Requirements

- Ubuntu 20.04 LTS or newer (or any Linux distribution with systemd)
- At least 4 CPU cores
- At least 8GB RAM
- At least 100GB disk space
- Stable internet connection

## Automated Setup (Recommended)

The easiest way to set up a validator node is to use the automated setup script provided in this repository.

### 1. Clone the Repository

```bash
git clone https://github.com/StudioPlatforms/Studio-Mainnet.git
cd Studio-Mainnet
```

### 2. Make the Scripts Executable

```bash
chmod +x node/scripts/*.sh
```

### 3. Run the Setup Script

```bash
./node/scripts/setup-validator.sh
```

The script will guide you through the setup process and handle:
- Installing dependencies and Geth
- Creating a validator account (or importing an existing one)
- Setting up network configuration
- Configuring monitoring and backups
- Creating systemd services

## Manual Setup

If you prefer to set up the validator node manually, follow these steps:

### 1. Prepare the Server

First, ensure your server is up-to-date and secure:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ufw curl wget tar git jq
```

### 2. Set Up Firewall

Configure the firewall to allow only necessary connections:

```bash
sudo ufw allow ssh
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw --force enable
```

### 3. Install Go

Install Go 1.21.6:

```bash
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
rm go1.21.6.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify Go installation
go version
```

### 4. Install Geth

Install Geth 1.13.14:

```bash
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
tar -xzf geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
sudo cp geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/
rm -rf geth-linux-amd64-1.13.14-2bd6bd01*

# Verify Geth installation
geth version
```

### 5. Create Directory Structure

Create the necessary directories:

```bash
mkdir -p ~/studio-validator/node/{scripts,config,data}
mkdir -p ~/studio-validator/backups/{daily,weekly}
```

### 6. Create Your Validator Account

Create a new account for your validator:

```bash
# Create a password file
echo "your-strong-password" > ~/studio-validator/node/password.txt
chmod 600 ~/studio-validator/node/password.txt

# Create a new account
geth --datadir ~/studio-validator/node/data account new --password ~/studio-validator/node/password.txt

# Note down your account address (it will look like 0x123abc...)
geth --datadir ~/studio-validator/node/data account list
```

Alternatively, you can import an existing private key:

```bash
# Create a temporary file with the private key (without 0x prefix)
echo "your-private-key-without-0x-prefix" > /tmp/private-key.txt

# Import the private key
geth account import --datadir ~/studio-validator/node/data /tmp/private-key.txt --password ~/studio-validator/node/password.txt

# Remove the temporary private key file for security
rm /tmp/private-key.txt

# Note down your account address
geth --datadir ~/studio-validator/node/data account list
```

### 7. Customize the Genesis File

Copy and customize the genesis.json file with your validator address:

```bash
# Copy the genesis file
cp node/genesis.json ~/studio-validator/node/

# Edit the genesis file to replace the placeholder with your validator address
# Replace YOUR_VALIDATOR_ADDRESS_HERE with your actual validator address (without the 0x prefix)
# For example, if your address is 0x123abc..., use 123abc...
sed -i "s/YOUR_VALIDATOR_ADDRESS_HERE/YOUR_ACTUAL_ADDRESS_WITHOUT_0x_PREFIX/g" ~/studio-validator/node/genesis.json
```

> **IMPORTANT**: This step is crucial for you to receive gas fees as a validator. You must replace the placeholder with your own validator address in both the "extradata" field and the "alloc" section.

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

Initialize the blockchain with the genesis file:

```bash
geth --datadir ~/studio-validator/node/data init ~/studio-validator/node/genesis.json
```

### 10. Create Start Script

Create the start script:

```bash
cat > ~/studio-validator/node/scripts/start.sh << 'EOF'
#!/bin/bash
echo "Starting Studio Blockchain Validator Node..."

VALIDATOR_ADDRESS=$(cat ~/studio-validator/node/data/validator-address.txt)
echo "Validator address: $VALIDATOR_ADDRESS"

# Create a backup of the data directory before starting
BACKUP_DIR=~/studio-validator/backups
mkdir -p $BACKUP_DIR/daily
mkdir -p $BACKUP_DIR/weekly
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo "Creating backup of blockchain data..."
tar -czf $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-validator/node data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
echo "Backup created at $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz"

# Keep only the last 5 backups to save space
ls -t $BACKUP_DIR/daily/blockchain-data-*.tar.gz | tail -n +6 | xargs -r rm

# Start the blockchain node
geth --datadir ~/studio-validator/node/data \
--networkid 240241 \
--port 30303 \
--http \
--http.addr "127.0.0.1" \
--http.port 8545 \
--http.api "eth,net,web3,txpool,debug,clique" \
--ws \
--ws.addr "127.0.0.1" \
--ws.port 8546 \
--ws.api "eth,net,web3,txpool,debug,clique" \
--mine \
--miner.gasprice "0" \
--miner.gaslimit "30000000" \
--allow-insecure-unlock \
--unlock $VALIDATOR_ADDRESS \
--password ~/studio-validator/node/password.txt \
--syncmode full \
--miner.etherbase $VALIDATOR_ADDRESS \
--rpc.allow-unprotected-txs \
--txpool.pricelimit "0" \
--txpool.accountslots "16" \
--txpool.globalslots "16384" \
--txpool.accountqueue "64" \
--txpool.globalqueue "1024" \
--metrics \
--metrics.addr "127.0.0.1" \
--metrics.port "6060" \
--verbosity 3
EOF

chmod +x ~/studio-validator/node/scripts/start.sh
```

### 11. Create Systemd Service Files

Create the systemd service files:

```bash
# For user-level service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/studio-validator.service << 'EOF'
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/home/$(whoami)/studio-validator/node/scripts/start.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

# Ensure data integrity during shutdown
KillSignal=SIGINT
TimeoutStopSec=300

[Install]
WantedBy=default.target
EOF

# For system-level service (requires root)
sudo cat > /etc/systemd/system/geth-studio-validator.service << 'EOF'
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=$(whoami)
ExecStart=/home/$(whoami)/studio-validator/node/scripts/start.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=geth-studio-validator
LimitNOFILE=65536
LimitNPROC=65536

# Ensure data integrity during shutdown
KillSignal=SIGINT
TimeoutStopSec=300

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF
```

### 12. Start the Validator Node

Start the validator node using systemd:

```bash
# For user-level service
systemctl --user daemon-reload
systemctl --user enable studio-validator.service
systemctl --user start studio-validator

# For system-level service (requires root)
sudo systemctl daemon-reload
sudo systemctl enable geth-studio-validator.service
sudo systemctl start geth-studio-validator
```

### 13. Verify the Deployment

Check the status of the service:

```bash
# For user-level service
systemctl --user status studio-validator

# For system-level service
sudo systemctl status geth-studio-validator
```

Check the blockchain logs:

```bash
# For user-level service
journalctl --user -u studio-validator -f

# For system-level service
sudo journalctl -u geth-studio-validator -f
```

## 14. Add This Node as a Validator

After the node is set up and running, you need to add it as a validator to the network. To do this, you need to:

1. Get the validator address from this node:
   ```bash
   cat ~/studio-validator/node/data/validator-address.txt
   ```

2. Contact the Studio Blockchain team at office@studio-blockchain.com with your validator address to be added to the network.

## Preventing Ghost State Issues

To prevent ghost state issues, follow these best practices:

1. **Ensure Proper Network Connectivity**:
   - Make sure your validator has a stable internet connection
   - Configure your firewall to allow incoming and outgoing connections on port 30303
   - Use the static-nodes.json file to connect to known validators

2. **Maintain Time Synchronization**:
   - Install and configure NTP to ensure your system clock is accurate
   - Time drift can cause consensus issues in Clique PoA networks

3. **Monitor Validator Participation**:
   - Regularly check if your validator is signing blocks
   - Monitor the number of validators in the network
   - Watch for signs of ghost state issues (e.g., no blocks being produced)

4. **Regular Backups**:
   - Create regular backups of your validator data
   - Test backup restoration procedures

5. **Proper Shutdown Procedures**:
   - Always use SIGINT to stop the geth process (systemctl stop)
   - Avoid force killing the process

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
- Block production
- Validator participation

If any issues are detected, the script will automatically attempt to resolve them.

## Troubleshooting

### Node Not Starting

Check the logs:

```bash
journalctl --user -u studio-validator -n 100
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

### Ghost State Issues

If you suspect a ghost state issue (no blocks being produced), check:

1. The number of validators in the network:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners()'
   ```

2. If your validator is in the signers list:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners().includes(eth.coinbase)'
   ```

3. The time since the last block:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'Math.floor(Date.now()/1000) - eth.getBlock(eth.blockNumber).timestamp'
   ```

If you detect a ghost state issue, contact the Studio Blockchain team immediately.

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com
