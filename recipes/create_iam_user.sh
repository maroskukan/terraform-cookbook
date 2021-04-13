#!/usr/bin/env bash

# Define IAM Username
TF_IAM_USER="tfdemo"

# Create and add user to group
aws iam create-user --user-name $TF_IAM_USER
aws iam add-user-to-group \
--group-name AWSAdmins \
--user-name $TF_IAM_USER

# Generate access key
aws iam create-access-key --user-name $TF_IAM_USER