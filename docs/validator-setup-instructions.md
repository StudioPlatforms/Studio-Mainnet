# Studio Blockchain Validator Node Setup Instructions

This document provides step-by-step instructions for setting up a validator node for the Studio Blockchain network and connecting it to the main node.

## System Requirements

- Ubuntu 20.04 LTS or newer
- At least 4 CPU cores
- At least 8GB RAM
- At least 100GB disk space
- Stable internet connection

## 1. Prepare the Server

First, ensure your server is up-to-date and secure:

```bash
apt-get update
apt-get upgrade -y
apt-get install -y ufw curl wget tar git jq
```

## 2. Set Up Firewall

Configure the firewall to allow only necessary connections:

```bash
ufw allow ssh
ufw allow 30303/tcp
ufw allow 30303/udp
ufw --force enable
```

## 3. Install Go

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

## 4. Install Geth

Install Geth 1.13.14:

```bash
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
tar -xzf geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
cp geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/bin/
rm -rf geth-linux-amd64-1.13.14-2bd6bd01*

# Verify Geth installation
geth version
```

## 5. Create Directory Structure

Create the necessary directories:

```bash
mkdir -p ~/studio-validator/node/{scripts,config,data}
mkdir -p ~/studio-validator/backups/{daily,weekly}
```

## 6. Create Genesis File

Create the genesis.json file:

```bash
cat > ~/studio-validator/node/genesis.json << 'EOF'
{
  "config": {
    "chainId": 240241,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "extradata": "0x0000000000000000000000000000000000000000000000000000000000000000856157992b74a799d7a09f611f7c78af4f26d3090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "alloc": {
    "0x856157992B74A799D7A09F611f7c78AF4f26d309": {
      "balance": "100000000000000000000000000"
    }
  },
  "coinbase": "0x0000000000000000000000000000000000000000",
  "timestamp": "0x0",
  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "nonce": "0x0000000000000000",
  "number": "0x0",
  "gasUsed": "0x0",
  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"
}
EOF
```

## 7. Create Static Nodes File

Create the static-nodes.json file to connect to the main node:

```bash
mkdir -p ~/studio-validator/node/data/geth
cat > ~/studio-validator/node/data/geth/static-nodes.json << 'EOF'
[
  "enode://20b8ecf71c1929290c149d7de20408e8140984334e02a54830cf40ae8dcc1a168466949a04bc00847666d11879a9dc98594debdc9a8c20daa461bad47ad81023@62.171.162.49:30303"
]
EOF
```

## 8. Create Initialization Script

Create the initialization script:

```bash
cat > ~/studio-validator/node/scripts/init.sh << 'EOF'
#!/bin/bash
echo "Initializing Studio Blockchain Validator Node..."

# Create password file
echo "Please enter a strong password for your validator account:"
read -s PASSWORD
echo "$PASSWORD" > ~/studio-validator/node/password.txt
chmod 600 ~/studio-validator/node/password.txt

# Create new account
echo "Creating validator account..."
geth --datadir ~/studio-validator/node/data account new --password ~/studio-validator/node/password.txt

# Save the address
VALIDATOR_ADDRESS=$(geth --datadir ~/studio-validator/node/data account list | head -n 1 | grep -o '0x[0-9a-fA-F]\+')
echo "$VALIDATOR_ADDRESS" > ~/studio-validator/node/address.txt

# Initialize the genesis block
echo "Initializing blockchain with genesis block..."
geth --datadir ~/studio-validator/node/data init ~/studio-validator/node/genesis.json

echo "Validator initialization complete!"
echo "Your validator address is: $(cat ~/studio-validator/node/address.txt)"
echo ""
echo "To start the node, run: ./start.sh"
EOF

chmod +x ~/studio-validator/node/scripts/init.sh
```

## 9. Create Start Script

Create the start script:

```bash
cat > ~/studio-validator/node/scripts/start.sh << 'EOF'
#!/bin/bash
echo "Starting Studio Blockchain Validator Node..."

VALIDATOR_ADDRESS=$(cat ~/studio-validator/node/address.txt)
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
--verbosity 3
EOF

chmod +x ~/studio-validator/node/scripts/start.sh
```

## 10. Create Monitor Script

Create the monitoring script:

```bash
cat > ~/studio-validator/node/scripts/monitor_blockchain.sh << 'EOF'
#!/bin/bash

# Blockchain Mining Monitor Script
# This script checks if mining is active and restarts it if needed
# It also performs regular backups and monitors system health

LOG_FILE="/var/log/blockchain_monitor.log"
BACKUP_DIR=~/studio-validator/backups
DAILY_BACKUP_TIME="02:00"  # 2 AM
WEEKLY_BACKUP_DAY="Sunday"
WEEKLY_BACKUP_TIME="03:00"  # 3 AM on Sunday

# Create backup directories
mkdir -p $BACKUP_DIR/daily
mkdir -p $BACKUP_DIR/weekly

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_node_health() {
    log_message "Checking node health..."
    
    # Check if geth is running
    if ! pgrep -f "geth --datadir" > /dev/null; then
        log_message "Geth process not found. Restarting service..."
        systemctl restart geth-studio-validator
        log_message "Service restart initiated."
        return
    fi
    
    # Check if RPC is responsive
    if ! curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
        http://localhost:8545 | grep -q "240241"; then
        log_message "RPC endpoint not responsive or wrong network. Restarting service..."
        systemctl restart geth-studio-validator
        log_message "Service restart initiated."
        return
    fi
}

perform_daily_backup() {
    CURRENT_TIME=$(date +%H:%M)
    CURRENT_DAY=$(date +%A)
    
    # Check if it's time for daily backup
    if [ "$CURRENT_TIME" == "$DAILY_BACKUP_TIME" ]; then
        log_message "Performing daily backup..."
        TIMESTAMP=$(date +%Y%m%d)
        tar -czf $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-validator/node data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
        log_message "Daily backup completed: $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz"
        
        # Keep only the last 7 daily backups
        ls -t $BACKUP_DIR/daily/blockchain-data-*.tar.gz | tail -n +8 | xargs -r rm
    fi
    
    # Check if it's time for weekly backup
    if [ "$CURRENT_DAY" == "$WEEKLY_BACKUP_DAY" ] && [ "$CURRENT_TIME" == "$WEEKLY_BACKUP_TIME" ]; then
        log_message "Performing weekly backup..."
        TIMESTAMP=$(date +%Y%m%d)
        tar -czf $BACKUP_DIR/weekly/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-validator/node data
        log_message "Weekly backup completed: $BACKUP_DIR/weekly/blockchain-data-$TIMESTAMP.tar.gz"
        
        # Keep only the last 4 weekly backups
        ls -t $BACKUP_DIR/weekly/blockchain-data-*.tar.gz | tail -n +5 | xargs -r rm
    fi
}

check_disk_space() {
    # Check available disk space
    AVAILABLE_SPACE=$(df -h / | awk 'NR==2 {print $4}')
    AVAILABLE_SPACE_MB=$(df / | awk 'NR==2 {print $4}')
    
    log_message "Available disk space: $AVAILABLE_SPACE"
    
    # If less than 5GB available, send warning
    if [ $AVAILABLE_SPACE_MB -lt 5000000 ]; then
        log_message "WARNING: Low disk space! Only $AVAILABLE_SPACE left."
        
        # Clean up old logs if space is low
        if [ $AVAILABLE_SPACE_MB -lt 2000000 ]; then
            log_message "Cleaning up old logs to free space..."
            find /var/log -name "*.gz" -type f -mtime +7 -delete
            find /var/log -name "*.log.*" -type f -mtime +7 -delete
            journalctl --vacuum-time=7d
        fi
    fi
}

# Main loop
log_message "Starting blockchain monitor..."

while true; do
    check_node_health
    perform_daily_backup
    check_disk_space
    sleep 60  # Check every minute
done
EOF

chmod +x ~/studio-validator/node/scripts/monitor_blockchain.sh
```

## 11. Create Systemd Service Files

Create the systemd service files:

```bash
cat > /etc/systemd/system/geth-studio-validator.service << 'EOF'
[Unit]
Description=Studio Blockchain Validator Node
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/bin/bash ~/studio-validator/node/scripts/start.sh
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

cat > /etc/systemd/system/blockchain-monitor-validator.service << 'EOF'
[Unit]
Description=Studio Blockchain Validator Monitoring Service
After=geth-studio-validator.service
Wants=geth-studio-validator.service

[Service]
Type=simple
User=root
ExecStart=/bin/bash ~/studio-validator/node/scripts/monitor_blockchain.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
SyslogIdentifier=blockchain-monitor-validator

# Hardening measures
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
ProtectHome=false

[Install]
WantedBy=multi-user.target
EOF
```

## 12. Initialize and Start the Validator Node

Run the following commands to initialize and start the validator node:

```bash
# Initialize the blockchain
cd ~/studio-validator/node/scripts
./init.sh

# Enable and start the services
systemctl daemon-reload
systemctl enable geth-studio-validator.service
systemctl enable blockchain-monitor-validator.service
systemctl start geth-studio-validator
systemctl start blockchain-monitor-validator
```

## 13. Verify the Deployment

Check the status of the services:

```bash
systemctl status geth-studio-validator
systemctl status blockchain-monitor-validator
```

Check the blockchain logs:

```bash
journalctl -u geth-studio-validator -f
```

## 14. Add This Node as a Validator

After the node is set up and running, you need to add it as a validator to the network. To do this, you need to:

1. Get the validator address from this node:
   ```bash
   cat ~/studio-validator/node/address.txt
   ```

2. Contact the Studio Blockchain team at office@studio-blockchain.com with your validator address to be added to the network.

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
