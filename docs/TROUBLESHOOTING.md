# Troubleshooting Guide for Studio Blockchain Nodes

This guide provides solutions for common issues you might encounter when running a Studio Blockchain validator node.

## Table of Contents

1. [Node Won't Start](#node-wont-start)
2. [Mining Issues](#mining-issues)
3. [Peer Connection Problems](#peer-connection-problems)
4. [Syncing Issues](#syncing-issues)
5. [RPC API Problems](#rpc-api-problems)
6. [Monitoring System Issues](#monitoring-system-issues)
7. [Performance Problems](#performance-problems)
8. [Common Error Messages](#common-error-messages)

## Node Won't Start

### Issue: Geth service fails to start

**Symptoms:**
- `systemctl status geth-studio` shows "Failed" status
- Error in logs: "Fatal: Error starting protocol stack"

**Solutions:**

1. Check if the data directory exists and has correct permissions:
   ```bash
   ls -la ~/studio-mainnet/node/data
   sudo chown -R $(whoami):$(whoami) ~/studio-mainnet/node/data
   ```

2. Check if the genesis block is initialized:
   ```bash
   geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json
   ```

3. Check if another instance of geth is already running:
   ```bash
   ps aux | grep geth
   ```

4. Check for port conflicts:
   ```bash
   netstat -tulpn | grep 30303
   netstat -tulpn | grep 8545
   ```

5. Check the systemd logs for more details:
   ```bash
   journalctl -u geth-studio -n 100
   ```

### Issue: Permission denied errors

**Symptoms:**
- Error in logs: "Permission denied"

**Solutions:**

1. Check file permissions:
   ```bash
   chmod +x ~/studio-mainnet/node/scripts/start.sh
   ```

2. Check directory permissions:
   ```bash
   chmod 755 ~/studio-mainnet/node/data
   ```

3. Run the service as the correct user:
   ```bash
   sudo nano /etc/systemd/system/geth-studio.service
   # Update the User= line to the correct user
   sudo systemctl daemon-reload
   sudo systemctl restart geth-studio
   ```

## Mining Issues

### Issue: Mining not starting

**Symptoms:**
- `eth.mining` returns false
- No new blocks are being produced

**Solutions:**

1. Check if your account is unlocked:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > personal.listWallets
   ```

2. Check if your account is set as etherbase:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > eth.coinbase
   ```

3. Manually start mining:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > miner.start()
   ```

4. Check for errors in the logs:
   ```bash
   journalctl -u geth-studio -n 100 | grep -i error
   ```

### Issue: Mining starts but stops after a while

**Symptoms:**
- Mining stops periodically
- Monitoring script keeps restarting mining

**Solutions:**

1. Check system resources:
   ```bash
   top
   free -h
   df -h
   ```

2. Check for overheating:
   ```bash
   sensors
   ```

3. Increase the check interval in the monitoring script:
   ```bash
   nano ~/enhanced_monitor_blockchain.sh
   # Update CHECK_INTERVAL to a higher value
   ```

## Peer Connection Problems

### Issue: No peers connecting

**Symptoms:**
- `net.peerCount` returns 0
- "No peers connected" alerts

**Solutions:**

1. Check if your firewall allows connections on port 30303:
   ```bash
   sudo ufw status
   sudo ufw allow 30303/tcp
   sudo ufw allow 30303/udp
   ```

2. Check if your node is reachable from the internet:
   ```bash
   curl https://ifconfig.me
   # Use this IP to check port 30303
   nc -vz YOUR_PUBLIC_IP 30303
   ```

3. Check if static nodes are configured correctly:
   ```bash
   cat ~/studio-mainnet/node/data/geth/static-nodes.json
   ```

4. Manually add a peer:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > admin.addPeer("enode://8a04c60d9406597b571b6b2405dd2455a20bccc00eb881e4af36e9b278ba3ae4bd0a0dfbe213fb98a5d138143efba4c258994e79cf96225fa26e12bde6d3ecb6@173.249.16.253:30303")
   ```

5. Check for network issues:
   ```bash
   ping 173.249.16.253
   traceroute 173.249.16.253
   ```

### Issue: Peers connect but disconnect immediately

**Symptoms:**
- Peers connect briefly but then disconnect
- Logs show "Removing p2p peer" messages

**Solutions:**

1. Check if you're using the correct network ID:
   ```bash
   grep -i networkid ~/studio-mainnet/node/scripts/start.sh
   ```

2. Check if you're using the correct genesis block:
   ```bash
   geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json
   ```

3. Check the logs for specific disconnect reasons:
   ```bash
   journalctl -u geth-studio -n 100 | grep -i "disconnect\|removing peer"
   ```

## Syncing Issues

### Issue: Node not syncing

**Symptoms:**
- `eth.syncing` returns false but you're not at the latest block
- Block number doesn't increase

**Solutions:**

1. Check if you have peers:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > net.peerCount
   ```

2. Check your current block number:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > eth.blockNumber
   ```

3. Try changing the sync mode:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Change --syncmode to "full" or "snap"
   ```

4. Restart the node:
   ```bash
   sudo systemctl restart geth-studio
   ```

### Issue: Syncing is very slow

**Symptoms:**
- Syncing progresses but very slowly

**Solutions:**

1. Check your internet connection:
   ```bash
   speedtest-cli
   ```

2. Check system resources:
   ```bash
   top
   free -h
   df -h
   ```

3. Try increasing the cache:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Add --cache 4096 (or higher, depending on your RAM)
   ```

4. Try connecting to more peers:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Add --maxpeers 50
   ```

## RPC API Problems

### Issue: RPC API not accessible

**Symptoms:**
- Cannot connect to the RPC API
- curl http://localhost:8545 fails

**Solutions:**

1. Check if the HTTP-RPC server is enabled:
   ```bash
   grep -i http ~/studio-mainnet/node/scripts/start.sh
   ```

2. Check if the correct APIs are enabled:
   ```bash
   grep -i "http.api" ~/studio-mainnet/node/scripts/start.sh
   ```

3. Check if the RPC server is listening on the correct address:
   ```bash
   grep -i "http.addr" ~/studio-mainnet/node/scripts/start.sh
   ```

4. Check if the RPC server is running:
   ```bash
   netstat -tulpn | grep 8545
   ```

### Issue: RPC API returns errors

**Symptoms:**
- RPC calls return errors
- "Method not found" errors

**Solutions:**

1. Check if the required API modules are enabled:
   ```bash
   grep -i "http.api" ~/studio-mainnet/node/scripts/start.sh
   ```

2. Check the format of your RPC calls:
   ```bash
   curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
   ```

3. Check the logs for specific errors:
   ```bash
   journalctl -u geth-studio -n 100 | grep -i "api\|rpc\|http"
   ```

## Monitoring System Issues

### Issue: Monitoring service won't start

**Symptoms:**
- `systemctl status blockchain-monitor` shows "Failed" status

**Solutions:**

1. Check if the script exists and has correct permissions:
   ```bash
   ls -la ~/enhanced_monitor_blockchain.sh
   chmod +x ~/enhanced_monitor_blockchain.sh
   ```

2. Check the systemd logs:
   ```bash
   journalctl -u blockchain-monitor -n 100
   ```

3. Check if the log file exists and has correct permissions:
   ```bash
   touch /var/log/blockchain_monitor.log
   chmod 644 /var/log/blockchain_monitor.log
   ```

### Issue: Email alerts not being sent

**Symptoms:**
- No email alerts received
- "Warning: Could not send email" in logs

**Solutions:**

1. Check if mailutils is installed:
   ```bash
   apt-get install -y mailutils
   ```

2. Check if Postfix is configured correctly:
   ```bash
   cat /etc/postfix/main.cf
   ```

3. Check if the SMTP credentials are correct:
   ```bash
   cat /etc/postfix/sasl_passwd
   ```

4. Test the email configuration:
   ```bash
   echo "Test email" | mail -s "Test" your-email@example.com
   ```

5. Check the mail logs:
   ```bash
   tail -f /var/log/mail.log
   ```

## Performance Problems

### Issue: High CPU usage

**Symptoms:**
- CPU usage consistently high
- System becomes unresponsive

**Solutions:**

1. Check which processes are using CPU:
   ```bash
   top
   ```

2. Check if you're mining with too many threads:
   ```bash
   geth attach ~/studio-mainnet/node/data/geth.ipc
   > miner.getThreads()
   > miner.setThreads(2)  # Adjust based on your CPU cores
   ```

3. Reduce the verbosity level:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Change --verbosity to a lower value (1-3)
   ```

### Issue: High memory usage

**Symptoms:**
- Memory usage consistently high
- System starts swapping

**Solutions:**

1. Check memory usage:
   ```bash
   free -h
   ```

2. Reduce the cache size:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Add or adjust --cache to a lower value
   ```

3. Disable unnecessary APIs:
   ```bash
   # Edit the start script
   nano ~/studio-mainnet/node/scripts/start.sh
   # Remove unnecessary APIs from --http.api and --ws.api
   ```

### Issue: Disk space filling up

**Symptoms:**
- Disk space running low
- `df -h` shows high usage

**Solutions:**

1. Check which directories are using the most space:
   ```bash
   du -h --max-depth=1 ~/studio-mainnet
   ```

2. Clean up old log files:
   ```bash
   find /var/log -name "*.gz" -delete
   ```

3. Consider pruning the blockchain data (this will require resyncing):
   ```bash
   sudo systemctl stop geth-studio
   rm -rf ~/studio-mainnet/node/data/geth/chaindata
   rm -rf ~/studio-mainnet/node/data/geth/lightchaindata
   geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json
   sudo systemctl start geth-studio
   ```

## Common Error Messages

### "Fatal: Error starting protocol stack"

This usually indicates a problem with the node's configuration or data directory.

**Solutions:**

1. Check if the data directory exists and has correct permissions
2. Check if another instance of geth is already running
3. Check for port conflicts
4. Try initializing the genesis block again

### "Failed to unlock account (no key)"

This indicates that the account specified in the start script doesn't exist or can't be found.

**Solutions:**

1. Check if the account exists:
   ```bash
   geth --datadir ~/studio-mainnet/node/data account list
   ```

2. Check if the account address in the start script matches the actual account
3. Check if the keystore file exists in `~/studio-mainnet/node/data/keystore/`

### "Wrong password"

This indicates that the password provided in the password file is incorrect.

**Solutions:**

1. Check if the password file contains the correct password
2. Create a new account with a known password if necessary

### "Genesis block mismatch"

This indicates that your node was initialized with a different genesis block than the network.

**Solutions:**

1. Check if you're using the correct genesis file
2. Reinitialize the blockchain with the correct genesis file:
   ```bash
   sudo systemctl stop geth-studio
   rm -rf ~/studio-mainnet/node/data/geth/chaindata
   rm -rf ~/studio-mainnet/node/data/geth/lightchaindata
   geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json
   sudo systemctl start geth-studio
   ```

### "Network ID mismatch"

This indicates that your node is using a different network ID than the peers it's trying to connect to.

**Solutions:**

1. Check if you're using the correct network ID (240241 for Studio Blockchain)
2. Update the network ID in the start script if necessary
