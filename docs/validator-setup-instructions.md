# Studio Blockchain Validator Node Setup Instructions

This document provides comprehensive instructions for setting up a validator node for the Studio Blockchain network. It incorporates lessons learned from actual deployments and addresses common challenges.

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
mkdir -p ~/studio-validator/data/geth
mkdir -p ~/studio-validator/scripts
mkdir -p ~/studio-validator/backups/{daily,weekly}
```

### 6. Create Your Validator Account

Create a new account for your validator:

```bash
# Create a password file
echo "your-strong-password" > ~/studio-validator/password.txt
chmod 600 ~/studio-validator/password.txt

# Create a new account
geth --datadir ~/studio-validator/data account new --password ~/studio-validator/password.txt

# Save your account address to a file for easy reference
geth --datadir ~/studio-validator/data account list | grep -o '0x[0-9a-fA-F]\{40\}' > ~/studio-validator/address.txt
```

Alternatively, you can import an existing private key:

```bash
# Create a temporary file with the private key (without 0x prefix)
echo "your-private-key-without-0x-prefix" > /tmp/private-key.txt

# Import the private key
geth account import --datadir ~/studio-validator/data --password ~/studio-validator/password.txt /tmp/private-key.txt

# Remove the temporary private key file for security
rm /tmp/private-key.txt

# Save your account address to a file for easy reference
geth --datadir ~/studio-validator/data account list | grep -o '0x[0-9a-fA-F]\{40\}' > ~/studio-validator/address.txt
```

### 7. Obtain the Correct Genesis File

**CRITICAL STEP**: You must use the exact same genesis.json file as the existing network. Even a single character difference will result in a different genesis block hash, preventing your node from connecting to the network.

```bash
# Contact the Studio Blockchain team to obtain the correct genesis.json file
# Save it to ~/studio-validator/genesis.json
```

Do NOT modify the genesis.json file in any way. The extradata field and alloc section must match exactly what is used by the existing network.

### 8. Create Static Nodes Configuration

Create the config.toml file with static nodes configuration:

```bash
cat > ~/studio-validator/data/geth/config.toml << 'EOF'
[Node.P2P]
StaticNodes = [
  "enode://673c250c3a7c91f5900cbe1bc605de2a2b94ebf0e853ceba70dc556249b76e4d4ce4b25eb13e13e32689365d50e08ff8fcf704b0827150e84164a04d58118864@173.249.16.253:30303",
  "enode://be9ff49b5a918370d80237faeca6ff260cb54431b0d71ac766e7b965b47ecca1bb0db44fb9501132a7f0449a43777e55baeeae2d00e4168484003c9bdc8d38bf@173.212.200.31:30303",
  "enode://c4f0744053f530f887f1b1ca03c79415a2fac2bbd8576d4e978f7e0e902b0c2fe1bdd5541afc087abaae9f23aa43d66a2749025fa41d7bb47be2168942bae409@161.97.92.8:30303",
  "enode://3295d5cc7495b59f511de451e71a614f84084119b0ad25c2758edca1c708eb4e32506a39ec86d42c8335828f47ca8bb48d6bbb6d131036e2af6828320e44431f@167.86.95.117:30303"
]
EOF
```

### 9. Initialize the Blockchain

Initialize the blockchain with the genesis file:

```bash
geth --datadir ~/studio-validator/data init ~/studio-validator/genesis.json
```

### 10. Create Start Script

Create the start script:

```bash
cat > ~/studio-validator/scripts/start.sh << 'EOF'
#!/bin/bash
echo "Starting Studio Blockchain Validator Node..."

VALIDATOR_ADDRESS=$(cat ~/studio-validator/address.txt)
echo "Validator address: $VALIDATOR_ADDRESS"

# Create a backup of the data directory before starting
BACKUP_DIR=~/studio-validator/backups
mkdir -p $BACKUP_DIR/daily
mkdir -p $BACKUP_DIR/weekly
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
echo "Creating backup of blockchain data..."
tar -czf $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-validator/data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
echo "Backup created at $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz"

# Keep only the last 5 backups to save space
ls -t $BACKUP_DIR/daily/blockchain-data-*.tar.gz | tail -n +6 | xargs -r rm

# Start the blockchain node
geth --config ~/studio-validator/data/geth/config.toml \
--datadir ~/studio-validator/data \
--networkid 240241 \
--port 30303 \
--http \
--http.addr "127.0.0.1" \
--http.port 8545 \
--http.corsdomain "*" \
--http.vhosts "*" \
--http.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--ws \
--ws.addr "127.0.0.1" \
--ws.port 8546 \
--ws.origins "*" \
--ws.api "eth,net,web3,personal,miner,admin,clique,txpool,debug" \
--mine \
--miner.gasprice "0" \
--miner.gaslimit "30000000" \
--allow-insecure-unlock \
--unlock $VALIDATOR_ADDRESS \
--password ~/studio-validator/password.txt \
--syncmode full \
--miner.etherbase $VALIDATOR_ADDRESS \
--rpc.allow-unprotected-txs \
--txpool.pricelimit "0" \
--txpool.accountslots "16" \
--txpool.globalslots "16384" \
--txpool.accountqueue "64" \
--txpool.globalqueue "1024" \
--verbosity 4
EOF

chmod +x ~/studio-validator/scripts/start.sh
```

**IMPORTANT**: Note the `--config` flag which is essential for loading the static nodes configuration.

### 11. Create Systemd Service File

Create the systemd service file:

```bash
cat > /etc/systemd/system/geth-studio-validator.service << 'EOF'
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/root/studio-validator/scripts/start.sh
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
systemctl daemon-reload
systemctl enable geth-studio-validator.service
systemctl start geth-studio-validator
```

### 13. Verify the Deployment

Check the status of the service:

```bash
systemctl status geth-studio-validator
```

Check the blockchain logs:

```bash
journalctl -u geth-studio-validator -f
```

## Adding Your Node as a Validator

After your node is set up and running, you need to have it added as a validator to the network. This requires existing validators to propose and vote for your node.

### 1. Verify Your Node is Syncing

First, check if your node is syncing with the network:

```bash
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://127.0.0.1:8545
```

The result should be a hex number representing the current block number. If it's `0x0`, your node hasn't started syncing yet.

### 2. Check Your Node's Peers

Verify that your node is connected to the network:

```bash
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' http://127.0.0.1:8545
```

You should see a list of peers that your node is connected to.

### 3. Request to be Added as a Validator

Contact the existing validators with your validator address:

```bash
cat ~/studio-validator/address.txt
```

The existing validators will need to propose your address using the `clique_propose` RPC method:

```bash
# This command needs to be run on each existing validator node
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"clique_propose","params":["YOUR_VALIDATOR_ADDRESS", true],"id":1}' http://127.0.0.1:8545
```

### 4. Verify You've Been Added as a Validator

After the existing validators have proposed your node, check if you've been added to the list of signers:

```bash
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"clique_getSigners","params":[],"id":1}' http://127.0.0.1:8545
```

Your address should appear in the list of signers.

### 5. Verify Your Node is Mining

Check if your node is mining blocks:

```bash
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' http://127.0.0.1:8545
```

The result should be `true` if your node is mining.

## Troubleshooting

### Genesis Block Mismatch

If you see errors like `genesis mismatch` in the logs, it means your genesis block hash doesn't match the one used by the network.

**Solution**: Obtain the exact genesis.json file used by the existing network and reinitialize your blockchain:

```bash
# Stop the validator service
systemctl stop geth-studio-validator

# Remove the existing chaindata
rm -rf ~/studio-validator/data/geth/chaindata
rm -rf ~/studio-validator/data/geth/lightchaindata
rm -rf ~/studio-validator/data/geth/nodes

# Initialize with the correct genesis file
geth --datadir ~/studio-validator/data init ~/studio-validator/genesis.json

# Start the validator service
systemctl start geth-studio-validator
```

### Static Nodes Not Connecting

If your node isn't connecting to the static nodes, check if the config.toml file is being loaded correctly.

**Solution**: Ensure the `--config` flag is included in the start script:

```bash
geth --config ~/studio-validator/data/geth/config.toml ...
```

### Account Unlock Failure

If you see errors like `Failed to unlock account` in the logs, it means the password provided doesn't match the one used to create the account.

**Solution**: Re-import the account with the correct password:

```bash
# Stop the validator service
systemctl stop geth-studio-validator

# Remove the existing keystore files
rm -rf ~/studio-validator/data/keystore/*

# Create a new password file
echo "your-correct-password" > ~/studio-validator/password.txt
chmod 600 ~/studio-validator/password.txt

# Re-import the private key
echo "your-private-key-without-0x-prefix" > /tmp/private-key.txt
geth account import --datadir ~/studio-validator/data --password ~/studio-validator/password.txt /tmp/private-key.txt
rm /tmp/private-key.txt

# Start the validator service
systemctl start geth-studio-validator
```

### Node Not Syncing

If your node isn't syncing blocks, check if it's connected to any peers:

```bash
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' http://127.0.0.1:8545
```

**Solution**: If you don't see any peers, check your network configuration and firewall settings. Ensure port 30303 is open for both TCP and UDP.

## Maintenance

### Backups

The system is configured to automatically create backups in the `~/studio-validator/backups/daily/` directory. You can also create manual backups:

```bash
# Create a manual backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
tar -czf ~/studio-validator/backups/manual-backup-$TIMESTAMP.tar.gz -C ~/studio-validator/data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
```

### Monitoring

Regularly check the status of your validator:

```bash
# Check if the service is running
systemctl status geth-studio-validator

# Check the logs for errors
journalctl -u geth-studio-validator -n 100

# Check if your node is mining
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' http://127.0.0.1:8545

# Check if your node is in the list of signers
curl -s -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"clique_getSigners","params":[],"id":1}' http://127.0.0.1:8545
```

### Updating

To update the Geth client:

```bash
# Stop the validator service
systemctl stop geth-studio-validator

# Download and install the new version of Geth
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-NEW_VERSION.tar.gz
tar -xzf geth-linux-amd64-NEW_VERSION.tar.gz
sudo cp geth-linux-amd64-NEW_VERSION/geth /usr/local/bin/
rm -rf geth-linux-amd64-NEW_VERSION*

# Start the validator service
systemctl start geth-studio-validator
```

## Contact

For questions or support, please contact:

Email: office@studio-blockchain.com
