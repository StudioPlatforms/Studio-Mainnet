#!/bin/bash

# Studio Blockchain Dependencies Installation Script
# This script installs all the necessary dependencies for running a Studio Blockchain node

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installing Dependencies for Studio Blockchain ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
apt-get update

# Install basic dependencies
echo -e "${YELLOW}Installing basic dependencies...${NC}"
apt-get install -y \
  build-essential \
  curl \
  software-properties-common \
  git \
  vim \
  net-tools \
  mailutils

# Install Go
echo -e "${YELLOW}Installing Go...${NC}"
apt-get install -y golang-go

# Install Ethereum
echo -e "${YELLOW}Installing Go Ethereum...${NC}"
add-apt-repository -y ppa:ethereum/ethereum
apt-get update
apt-get install -y ethereum

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"
go version
geth version

echo -e "${GREEN}=== All dependencies installed successfully ===${NC}"
