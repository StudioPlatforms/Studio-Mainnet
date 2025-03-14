# Validator Node Setup Guide

This guide provides detailed instructions for setting up a validator node on the Studio Blockchain network.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Setup](#system-setup)
3. [Installing Dependencies](#installing-dependencies)
4. [Setting Up the Node](#setting-up-the-node)
5. [Creating a Validator Account](#creating-a-validator-account)
6. [Configuring the Node](#configuring-the-node)
7. [Starting the Node](#starting-the-node)
8. [Setting Up Monitoring](#setting-up-monitoring)
9. [Securing Your Node](#securing-your-node)
10. [Maintenance](#maintenance)

## Prerequisites

Before you begin, ensure you have:

- A Linux server (Ubuntu 20.04 LTS or later recommended)
- Root or sudo access to the server
- Basic knowledge of Linux command line
- A static IP address for your server
- Port 30303 (TCP/UDP) open in your firewall

## System Setup

### Hardware Requirements

- CPU: 4+ cores
- RAM: 8+ GB
- Storage: 100+ GB SSD (preferably NVMe for better performance)
- Network: 100+ Mbps connection

### Firewall Configuration

Ensure that port 30303 (TCP/UDP) is open for P2P communication:

```bash
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
```

If you plan to expose the RPC API, also open port 8545 (but secure it properly):

```bash
sudo ufw allow 8545/tcp
```

## Installing Dependencies

You can install all the necessary dependencies using the provided script:

```bash
chmod +x scripts/install_dependencies.sh
sudo ./scripts/install_dependencies.sh
```

Or manually install them:

```bash
# Update package lists
sudo apt-get update

# Install basic dependencies
sudo apt-get install -y build-essential curl software-properties-common git vim net-tools mailutils

# Install Go
sudo apt-get install -y golang-go

# Install Ethereum
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install -y ethereum
```

Verify the installations:

```bash
go version
geth version
```

## Setting Up the Node

### Directory Structure

Create the necessary directories:

```bash
mkdir -p ~/studio-mainnet/node/data
mkdir -p ~/studio-mainnet/node/scripts
```

### Genesis Block

Copy the genesis file:

```bash
cp genesis.json ~/studio-mainnet/node/
```

Initialize the blockchain with the genesis file:

```bash
geth --datadir ~/studio-mainnet/node/data init ~/studio-mainnet/node/genesis.json
```

## Creating a Validator Account

Create a new account that will serve as your validator:

```bash
geth --datadir ~/studio-mainnet/node/data account new
```

You will be prompted to enter a password. Create a strong password and remember it, as you'll need it to unlock your account.

Save your account address for easy reference:

```bash
ACCOUNT=$(geth --datadir ~/studio-mainnet/node/data account list | head -n 1 | grep -o '0x[0-9a-fA-F]\+')
echo "$ACCOUNT" > ~/studio-mainnet/node/address.txt
```

Create a password file (this will be used to automatically unlock your account when starting the node):

```bash
echo "YourStrongPassword" > ~/studio-mainnet/node/password.txt
chmod 600 ~/studio-mainnet/node/password.txt  # Restrict access to the password file
```

## Configuring the Node

### Static Nodes

Configure static nodes to connect to the network:

```bash
mkdir -p ~/studio-mainnet/node/data/geth
cp config/static-nodes.json.template ~/studio-mainnet/node/data/geth/static-nodes.json
```

### Start Script

Copy the start script:

```bash
cp scripts/start.sh ~/studio-mainnet/node/scripts/
chmod +x ~/studio-mainnet/node/scripts/start.sh
```

The start script contains the following parameters:

- `--networkid 240241`: The network ID for Studio Blockchain
- `--port 30303`: The P2P port
- `--http`: Enable the HTTP-RPC server
- `--http.api "eth,net,web3,personal,miner,admin,clique,txpool,debug"`: Enable APIs
- `--mine`: Enable mining
- `--syncmode full`: Use full sync mode
- And more...

## Starting the Node

### Systemd Service

Create a systemd service file for the node:

```bash
cp config/geth-studio.service /etc/systemd/system/
```

Update the paths in the service file if necessary:

```bash
sed -i "s|/root/studio-mainnet|$HOME/studio-mainnet|g" /etc/systemd/system/geth-studio.service
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable geth-studio
sudo systemctl start geth-studio
```

Check the status of the service:

```bash
sudo systemctl status geth-studio
```

View the logs:

```bash
sudo journalctl -u geth-studio -f
```

## Setting Up Monitoring

### Monitoring Script

Copy the monitoring script:

```bash
cp scripts/enhanced_monitor_blockchain.sh ~/
chmod +x ~/enhanced_monitor_blockchain.sh
```

### Email Configuration

Install and configure mailutils to send email alerts:

```bash
sudo apt-get install -y mailutils
```

Configure the mail system to use your SMTP server:

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

Create the password file:

```bash
echo "[smtp.your-email-provider.com]:587 username:password" | sudo tee /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd
```

Restart Postfix:

```bash
sudo systemctl restart postfix
```

Test the email configuration:

```bash
echo "Test email from blockchain node" | mail -s "Test Alert" your-email@example.com
```

### Monitoring Service

Create a systemd service file for the monitoring script:

```bash
cp config/blockchain-monitor.service /etc/systemd/system/
```

Update the paths in the service file if necessary:

```bash
sed -i "s|/root/enhanced_monitor_blockchain.sh|$HOME/enhanced_monitor_blockchain.sh|g" /etc/systemd/system/blockchain-monitor.service
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable blockchain-monitor
sudo systemctl start blockchain-monitor
```

Check the status of the service:

```bash
sudo systemctl status blockchain-monitor
```

View the logs:

```bash
tail -f /var/log/blockchain_monitor.log
```

## Securing Your Node

### Firewall

Ensure that only necessary ports are open:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 30303/tcp
sudo ufw allow 30303/udp
sudo ufw enable
```

### Secure RPC

If you need to expose the RPC API, consider using a reverse proxy with authentication:

```bash
sudo apt-get install -y nginx
```

Configure Nginx as a reverse proxy:

```bash
sudo nano /etc/nginx/sites-available/geth
```

Add the following configuration:

```
server {
    listen 8545 ssl;
    server_name your-server-name;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8545;
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

Create a password file:

```bash
sudo apt-get install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd username
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/geth /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### Regular Updates

Keep your system and Geth up to date:

```bash
sudo apt-get update
sudo apt-get upgrade
```

## Maintenance

### Backup

Regularly backup your keystore files:

```bash
cp -r ~/studio-mainnet/node/data/keystore ~/backup/
```

### Monitoring

Check the logs regularly:

```bash
tail -f /var/log/blockchain_monitor.log
journalctl -u geth-studio -f
```

### Troubleshooting

If you encounter issues, check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) file for common problems and solutions.
