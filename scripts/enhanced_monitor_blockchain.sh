#!/bin/bash

# Enhanced Blockchain Mining Monitor Script
# This script checks if mining is active and restarts it if needed
# Created: March 13, 2025
# Modified: March 14, 2025 - Added peer alert throttling and improved block progress detection

LOG_FILE="/var/log/blockchain_monitor.log"
CHECK_INTERVAL=30  # Check every 30 seconds
ALERT_EMAIL="developer@example.com"  # Alert email address
CONSECUTIVE_FAILURES_THRESHOLD=3
PEER_ALERT_INTERVAL=3600  # Send peer alerts at most once per hour (in seconds)

# Initialize counters and variables
consecutive_failures=0
consecutive_no_peers=0
last_peer_alert_time=0
last_block_number=""
last_block_check_time=0
BLOCK_PROGRESS_INTERVAL=300  # Check block progress every 5 minutes (in seconds)

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local subject="$1"
    local message="$2"
    
    log_message "ALERT: $subject - $message"
    
    # Send email alert if mail command is available
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    fi
    
    # Log to system journal
    logger -p daemon.alert "BLOCKCHAIN ALERT: $subject - $message"
}

check_node_running() {
    # Check if the node is responding to RPC calls
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' \
        http://localhost:8545)
    
    if [ -z "$response" ]; then
        return 1  # Node is not responding
    else
        return 0  # Node is responding
    fi
}

check_node_syncing() {
    # Check if the node is syncing
    local response=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545)
    
    if [[ "$response" == *"currentBlock"* ]]; then
        return 0  # Node is syncing
    else
        return 1  # Node is not syncing
    fi
}

check_block_progress() {
    # Get current block number
    local current_block=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | grep -o '0x[a-f0-9]*')
    
    # Get current time
    local current_time=$(date +%s)
    
    # If we have a previous block number and enough time has passed
    if [ ! -z "$last_block_number" ] && [ ! -z "$current_block" ] && \
       [ $((current_time - last_block_check_time)) -ge $BLOCK_PROGRESS_INTERVAL ]; then
        
        # Convert hex to decimal for comparison
        local last_block_dec=$((16#${last_block_number:2}))
        local current_block_dec=$((16#${current_block:2}))
        
        log_message "Checking block progress: Last block: $last_block_number ($last_block_dec), Current block: $current_block ($current_block_dec)"
        
        if [ $current_block_dec -gt $last_block_dec ]; then
            log_message "Block number is increasing - node is making progress"
            return 0  # Block number is increasing
        else
            log_message "Block number is not increasing - node may be stuck"
            return 1  # Block number is not increasing
        fi
    fi
    
    # Update last block number and check time
    if [ ! -z "$current_block" ]; then
        last_block_number=$current_block
        last_block_check_time=$current_time
    fi
    
    # If we don't have enough data yet, assume progress is happening
    return 0
}

restart_node() {
    log_message "Attempting to restart the blockchain node..."
    
    # First try to restart using systemd
    if systemctl is-active --quiet geth-studio; then
        log_message "Restarting geth-studio service..."
        systemctl restart geth-studio
    else
        log_message "Starting geth-studio service..."
        systemctl start geth-studio
    fi
    
    # Wait for the service to start
    sleep 10
    
    # Check if the service is running
    if systemctl is-active --quiet geth-studio; then
        log_message "Geth service started successfully."
        send_alert "Geth Service Restarted" "The geth-studio service has been restarted."
        return 0
    else
        log_message "Failed to start geth service via systemd!"
        
        # Try to start the node directly as a fallback
        log_message "Attempting to start node directly..."
        nohup /bin/bash $HOME/studio-mainnet/node/scripts/start.sh > $HOME/studio-mainnet/node/direct_start.log 2>&1 &
        
        # Wait for the node to start
        sleep 15
        
        # Check if the node is responding
        if check_node_running; then
            log_message "Node started successfully via direct method."
            send_alert "Node Started Directly" "The blockchain node was started directly after systemd service failed."
            return 0
        else
            log_message "CRITICAL: Failed to start node by any method!"
            send_alert "CRITICAL: Node Start Failure" "The blockchain node could not be started by any method. IMMEDIATE MANUAL INTERVENTION REQUIRED."
            return 1
        fi
    fi
}

check_and_restart_mining() {
    log_message "Checking if node is running..."
    
    # First check if the node is running at all
    if ! check_node_running; then
        log_message "Node is not responding! Attempting to restart..."
        restart_node
        
        # If restart failed, return early
        if ! check_node_running; then
            return
        fi
    fi
    
    log_message "Checking mining status..."
    
    # Check if mining is active
    MINING_STATUS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_mining","params":[],"id":1}' \
        http://localhost:8545 | grep -o 'true\|false')
    
    if [ "$MINING_STATUS" == "false" ] || [ -z "$MINING_STATUS" ]; then
        log_message "Mining is not active. Restarting..."
        consecutive_failures=$((consecutive_failures + 1))
        
        # Set etherbase address
        curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"miner_setEtherbase","params":["0x0000000000000000000000000000000000000000"],"id":1}' \
            http://localhost:8545 > /dev/null
        
        # Start mining
        curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"miner_start","params":[],"id":1}' \
            http://localhost:8545 > /dev/null
        
        log_message "Mining restarted. Consecutive failures: $consecutive_failures"
        
        # Check if we need to send an alert
        if [ $consecutive_failures -ge $CONSECUTIVE_FAILURES_THRESHOLD ]; then
            send_alert "Mining Stopped Repeatedly" "Mining has stopped $consecutive_failures times in a row. This may indicate a serious issue."
            
            # If mining keeps failing, try to restart the entire node
            if [ $consecutive_failures -ge $((CONSECUTIVE_FAILURES_THRESHOLD * 2)) ]; then
                log_message "Too many consecutive mining failures. Restarting entire node..."
                restart_node
                consecutive_failures=0
            fi
        fi
    else
        log_message "Mining is active."
        consecutive_failures=0
    fi
    
    # Get current block number
    BLOCK_NUMBER=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | grep -o '0x[a-f0-9]*')
    
    log_message "Current block number: $BLOCK_NUMBER"
    
    # First check if node is syncing or making block progress
    if check_node_syncing || check_block_progress; then
        log_message "Node is syncing or making block progress - this indicates connectivity is working"
        consecutive_no_peers=0  # Reset counter since connectivity is working
    else
        # Only check peer count if not syncing and not making block progress
        PEER_COUNT=$(curl -s -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
            http://localhost:8545 | grep -o '0x[a-f0-9]*')
        
        # Convert hex to decimal
        if [ ! -z "$PEER_COUNT" ]; then
            PEER_COUNT_DEC=$((16#${PEER_COUNT:2}))
            log_message "Peer count: $PEER_COUNT_DEC"
            
            if [ $PEER_COUNT_DEC -eq 0 ]; then
                log_message "Warning: No peers connected and node is not making progress!"
                consecutive_no_peers=$((consecutive_no_peers + 1))
                
                # Only send alert if it's been more than PEER_ALERT_INTERVAL seconds since the last alert
                current_time=$(date +%s)
                time_since_last_alert=$((current_time - last_peer_alert_time))
                
                if [ $time_since_last_alert -ge $PEER_ALERT_INTERVAL ]; then
                    send_alert "No Network Connectivity" "The blockchain node has no peers connected and is not making progress for $consecutive_no_peers checks. This indicates a network issue."
                    last_peer_alert_time=$current_time
                else
                    log_message "Suppressing peer alert (sent one $time_since_last_alert seconds ago, threshold is $PEER_ALERT_INTERVAL seconds)"
                fi
            else
                # Reset counter if peers are connected
                consecutive_no_peers=0
            fi
        else
            log_message "Warning: Could not get peer count!"
        fi
    fi
    
    # Check for malware (just in case)
    MALWARE_PROCESSES=$(ps aux | grep -E 'kdevtmpfsi|kinsing' | grep -v grep)
    
    if [ -n "$MALWARE_PROCESSES" ]; then
        log_message "WARNING: Malware processes detected! Running removal script..."
        bash $HOME/remove_crypto_malware.sh
        send_alert "Malware Detected" "Cryptocurrency mining malware detected and removal script executed."
    fi
}

# Main loop
log_message "Starting enhanced blockchain monitor..."
log_message "Monitoring interval: $CHECK_INTERVAL seconds"
log_message "Alert email: $ALERT_EMAIL"
log_message "Peer alert interval: $PEER_ALERT_INTERVAL seconds"
log_message "Block progress check interval: $BLOCK_PROGRESS_INTERVAL seconds"

while true; do
    check_and_restart_mining
    sleep $CHECK_INTERVAL
done
