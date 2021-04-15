#!/usr/bin/env bash

# Define version
TERRAFORM_VERSION=0.15.0

# Download, extract and move
wget -O "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Unzip the archive
sudo unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin

# Cleanup
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip