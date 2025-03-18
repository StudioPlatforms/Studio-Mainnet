#!/bin/bash

# Blockchain Mining Monitor Script
# This script checks if mining is active and restarts it if needed
# It also performs regular backups and monitors system health

LOG_FILE="/var/log/blockchain_monitor.log"
BACKUP_DIR=~/studio-mainnet/backups
DAILY_BACKUP_TIME="02:00"  # 2 AM
WEEKLY_BACKUP_DAY="Sunday"
WEEKLY_BACKUP_TIME="03:00"  # 3 AM on Sunday

# Create backup directories
mkdir -p $BACKUP_DIR/daily
mkdir -p $BACKUP_DIR/weekly

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_and_restart_mining() {
    log_message "Checking mining status..."
    
    # Check if mining is active
    MINING_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' \
        http://localhost:8545 | grep -o 'true\|false')
    
    if [ "$MINING_STATUS" == "false" ] || [ -z "$MINING_STATUS" ]; then
        log_message "Mining is not active. Restarting..."
        
        # Set etherbase address
        VALIDATOR_ADDRESS=$(cat ~/studio-mainnet/node/address.txt)
        curl -s -X POST -H "Content-Type: application/json" \
            --data "{\"jsonrpc\":\"2.0\",\"method\":\"miner_setEtherbase\",\"params\":[\"$VALIDATOR_ADDRESS\"],\"id\":1}" \
            http://localhost:8545 > /dev/null
        
        # Start mining
        curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"miner_start","params":[],"id":1}' \
            http://localhost:8545 > /dev/null
        
        log_message "Mining restarted."
    else
        log_message "Mining is active."
    fi
}

check_node_health() {
    log_message "Checking node health..."
    
    # Check if geth is running
    if ! pgrep -f "geth --datadir" > /dev/null; then
        log_message "Geth process not found. Restarting service..."
        systemctl restart geth-studio-mainnet
        log_message "Service restart initiated."
        return
    fi
    
    # Check if RPC is responsive
    if ! curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
        http://localhost:8545 | grep -q "240241"; then
        log_message "RPC endpoint not responsive or wrong network. Restarting service..."
        systemctl restart geth-studio-mainnet
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
        tar -czf $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-mainnet/node data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
        log_message "Daily backup completed: $BACKUP_DIR/daily/blockchain-data-$TIMESTAMP.tar.gz"
        
        # Keep only the last 7 daily backups
        ls -t $BACKUP_DIR/daily/blockchain-data-*.tar.gz | tail -n +8 | xargs -r rm
    fi
    
    # Check if it's time for weekly backup
    if [ "$CURRENT_DAY" == "$WEEKLY_BACKUP_DAY" ] && [ "$CURRENT_TIME" == "$WEEKLY_BACKUP_TIME" ]; then
        log_message "Performing weekly backup..."
        TIMESTAMP=$(date +%Y%m%d)
        tar -czf $BACKUP_DIR/weekly/blockchain-data-$TIMESTAMP.tar.gz -C ~/studio-mainnet/node data
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
    check_and_restart_mining
    perform_daily_backup
    check_disk_space
    sleep 60  # Check every minute
done
