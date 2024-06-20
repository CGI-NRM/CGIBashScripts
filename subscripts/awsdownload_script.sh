#!/bin/bash

# parse input file with new credentials:
awsinfo=(`awk '{print $4}' input.txt`)

# File that stores aws credentials:
credentials_file=~/.aws/credentials

# Save current credentials to backup if present:
mkdir -p ~/.aws
touch $credentials_file
cat $credentials_file >> ~/.aws/credentials.bak

# Write new credentials:
echo "# "${awsinfo[0]} > $credentials_file
echo "[default]" >> $credentials_file
echo "aws_access_key_id = "${awsinfo[1]} >> $credentials_file
echo "aws_secret_access_key = "${awsinfo[2]} >> $credentials_file

# Download data from amazon S3:
aws s3 cp s3://${awsinfo[0]} . --recursive

# Get location of the md5 sums reported by BMK
md5file=$(find . -iname '*md5*' -type f)

datapath=$(dirname $md5file)
# Check md5sums:
(cd $datapath; md5sum --check data_md5.txt)
