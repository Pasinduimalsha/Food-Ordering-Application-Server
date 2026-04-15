#!/bin/bash
# Install to the current project workspace to avoid all permission issues
INSTALL_DIR="$(pwd)/aws-cli-inner"
BIN_DIR="$(pwd)/aws-bin"

mkdir -p "$BIN_DIR"

if ! [ -f "$BIN_DIR/aws" ]; then
    echo "AWS CLI not found in workspace, installing to $BIN_DIR..."
    
    # Download
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    
    # Unzip using python
    python3 -m zipfile -e awscliv2.zip .
    
    # FIX: Grant execution permissions to the extracted installer
    chmod +x ./aws/install
    chmod +x ./aws/dist/aws
    
    # Install into workspace folders
    ./aws/install -i "$INSTALL_DIR" -b "$BIN_DIR" --update
    
    # Verify and ensure the binary is executable
    chmod +x "$BIN_DIR/aws"
    "$BIN_DIR/aws" --version

    # Cleanup installer
    rm -rf awscliv2.zip ./aws
    echo "AWS CLI installed successfully to $BIN_DIR"
else
    echo "AWS CLI already present in workspace."
fi
