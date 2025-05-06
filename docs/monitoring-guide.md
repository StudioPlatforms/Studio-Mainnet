# Monitoring Guide for Studio Blockchain Validators

This guide provides instructions for setting up monitoring for your Studio Blockchain validator node running Hyperledger Besu with QBFT consensus.

## Basic Monitoring

### System Status Checks

#### Checking Validator Service Status

To check if your validator service is running:

```bash
systemctl status besu-validator
```

This command shows:
- Whether the service is active (running) or inactive (stopped)
- Recent log entries
- Service uptime

#### Viewing Logs

To view the validator logs:

```bash
# View the most recent logs
journalctl -u besu-validator -n 100

# Follow logs in real-time
journalctl -u besu-validator -f

# View logs from a specific time
journalctl -u besu-validator --since "2025-05-06 10:00:00"

# View only error logs
journalctl -u besu-validator | grep ERROR
```

### Blockchain Status Checks

#### Checking Block Height

To check the current block number:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
```

The result is in hexadecimal format. To convert to decimal:

```bash
# Example: If the result is "0x1a4" (hexadecimal)
echo $((16#1a4))  # Outputs 420 (decimal)
```

#### Checking Peer Count

To check the number of connected peers:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545
```

For optimal performance, each validator should be connected to all other validators in the network.

#### Checking Validator Status

To check if your node is in the validator list:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' http://localhost:8545
```

#### Checking Sync Status

To check if your node is in sync with the network:

```bash
curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' http://localhost:8545
```

If the result is `false`, your node is in sync. If it returns an object with `startingBlock`, `currentBlock`, and `highestBlock`, your node is still syncing.

### System Resource Monitoring

#### CPU and Memory Usage

To check CPU and memory usage:

```bash
# Overall system status
top

# Memory usage
free -h

# CPU information
mpstat -P ALL
```

#### Disk Usage

To check disk usage:

```bash
# Overall disk usage
df -h

# Besu data directory size
du -sh /opt/besu/data
```

#### Network Usage

To check network usage:

```bash
# Install if not available
apt-get install -y iftop

# Monitor network traffic
iftop
```

## Automated Monitoring Scripts

### Basic Monitoring Script

Create a file named `monitor-validator.sh`:

```bash
#!/bin/bash

# Check if validator service is running
echo "Validator Service Status:"
systemctl is-active besu-validator
echo ""

# Check block height
echo "Current Block Height:"
BLOCK_HEX=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 | jq -r '.result')
BLOCK_DEC=$((16#${BLOCK_HEX:2}))
echo "Hex: $BLOCK_HEX, Decimal: $BLOCK_DEC"
echo ""

# Check peer count
echo "Connected Peers:"
PEER_HEX=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' http://localhost:8545 | jq -r '.result')
PEER_DEC=$((16#${PEER_HEX:2}))
echo "Hex: $PEER_HEX, Decimal: $PEER_DEC"
echo ""

# Check if node is in validator list
echo "Validator Status:"
VALIDATORS=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"],"id":1}' http://localhost:8545 | jq -r '.result[]')
NODE_ADDRESS=$(cat /opt/besu/address.txt)
if echo "$VALIDATORS" | grep -q "$NODE_ADDRESS"; then
  echo "This node is in the validator list"
else
  echo "WARNING: This node is NOT in the validator list"
fi
echo ""

# Check system resources
echo "System Resources:"
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
echo "Memory Usage:"
free -h | grep Mem | awk '{print "Used: " $3 " / Total: " $2}'
echo "Disk Usage:"
df -h | grep /$ | awk '{print "Used: " $3 " / Total: " $2 " (" $5 ")"}'
```

Make the script executable:

```bash
chmod +x monitor-validator.sh
```

Run the script:

```bash
./monitor-validator.sh
```

### Setting Up Cron Jobs for Regular Monitoring

To run the monitoring script regularly:

```bash
# Edit crontab
crontab -e

# Add a line to run the script every hour and save output to a log file
0 * * * * /path/to/monitor-validator.sh >> /var/log/validator-monitor.log 2>&1
```

## Advanced Monitoring with Prometheus and Grafana

For more comprehensive monitoring, you can set up Prometheus and Grafana.

### Installing Prometheus

1. Download and install Prometheus:

```bash
# Create user for Prometheus
useradd --no-create-home --shell /bin/false prometheus

# Create directories
mkdir -p /etc/prometheus /var/lib/prometheus

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar -xvf prometheus-2.45.0.linux-amd64.tar.gz

# Copy binaries
cp prometheus-2.45.0.linux-amd64/prometheus /usr/local/bin/
cp prometheus-2.45.0.linux-amd64/promtool /usr/local/bin/

# Copy configuration files
cp -r prometheus-2.45.0.linux-amd64/consoles /etc/prometheus
cp -r prometheus-2.45.0.linux-amd64/console_libraries /etc/prometheus

# Set ownership
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Clean up
rm -rf prometheus-2.45.0.linux-amd64 prometheus-2.45.0.linux-amd64.tar.gz
```

2. Configure Prometheus:

```bash
cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'besu'
    static_configs:
      - targets: ['localhost:9545']
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml
```

3. Create a systemd service for Prometheus:

```bash
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
```

4. Start and enable Prometheus:

```bash
systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus
```

### Configuring Besu for Prometheus

1. Update the Besu service file to enable metrics:

```bash
nano /etc/systemd/system/besu-validator.service
```

2. Add the following flags to the ExecStart line:

```
--metrics-enabled=true --metrics-host=0.0.0.0 --metrics-port=9545
```

3. Reload and restart the Besu service:

```bash
systemctl daemon-reload
systemctl restart besu-validator
```

### Installing Grafana

1. Install Grafana:

```bash
apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana
```

2. Start and enable Grafana:

```bash
systemctl start grafana-server
systemctl enable grafana-server
```

3. Access Grafana at http://your-server-ip:3000 (default credentials: admin/admin)

4. Add Prometheus as a data source:
   - Click on "Configuration" (gear icon) > "Data sources"
   - Click "Add data source"
   - Select "Prometheus"
   - Set URL to "http://localhost:9090"
   - Click "Save & Test"

5. Import a Besu dashboard:
   - Click on "+" > "Import"
   - Enter dashboard ID 10273 (Besu Dashboard)
   - Select your Prometheus data source
   - Click "Import"

## Setting Up Alerts

### Email Alerts with Prometheus Alertmanager

1. Install Alertmanager:

```bash
# Create user for Alertmanager
useradd --no-create-home --shell /bin/false alertmanager

# Create directories
mkdir -p /etc/alertmanager /var/lib/alertmanager

# Download Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar -xvf alertmanager-0.26.0.linux-amd64.tar.gz

# Copy binaries
cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/

# Set ownership
chown alertmanager:alertmanager /usr/local/bin/alertmanager /usr/local/bin/amtool
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager

# Clean up
rm -rf alertmanager-0.26.0.linux-amd64 alertmanager-0.26.0.linux-amd64.tar.gz
```

2. Configure Alertmanager:

```bash
cat > /etc/alertmanager/alertmanager.yml << EOF
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'your-email@example.com'
  smtp_auth_password: 'your-password'

route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'email'

receivers:
- name: 'email'
  email_configs:
  - to: 'your-email@example.com'
EOF

chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
```

3. Create a systemd service for Alertmanager:

```bash
cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF
```

4. Start and enable Alertmanager:

```bash
systemctl daemon-reload
systemctl start alertmanager
systemctl enable alertmanager
```

5. Configure Prometheus to use Alertmanager:

```bash
cat > /etc/prometheus/rules.yml << EOF
groups:
- name: besu_alerts
  rules:
  - alert: BesuDown
    expr: up{job="besu"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Besu node is down"
      description: "Besu node has been down for more than 5 minutes."
  
  - alert: LowPeerCount
    expr: ethereum_peer_count < 2
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Low peer count"
      description: "Besu node has less than 2 peers for more than 5 minutes."
  
  - alert: HighCPUUsage
    expr: rate(process_cpu_seconds_total{job="besu"}[5m]) * 100 > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage"
      description: "Besu node CPU usage is above 80% for more than 5 minutes."
  
  - alert: HighMemoryUsage
    expr: process_resident_memory_bytes{job="besu"} / (1024 * 1024 * 1024) > 6
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Besu node is using more than 6GB of memory for more than 5 minutes."
EOF

chown prometheus:prometheus /etc/prometheus/rules.yml
```

6. Update Prometheus configuration to include rules and Alertmanager:

```bash
cat > /etc/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules.yml"

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093

scrape_configs:
  - job_name: 'besu'
    static_configs:
      - targets: ['localhost:9545']
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml
```

7. Restart Prometheus:

```bash
systemctl restart prometheus
```

## SMS Alerts (Optional)

For SMS alerts, you can use a service like Twilio:

1. Sign up for a Twilio account at https://www.twilio.com/

2. Install the Twilio CLI:

```bash
npm install -g twilio-cli
```

3. Create a script to send SMS alerts:

```bash
cat > /usr/local/bin/send-sms-alert << EOF
#!/bin/bash

# Twilio credentials
TWILIO_ACCOUNT_SID="your_account_sid"
TWILIO_AUTH_TOKEN="your_auth_token"
TWILIO_PHONE_NUMBER="your_twilio_phone_number"
YOUR_PHONE_NUMBER="your_phone_number"

# Alert message
MESSAGE="\$1"

# Send SMS using Twilio API
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/\$TWILIO_ACCOUNT_SID/Messages.json" \
  --data-urlencode "To=\$YOUR_PHONE_NUMBER" \
  --data-urlencode "From=\$TWILIO_PHONE_NUMBER" \
  --data-urlencode "Body=\$MESSAGE" \
  -u "\$TWILIO_ACCOUNT_SID:\$TWILIO_AUTH_TOKEN"
EOF

chmod +x /usr/local/bin/send-sms-alert
```

4. Test the SMS alert:

```bash
/usr/local/bin/send-sms-alert "Test alert from Besu validator"
```

## Best Practices for Monitoring

1. **Regular Checks**: Set up automated checks to run at regular intervals.

2. **Log Rotation**: Configure log rotation to prevent logs from filling up your disk:
   ```bash
   nano /etc/logrotate.d/besu
   ```
   
   Add the following:
   ```
   /var/log/besu/*.log {
       daily
       rotate 7
       compress
       delaycompress
       missingok
       notifempty
       create 0640 root root
   }
   ```

3. **Backup Monitoring Data**: Regularly backup your Prometheus and Grafana data.

4. **Monitor Multiple Aspects**:
   - Node connectivity
   - Block production
   - System resources
   - Network traffic
   - Disk usage

5. **Set Up Redundant Monitoring**: Consider monitoring your validator from multiple locations.

6. **Document Your Monitoring Setup**: Keep documentation of your monitoring setup for future reference.

## Contact

For questions or support, please contact:

- Email: office@studio-blockchain.com
