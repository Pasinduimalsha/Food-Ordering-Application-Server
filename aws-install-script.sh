#!/bin/bash
# Define local paths (No sudo needed)
BIN_DIR="$HOME/.local/bin"
INSTALL_DIR="$HOME/.aws-cli-install"

# Create bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

if ! [ -f "$BIN_DIR/aws" ]; then
    echo "AWS CLI not found, installing locally to $BIN_DIR..."
    
    # Download AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    
    # Use Python3 to unzip (avoids needing 'sudo apt install unzip')
    python3 -m zipfile -e awscliv2.zip .
    
    # Install to the home directory (avoids needing sudo)
    ./aws/install -i "$INSTALL_DIR" -b "$BIN_DIR" --update
    
    # Verify
    "$BIN_DIR/aws" --version

    # Cleanup to save space
    rm -rf awscliv2.zip ./aws
    echo "AWS CLI installed successfully to $BIN_DIR"
else
    echo "AWS CLI is already installed at $BIN_DIR/aws"
fi
