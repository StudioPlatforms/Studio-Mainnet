# Studio Blockchain Validator Monitoring Guide

This guide provides instructions for monitoring your Studio Blockchain validator node to ensure optimal performance and detect issues early.

## Table of Contents

1. [Built-in Monitoring](#built-in-monitoring)
2. [Health Check Script](#health-check-script)
3. [Prometheus and Grafana Setup](#prometheus-and-grafana-setup)
4. [Alert Configuration](#alert-configuration)
5. [Log Monitoring](#log-monitoring)
6. [Performance Monitoring](#performance-monitoring)
7. [Network Monitoring](#network-monitoring)
8. [Consensus Monitoring](#consensus-monitoring)
9. [Backup Monitoring](#backup-monitoring)
10. [Advanced Monitoring Techniques](#advanced-monitoring-techniques)

## Built-in Monitoring

The validator setup includes a built-in monitoring system that checks the health of your node and sends notifications if issues are detected.

### Monitoring Service

The monitoring service runs as a systemd service and executes the health check script every minute. To check the status of the monitoring service:

```bash
# For user-level service
systemctl --user status studio-validator-monitor

# For system-level service
sudo systemctl status blockchain-monitor-validator
```

To view the monitoring logs:

```bash
# For user-level service
journalctl --user -u studio-validator-monitor -f

# For system-level service
sudo journalctl -u blockchain-monitor-validator -f
```

## Health Check Script

The health check script performs various checks on your validator node and sends notifications if issues are detected. The script is located at `~/studio-validator/health-check.sh`.

### What the Script Checks

1. **Node Status**: Checks if the geth process is running.
2. **Block Production**: Checks if blocks are being produced.
3. **Peer Connectivity**: Checks if the node is connected to peers.
4. **Validator Status**: Checks if the validator is in the signers list.
5. **Disk Space**: Checks if there's enough disk space available.
6. **Ghost State Issues**: Checks for potential ghost state issues.

### Configuring Notifications

The health check script can send notifications via email and Discord. To configure notifications, edit the script and set the following variables:

```bash
# Open the health check script
nano ~/studio-validator/health-check.sh

# Set the email address and Discord webhook
EMAIL="your-email@example.com"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/your-webhook-url"
```

### Running the Script Manually

You can run the health check script manually to check the health of your node:

```bash
~/studio-validator/health-check.sh
```

## Prometheus and Grafana Setup

For more advanced monitoring, you can set up Prometheus and Grafana to collect and visualize metrics from your validator node.

### Installing Prometheus

```bash
# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz

# Extract the archive
tar -xzf prometheus-2.45.0.linux-amd64.tar.gz
cd prometheus-2.45.0.linux-amd64

# Create a configuration file
cat > prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'geth'
    static_configs:
      - targets: ['localhost:6060']
        labels:
          instance: 'validator'

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'validator'
EOF

# Start Prometheus
./prometheus --config.file=prometheus.yml
```

### Installing Node Exporter

```bash
# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz

# Extract the archive
tar -xzf node_exporter-1.6.0.linux-amd64.tar.gz
cd node_exporter-1.6.0.linux-amd64

# Start Node Exporter
./node_exporter
```

### Installing Grafana

```bash
# Add Grafana APT repository
sudo apt-get install -y apt-transport-https software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update

# Install Grafana
sudo apt-get install -y grafana

# Start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### Configuring Grafana

1. Open Grafana in your browser: http://localhost:3000 (default credentials: admin/admin)
2. Add Prometheus as a data source:
   - URL: http://localhost:9090
   - Access: Server
3. Import the Ethereum Node dashboard (ID: 14053) or create your own.

## Alert Configuration

You can configure alerts in Grafana to notify you when certain conditions are met.

### Creating an Alert

1. Open the dashboard in Grafana.
2. Click on the panel you want to create an alert for.
3. Click on the "Edit" button.
4. Go to the "Alert" tab.
5. Click on "Create Alert".
6. Configure the alert conditions.
7. Add notification channels (email, Slack, etc.).
8. Save the alert.

### Common Alert Conditions

- **Node Down**: Alert when the node is not responding.
- **No Blocks Produced**: Alert when no blocks have been produced for a certain period.
- **Low Disk Space**: Alert when disk space is running low.
- **High CPU/Memory Usage**: Alert when CPU or memory usage is high.
- **No Peers**: Alert when the node has no peers.
- **Not in Signers List**: Alert when the validator is not in the signers list.

## Log Monitoring

Monitoring the logs of your validator node can help you detect issues early.

### Geth Logs

```bash
# For user-level service
journalctl --user -u studio-validator -f

# For system-level service
sudo journalctl -u geth-studio-validator -f
```

### Filtering Logs

You can filter the logs to show only specific messages:

```bash
# Show only error messages
journalctl --user -u studio-validator | grep -i error

# Show only warning messages
journalctl --user -u studio-validator | grep -i warn
```

### Log Rotation

To prevent logs from filling up your disk, you can configure log rotation:

```bash
sudo nano /etc/logrotate.d/geth

# Add the following configuration
/var/log/geth/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 geth geth
}
```

## Performance Monitoring

Monitoring the performance of your validator node can help you detect issues early.

### CPU Usage

```bash
# Show CPU usage
top -c | grep geth
```

### Memory Usage

```bash
# Show memory usage
free -h
```

### Disk Usage

```bash
# Show disk usage
df -h
```

### Network Usage

```bash
# Show network usage
iftop
```

## Network Monitoring

Monitoring the network connectivity of your validator node can help you detect issues early.

### Peer Count

```bash
# Show peer count
geth attach ~/studio-validator/node/data/geth.ipc --exec 'net.peerCount'
```

### Peer List

```bash
# Show peer list
geth attach ~/studio-validator/node/data/geth.ipc --exec 'admin.peers'
```

### Network ID

```bash
# Show network ID
geth attach ~/studio-validator/node/data/geth.ipc --exec 'net.version'
```

## Consensus Monitoring

Monitoring the consensus status of your validator node can help you detect issues early.

### Signers List

```bash
# Show signers list
geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners()'
```

### Validator Status

```bash
# Check if your validator is in the signers list
geth attach ~/studio-validator/node/data/geth.ipc --exec 'clique.getSigners().includes(eth.coinbase)'
```

### Block Production

```bash
# Show the number of blocks produced by your validator
geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.getBlock(eth.blockNumber).miner === eth.coinbase'
```

### Time Since Last Block

```bash
# Show the time since the last block
geth attach ~/studio-validator/node/data/geth.ipc --exec 'Math.floor(Date.now()/1000) - eth.getBlock(eth.blockNumber).timestamp'
```

## Backup Monitoring

Monitoring the backup status of your validator node can help you ensure that you have recent backups in case of issues.

### Backup Status

```bash
# Show the status of the last backup
ls -la ~/studio-validator/backups/daily
```

### Backup Size

```bash
# Show the size of the backups
du -sh ~/studio-validator/backups/daily
```

### Backup Integrity

```bash
# Check the integrity of the last backup
tar -tzf ~/studio-validator/backups/daily/$(ls -t ~/studio-validator/backups/daily | head -1)
```

## Advanced Monitoring Techniques

### Custom Metrics

You can create custom metrics to monitor specific aspects of your validator node. For example, you can create a metric to monitor the number of blocks produced by your validator:

```bash
# Create a custom metric
geth attach ~/studio-validator/node/data/geth.ipc --exec 'var blockCount = 0; for (var i = 0; i < 100; i++) { if (eth.getBlock(eth.blockNumber - i).miner === eth.coinbase) blockCount++; } blockCount'
```

### Automated Monitoring

You can create a script to automate the monitoring of your validator node. For example, you can create a script that checks the health of your node every minute and sends notifications if issues are detected:

```bash
#!/bin/bash

# Check if the node is running
if ! pgrep -f "geth.*--datadir" > /dev/null; then
    echo "Node is not running"
    exit 1
fi

# Check if the node is connected to peers
PEER_COUNT=$(geth attach ~/studio-validator/node/data/geth.ipc --exec 'net.peerCount' 2>/dev/null)
if [ "$PEER_COUNT" -eq 0 ]; then
    echo "Node has no peers"
    exit 1
fi

# Check if the node is producing blocks
BLOCK_NUMBER=$(geth attach ~/studio-validator/node/data/geth.ipc --exec 'eth.blockNumber' 2>/dev/null)
LAST_BLOCK_NUMBER=$(cat ~/studio-validator/last_block_number 2>/dev/null || echo 0)
if [ "$BLOCK_NUMBER" -eq "$LAST_BLOCK_NUMBER" ]; then
    echo "Node is not producing blocks"
    exit 1
fi
echo "$BLOCK_NUMBER" > ~/studio-validator/last_block_number

# Check if the validator is in the signers list
VALIDATOR_ADDRESS=$(cat ~/studio-validator/node/data/validator-address.txt)
IS_VALIDATOR=$(geth attach ~/studio-validator/node/data/geth.ipc --exec "clique.getSigners().includes('$VALIDATOR_ADDRESS')" 2>/dev/null)
if [ "$IS_VALIDATOR" != "true" ]; then
    echo "Validator is not in the signers list"
    exit 1
fi

# All checks passed
echo "Node is healthy"
exit 0
```

### External Monitoring Services

You can use external monitoring services to monitor your validator node. For example, you can use services like Uptime Robot, Pingdom, or StatusCake to monitor the availability of your node's RPC endpoint.

## Conclusion

Monitoring your validator node is essential to ensure optimal performance and detect issues early. By following the guidelines in this guide, you can set up a comprehensive monitoring system for your validator node.

For more information, please contact the Studio Blockchain team at office@studio-blockchain.com.
