#!/bin/bash
# Check if AWS CLI is already installed
if ! command -v /usr/local/bin/aws &> /dev/null; then
    echo "AWS CLI not found, installing..."
    sudo apt-get update
    sudo apt-get install -y unzip curl

    # Download AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    
    # Verify installation
    /usr/local/bin/aws --version

    # Cleanup to save disk space
    rm -rf awscliv2.zip ./aws
    echo "AWS CLI installed successfully and installer files removed."
else
    echo "AWS CLI is already installed at $(which /usr/local/bin/aws)"
fi
