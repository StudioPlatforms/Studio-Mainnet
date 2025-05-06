# Troubleshooting Guide

This document provides solutions for common issues you might encounter when running a Studio Blockchain validator node with Hyperledger Besu.

## Connection Issues

### Validator Not Connecting to Peers

**Symptoms:**
- `net_peerCount` returns `0x0` or a low number
- Logs show "Unable to find sync target" messages
- Validator is not producing blocks

**Solutions:**

1. **Check static-nodes.json:**
   ```bash
   cat /opt/besu/data/static-nodes.json
   ```
   Ensure it contains the correct enode URLs with the right node IDs and IP addresses.

2. **Verify firewall settings:**
   ```bash
   # For UFW
   ufw status
   
   # For iptables
   iptables -L
   ```
   Make sure port 30303 (TCP/UDP) is open.

3. **Check network connectivity:**
   ```bash
   # Test TCP connection to another validator
   nc -vz <validator_ip> 30303
   
   # Test UDP connection
   nc -vzu <validator_ip> 30303
   ```

4. **Restart the validator service:**
   ```bash
   systemctl restart besu-validator
   ```

5. **Check for correct node ID:**
   ```bash
   besu --node-private-key-file=/opt/besu/keys/nodekey public-key export --to=/tmp/nodeid.txt
   cat /tmp/nodeid.txt
   ```
   Verify that this node ID matches the one in the static-nodes.json file on other validators.

### Incorrect Node ID in static-nodes.json

**Symptoms:**
- Peers connect briefly but then disconnect
- Logs show "Disconnecting from peer" messages

**Solution:**

1. Get the correct node ID:
   ```bash
   besu --node-private-key-file=/opt/besu/keys/nodekey public-key export --to=/tmp/nodeid.txt
   cat /tmp/nodeid.txt
   ```

2. Update the static-nodes.json file on all validators with the correct enode URL:
   ```bash
   # Example enode URL format
   "enode://<node_id>@<ip_address>:30303"
   ```

3. Restart the validator service on all nodes:
   ```bash
   systemctl restart besu-validator
   ```

## Consensus Issues

### Validator Not Producing Blocks

**Symptoms:**
- Validator is connected to peers but not participating in block production
- Logs show no QBFT consensus messages

**Solutions:**

1. **Check if the validator is in the validator list:**
   ```bash
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' http://localhost:8545
   ```
   Verify that your validator's address is in the list.

2. **Check if the validator is using the correct private key:**
   ```bash
   besu --node-private-key-file=/opt/besu/keys/nodekey public-key export --to=/tmp/nodeid.txt
   cat /tmp/nodeid.txt
   ```
   The public key should correspond to an address in the validator list.

3. **Verify the genesis file:**
   ```bash
   cat /opt/besu/genesis.json
   ```
   Ensure it matches the network's genesis file.

4. **Check for clock synchronization:**
   ```bash
   timedatectl status
   ```
   Make sure your system clock is synchronized. Consider installing and configuring NTP:
   ```bash
   apt-get install -y ntp
   systemctl enable ntp
   systemctl start ntp
   ```

### Round Change Timeout

**Symptoms:**
- Logs show frequent "Round change timeout" messages
- Block production is slow or inconsistent

**Solutions:**

1. **Check network latency between validators:**
   ```bash
   ping <validator_ip>
   ```
   High latency can cause round change timeouts.

2. **Ensure all validators are properly connected:**
   ```bash
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545
   ```
   Each validator should be connected to all other validators.

3. **Check system resources:**
   ```bash
   top
   ```
   Ensure the system has sufficient CPU and memory resources.

## RPC Issues

### RPC Endpoint Not Responding

**Symptoms:**
- curl commands to the RPC endpoint fail
- Applications cannot connect to the blockchain

**Solutions:**

1. **Check if the validator service is running:**
   ```bash
   systemctl status besu-validator
   ```

2. **Verify RPC configuration:**
   ```bash
   grep rpc /etc/systemd/system/besu-validator.service
   ```
   Ensure the service is configured with `--rpc-http-enabled=true`.

3. **Check if the RPC port is open:**
   ```bash
   # For UFW
   ufw status | grep 8545
   
   # For iptables
   iptables -L | grep 8545
   
   # Test locally
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}' http://localhost:8545
   ```

4. **Restart the validator service:**
   ```bash
   systemctl restart besu-validator
   ```

### RPC Method Not Allowed

**Symptoms:**
- Error message: "Method not allowed"
- Specific RPC calls fail while others work

**Solution:**

1. Check the RPC API configuration in the service file:
   ```bash
   grep rpc-http-api /etc/systemd/system/besu-validator.service
   ```

2. Update the service file to include the required APIs:
   ```bash
   # Edit the service file
   nano /etc/systemd/system/besu-validator.service
   
   # Add or update the --rpc-http-api flag
   # Example: --rpc-http-api=ETH,NET,QBFT,DEBUG,ADMIN
   ```

3. Reload and restart the service:
   ```bash
   systemctl daemon-reload
   systemctl restart besu-validator
   ```

## System Issues

### Out of Memory

**Symptoms:**
- Validator service crashes
- Logs show "OutOfMemoryError" messages

**Solutions:**

1. **Check memory usage:**
   ```bash
   free -h
   ```

2. **Increase Java heap size:**
   ```bash
   # Edit the service file
   nano /etc/systemd/system/besu-validator.service
   
   # Add or update the Java options
   # Example: ExecStart=/usr/local/bin/besu -Xmx4g ...
   ```

3. **Add swap space if needed:**
   ```bash
   # Create a 4GB swap file
   dd if=/dev/zero of=/swapfile bs=1G count=4
   chmod 600 /swapfile
   mkswap /swapfile
   swapon /swapfile
   
   # Make it permanent
   echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
   ```

4. **Restart the validator service:**
   ```bash
   systemctl daemon-reload
   systemctl restart besu-validator
   ```

### Disk Space Issues

**Symptoms:**
- Validator service crashes
- Logs show disk space errors
- System reports low disk space

**Solutions:**

1. **Check disk usage:**
   ```bash
   df -h
   ```

2. **Check the size of the Besu data directory:**
   ```bash
   du -sh /opt/besu/data
   ```

3. **Prune the database (if necessary):**
   ```bash
   # Stop the validator service
   systemctl stop besu-validator
   
   # Backup the data directory
   tar -czf besu-data-backup.tar.gz /opt/besu/data
   
   # Remove the database
   rm -rf /opt/besu/data/database
   
   # Start the validator service
   systemctl start besu-validator
   ```
   Note: This will require the node to resync from scratch.

4. **Add more disk space:**
   - Resize the partition
   - Add a new disk and mount it
   - Use a cloud storage solution

## Upgrade Issues

### Failed Upgrade

**Symptoms:**
- Validator service fails to start after an upgrade
- Logs show compatibility errors

**Solutions:**

1. **Check the logs for specific errors:**
   ```bash
   journalctl -u besu-validator -n 100
   ```

2. **Verify the Besu version:**
   ```bash
   besu --version
   ```

3. **Rollback to the previous version:**
   ```bash
   # Download the previous version
   wget https://hyperledger.jfrog.io/artifactory/besu-binaries/besu/PREVIOUS_VERSION/besu-PREVIOUS_VERSION.tar.gz
   
   # Extract and install
   tar -xzf besu-PREVIOUS_VERSION.tar.gz
   cp -r besu-PREVIOUS_VERSION/bin/besu /usr/local/bin/
   
   # Restart the service
   systemctl restart besu-validator
   ```

4. **Check for data directory compatibility:**
   ```bash
   # If needed, restore from backup
   systemctl stop besu-validator
   rm -rf /opt/besu/data
   tar -xzf besu-data-backup.tar.gz -C /
   systemctl start besu-validator
   ```

## Genesis File Issues

### Genesis File Mismatch

**Symptoms:**
- Validator cannot sync with the network
- Logs show "Genesis block mismatch" or similar errors

**Solutions:**

1. **Verify the genesis file:**
   ```bash
   cat /opt/besu/genesis.json
   ```
   Compare with the correct genesis file from the repository.

2. **Replace the genesis file:**
   ```bash
   cp /path/to/correct/genesis.json /opt/besu/genesis.json
   ```

3. **Clear the database and restart:**
   ```bash
   systemctl stop besu-validator
   rm -rf /opt/besu/data/database
   systemctl start besu-validator
   ```

## Advanced Troubleshooting

### Enabling Debug Logs

To get more detailed logs for troubleshooting:

1. **Edit the service file:**
   ```bash
   nano /etc/systemd/system/besu-validator.service
   ```

2. **Add the log level option:**
   ```
   --logging=DEBUG
   ```

3. **Reload and restart the service:**
   ```bash
   systemctl daemon-reload
   systemctl restart besu-validator
   ```

4. **View the detailed logs:**
   ```bash
   journalctl -u besu-validator -f
   ```

### Checking Network Traffic

To analyze network traffic for troubleshooting:

1. **Install tcpdump:**
   ```bash
   apt-get install -y tcpdump
   ```

2. **Monitor P2P traffic:**
   ```bash
   tcpdump -i any port 30303 -nn
   ```

3. **Monitor RPC traffic:**
   ```bash
   tcpdump -i any port 8545 -nn
   ```

## Getting Help

If you've tried the solutions above and are still experiencing issues, please contact:

- Email: office@studio-blockchain.com

When reporting an issue, please include:
- Detailed description of the problem
- Relevant logs
- System information (OS, Java version, Besu version)
- Steps you've already taken to troubleshoot
