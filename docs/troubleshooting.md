# Studio Blockchain Validator Troubleshooting Guide

This guide provides solutions for common issues you might encounter when running a Studio Blockchain validator node.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Network Connectivity Issues](#network-connectivity-issues)
3. [Consensus Issues](#consensus-issues)
4. [Ghost State Issues](#ghost-state-issues)
5. [Performance Issues](#performance-issues)
6. [Backup and Recovery Issues](#backup-and-recovery-issues)
7. [Monitoring Issues](#monitoring-issues)
8. [Service Management Issues](#service-management-issues)

## Installation Issues

### Geth Installation Fails

**Symptoms:**
- Error messages during Geth installation
- Geth command not found after installation

**Solutions:**
1. Check if you have sufficient permissions:
   ```bash
   sudo cp geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/
   ```

2. Verify the downloaded file integrity:
   ```bash
   sha256sum geth-linux-amd64-1.13.14-2bd6bd01.tar.gz
   ```

3. Try installing Geth from the package manager:
   ```bash
   sudo add-apt-repository -y ppa:ethereum/ethereum
   sudo apt-get update
   sudo apt-get install ethereum
   ```

### Account Creation Fails

**Symptoms:**
- Error messages during account creation
- No keystore file created

**Solutions:**
1. Check if the data directory exists and has correct permissions:
   ```bash
   mkdir -p ~/studio-validator/node/data
   chmod 700 ~/studio-validator/node/data
   ```

2. Try creating the account manually:
   ```bash
   geth account new --datadir ~/studio-validator/node/data
   ```

3. Check for disk space issues:
   ```bash
   df -h
   ```

## Network Connectivity Issues

### Node Cannot Connect to Peers

**Symptoms:**
- Zero peers in the node status
- Node not syncing

**Solutions:**
1. Check if the firewall allows connections on port 30303:
   ```bash
   sudo ufw status
   sudo ufw allow 30303/tcp
   sudo ufw allow 30303/udp
   ```

2. Verify the static-nodes.json file:
   ```bash
   cat ~/studio-validator/node/data/geth/static-nodes.json
   ```

3. Check if the bootnode is reachable:
   ```bash
   ping 62.171.162.49
   nc -vz 62.171.162.49 30303
   ```

4. Manually add peers:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'admin.addPeer("enode://20b8ecf71c1929290c149d7de20408e8140984334e02a54830cf40ae8dcc1a168466949a04bc00847666d11879a9dc98594debdc9a8c20daa461bad47ad81023@62.171.162.49:30303")'
   ```

### Node Not Syncing

**Symptoms:**
- Node connected to peers but not syncing
- Block number not increasing

**Solutions:**
1. Check the sync status:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.syncing'
   ```

2. Check the current block number:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.blockNumber'
   ```

3. Restart the node:
   ```bash
   systemctl --user restart studio-validator
   ```

4. Try resetting the sync state:
   ```bash
   geth --datadir ~/studio-validator/node/data removedb
   geth --datadir ~/studio-validator/node/data init ~/studio-validator/node/genesis.json
   ```

## Consensus Issues

### Validator Not Mining Blocks

**Symptoms:**
- Node is synced but not producing blocks
- Not listed in the signers list

**Solutions:**
1. Check if the node is mining:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.mining'
   ```

2. Check if the validator address is correct:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.coinbase'
   ```

3. Check if the validator is in the signers list:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners()'
   ```

4. Contact the Studio Blockchain team to ensure your validator has been added to the network.

### Inconsistent Block Production

**Symptoms:**
- Blocks are produced irregularly
- Long gaps between blocks

**Solutions:**
1. Check the number of validators in the network:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners().length'
   ```

2. Check the time since the last block:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'Math.floor(Date.now()/1000) - eth.getBlock(eth.blockNumber).timestamp'
   ```

3. Check for time synchronization issues:
   ```bash
   timedatectl status
   ```

4. Install and configure NTP:
   ```bash
   sudo apt-get install -y ntp
   sudo systemctl enable ntp
   sudo systemctl start ntp
   ```

## Ghost State Issues

### Chain Stuck at a Specific Block

**Symptoms:**
- Block production stopped at a specific block
- No new blocks being produced

**Solutions:**
1. Check the current block number:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.blockNumber'
   ```

2. Check the signers list:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners()'
   ```

3. Check for multiple Clique snapshot files:
   ```bash
   find ~/studio-validator/node/data/geth/clique -name "*.snap" | wc -l
   ```

4. Check the Clique snapshot:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSnapshot()'
   ```

5. If the chain is stuck, contact the Studio Blockchain team immediately.

### Multiple Validators with Same Address

**Symptoms:**
- Inconsistent block production
- Validators appearing and disappearing from the signers list

**Solutions:**
1. Check if there are multiple validators with the same address:
   ```bash
   geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners()'
   ```

2. Ensure each validator has a unique address.

3. Check for duplicate entries in the static-nodes.json file:
   ```bash
   cat ~/studio-validator/node/data/geth/static-nodes.json
   ```

4. If you detect this issue, contact the Studio Blockchain team immediately.

## Performance Issues

### High CPU Usage

**Symptoms:**
- High CPU usage by the geth process
- System becoming unresponsive

**Solutions:**
1. Check the CPU usage:
   ```bash
   top -c | grep geth
   ```

2. Adjust the number of threads:
   ```bash
   # Add this to your start script
   --cache 1024 --cache.gc 20
   ```

3. Monitor the system resources:
   ```bash
   htop
   ```

### High Memory Usage

**Symptoms:**
- High memory usage by the geth process
- System becoming unresponsive

**Solutions:**
1. Check the memory usage:
   ```bash
   free -h
   ```

2. Adjust the cache size:
   ```bash
   # Add this to your start script
   --cache 512
   ```

3. Monitor the memory usage:
   ```bash
   watch -n 1 'free -h'
   ```

### Disk Space Issues

**Symptoms:**
- Running out of disk space
- Node crashes due to insufficient disk space

**Solutions:**
1. Check the disk usage:
   ```bash
   df -h
   ```

2. Check the size of the data directory:
   ```bash
   du -sh ~/studio-validator/node/data
   ```

3. Clean up old logs:
   ```bash
   find /var/log -name "*.gz" -type f -mtime +7 -delete
   journalctl --vacuum-time=7d
   ```

4. Prune the ancient database:
   ```bash
   geth --datadir ~/studio-validator/node/data snapshot prune-state
   ```

## Backup and Recovery Issues

### Backup Creation Fails

**Symptoms:**
- Error messages during backup creation
- Backup file not created

**Solutions:**
1. Check if there's enough disk space:
   ```bash
   df -h
   ```

2. Check if the backup directory exists:
   ```bash
   mkdir -p ~/studio-validator/backups/{daily,weekly}
   ```

3. Try creating a backup manually:
   ```bash
   tar -czf ~/studio-validator/backups/manual/blockchain-data-$(date +%Y%m%d-%H%M%S).tar.gz -C ~/studio-validator/node data --exclude data/geth/chaindata/ancient --exclude data/geth/lightchaindata/ancient
   ```

### Backup Restoration Fails

**Symptoms:**
- Error messages during backup restoration
- Node fails to start after restoration

**Solutions:**
1. Check the backup file integrity:
   ```bash
   tar -tzf backup-file.tar.gz
   ```

2. Ensure the node is stopped before restoration:
   ```bash
   systemctl --user stop studio-validator
   ```

3. Try restoring the backup manually:
   ```bash
   rm -rf ~/studio-validator/node/data
   mkdir -p ~/studio-validator/node/data
   tar -xzf backup-file.tar.gz -C ~/studio-validator/node
   ```

4. Initialize the blockchain again:
   ```bash
   geth --datadir ~/studio-validator/node/data init ~/studio-validator/node/genesis.json
   ```

## Monitoring Issues

### Monitoring Service Not Starting

**Symptoms:**
- Monitoring service fails to start
- No monitoring data available

**Solutions:**
1. Check the monitoring service status:
   ```bash
   systemctl --user status studio-validator-monitor
   ```

2. Check the monitoring service logs:
   ```bash
   journalctl --user -u studio-validator-monitor -n 100
   ```

3. Verify the health check script exists and is executable:
   ```bash
   ls -la ~/studio-validator/health-check.sh
   chmod +x ~/studio-validator/health-check.sh
   ```

### Health Check Script Fails

**Symptoms:**
- Error messages in the monitoring logs
- Health check script exits with non-zero status

**Solutions:**
1. Check if the geth IPC file exists:
   ```bash
   ls -la ~/studio-validator/node/data/geth.ipc
   ```

2. Check if the validator address file exists:
   ```bash
   cat ~/studio-validator/node/data/validator-address.txt
   ```

3. Try running the health check script manually:
   ```bash
   ~/studio-validator/health-check.sh
   ```

## Service Management Issues

### Service Fails to Start

**Symptoms:**
- Service fails to start
- Error messages in the service logs

**Solutions:**
1. Check the service status:
   ```bash
   systemctl --user status studio-validator
   ```

2. Check the service logs:
   ```bash
   journalctl --user -u studio-validator -n 100
   ```

3. Verify the start script exists and is executable:
   ```bash
   ls -la ~/studio-validator/node/scripts/start.sh
   chmod +x ~/studio-validator/node/scripts/start.sh
   ```

4. Try starting the node manually:
   ```bash
   ~/studio-validator/node/scripts/start.sh
   ```

### Service Crashes Frequently

**Symptoms:**
- Service restarts frequently
- Error messages in the service logs

**Solutions:**
1. Check the service logs for error messages:
   ```bash
   journalctl --user -u studio-validator -n 100
   ```

2. Check the system resources:
   ```bash
   top
   free -h
   df -h
   ```

3. Increase the service restart delay:
   ```bash
   # Edit the service file
   # Change RestartSec=30 to RestartSec=60
   systemctl --user daemon-reload
   ```

4. Check for file descriptor limits:
   ```bash
   ulimit -n
   # Add this to your service file
   LimitNOFILE=65536
   ```

## Additional Resources

If you encounter issues not covered in this guide, please contact the Studio Blockchain team at office@studio-blockchain.com.

For more information about Geth and Clique PoA, refer to the following resources:
- [Geth Documentation](https://geth.ethereum.org/docs/)
- [Clique PoA Consensus Protocol](https://eips.ethereum.org/EIPS/eip-225)
