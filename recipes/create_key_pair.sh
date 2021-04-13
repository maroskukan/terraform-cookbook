#!/usr/bin/env bash

# Define Key Pair Name
TF_EC2_KEYPAIR_NAME="tfkey"

# Create key pair
aws ec2 create-key-pair --key-name $TF_EC2_KEYPAIR_NAME --region us-east-1