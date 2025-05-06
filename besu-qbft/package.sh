#!/bin/bash

# This script packages the files for deployment to the other validator servers

echo "Packaging files for deployment..."

# Create a tar file with all the necessary files
tar -czf studio-qbft-deployment.tar.gz \
    studio-qbft/genesis.json \
    studio-qbft/besu-validator.service \
    studio-qbft/deploy.sh \
    studio-qbft/README.md \
    studio-qbft/Node-1 \
    studio-qbft/Node-2 \
    studio-qbft/Node-3 \
    studio-qbft/Node-4 \
    studio-qbft/Node-5

echo "Package created: studio-qbft-deployment.tar.gz"
echo "You can now copy this package to the other validator servers."
echo ""
echo "To deploy on each server:"
echo "1. Copy the package to the server"
echo "2. Extract the package: tar -xzf studio-qbft-deployment.tar.gz"
echo "3. Run the deployment script with the appropriate validator number and IP address"
echo ""
echo "For example:"
echo "- On Validator 1 (167.86.95.117): ./studio-qbft/deploy.sh 1 167.86.95.117"
echo "- On Validator 2 (173.212.200.31): ./studio-qbft/deploy.sh 2 173.212.200.31"
echo "- On Validator 4 (173.249.16.253): ./studio-qbft/deploy.sh 4 173.249.16.253"
echo "- On Validator 5 (62.171.162.49): ./studio-qbft/deploy.sh 5 62.171.162.49"
