# Blockchain Node Monitoring Guide

This guide explains how to set up and use the monitoring system for your Studio Blockchain validator node.

## Table of Contents

1. [Overview](#overview)
2. [Setting Up the Monitoring System](#setting-up-the-monitoring-system)
3. [Email Alerts Configuration](#email-alerts-configuration)
4. [Understanding the Monitoring Logs](#understanding-the-monitoring-logs)
5. [Customizing the Monitoring System](#customizing-the-monitoring-system)
6. [Troubleshooting](#troubleshooting)

## Overview

The monitoring system checks your node's health at regular intervals and sends alerts if any issues are detected. It monitors:

- Node connectivity (is the node running and responding to RPC calls?)
- Mining status (is the node actively mining blocks?)
- Peer connections (is the node connected to other nodes in the network?)
- Block progression (is the node producing/receiving new blocks?)
- System security (checks for known cryptocurrency mining malware)

## Setting Up the Monitoring System

### Installation

1. Copy the monitoring script to your home directory:

```bash
cp scripts/enhanced_monitor_blockchain.sh ~/
chmod +x ~/enhanced_monitor_blockchain.sh
```

2. Create a systemd service file:

```bash
cp config/blockchain-monitor.service /etc/systemd/system/
```

3. Update the paths in the service file if necessary:

```bash
sed -i "s|/root/enhanced_monitor_blockchain.sh|$HOME/enhanced_monitor_blockchain.sh|g" /etc/systemd/system/blockchain-monitor.service
```

4. Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable blockchain-monitor
sudo systemctl start blockchain-monitor
```

### Verification

Check if the monitoring service is running:

```bash
sudo systemctl status blockchain-monitor
```

View the monitoring logs:

```bash
tail -f /var/log/blockchain_monitor.log
```

## Email Alerts Configuration

The monitoring system can send email alerts when issues are detected. To set this up:

1. Install mailutils:

```bash
sudo apt-get install -y mailutils
```

2. Configure the mail system to use your SMTP server:

```bash
sudo nano /etc/postfix/main.cf
```

Add or modify these lines:

```
relayhost = [smtp.your-email-provider.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

3. Create the password file:

```bash
echo "[smtp.your-email-provider.com]:587 username:password" | sudo tee /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
```

4. Restart Postfix:

```bash
sudo systemctl restart postfix
```

5. Update the email address in the monitoring script:

```bash
sed -i "s|ALERT_EMAIL=\".*\"|ALERT_EMAIL=\"your-email@example.com\"|g" ~/enhanced_monitor_blockchain.sh
```

6. Test the email configuration:

```bash
echo "Test email from blockchain node" | mail -s "Test Alert" your-email@example.com
```

## Understanding the Monitoring Logs

The monitoring script logs its activities to `/var/log/blockchain_monitor.log`. Here's how to interpret the log entries:

- `Checking if node is running...`: The script is checking if the node is responding to RPC calls.
- `Node is not responding! Attempting to restart...`: The node is not responding, and the script is trying to restart it.
- `Checking mining status...`: The script is checking if the node is mining.
- `Mining is not active. Restarting...`: Mining has stopped, and the script is trying to restart it.
- `Mining is active.`: Mining is working correctly.
- `Current block number: 0x...`: The current block number in hexadecimal.
- `Peer count: N`: The number of peers the node is connected to.
- `Warning: No peers connected!`: The node has no peer connections.
- `ALERT: [Subject] - [Message]`: An alert has been sent.
- `Suppressing peer alert (sent one X seconds ago, threshold is Y seconds)`: An alert is being suppressed because a similar alert was sent recently.

## Customizing the Monitoring System

You can customize the monitoring system by editing the script:

```bash
nano ~/enhanced_monitor_blockchain.sh
```

Here are some parameters you might want to adjust:

- `CHECK_INTERVAL`: How often the script checks the node (in seconds).
- `ALERT_EMAIL`: The email address to send alerts to.
- `CONSECUTIVE_FAILURES_THRESHOLD`: How many consecutive mining failures before sending an alert.
- `PEER_ALERT_INTERVAL`: How often to send alerts about peer connection issues (in seconds).

After making changes, restart the monitoring service:

```bash
sudo systemctl restart blockchain-monitor
```

## Troubleshooting

### Common Issues

#### Monitoring Service Won't Start

Check the systemd logs:

```bash
sudo journalctl -u blockchain-monitor -n 50
```

Make sure the script path is correct in the service file:

```bash
cat /etc/systemd/system/blockchain-monitor.service
```

#### Email Alerts Not Being Sent

Test the email configuration:

```bash
echo "Test email" | mail -s "Test" your-email@example.com
```

Check the mail logs:

```bash
tail -f /var/log/mail.log
```

Make sure the SMTP credentials are correct:

```bash
cat /etc/postfix/sasl_passwd
```

#### High CPU Usage

If the monitoring script is using too much CPU, you can increase the check interval:

```bash
sed -i "s|CHECK_INTERVAL=.*|CHECK_INTERVAL=60|g" ~/enhanced_monitor_blockchain.sh
sudo systemctl restart blockchain-monitor
```

#### Log File Growing Too Large

Set up log rotation:

```bash
sudo nano /etc/logrotate.d/blockchain-monitor
```

Add the following:

```
/var/log/blockchain_monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
```

This will rotate the log file daily and keep 7 days of logs.
