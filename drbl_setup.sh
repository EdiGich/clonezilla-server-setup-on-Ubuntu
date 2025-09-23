#!/bin/bash
# DRBL Installation Script for Ubuntu

# Note: This script is intended for Ubuntu distributions.
# The DRBL documentation specifies support for Ubuntu 22.04 (Jammy).
# Your system is Ubuntu 25.04, so we will use the Jammy repositories.
# This may have unintended side effects.

# Step 1: Add DRBL GPG key
echo "Adding DRBL GPG key..."
sudo wget -O /etc/apt/trusted.gpg.d/drbl-gpg.asc https://drbl.org/GPG-KEY-DRBL

# Step 2: Add DRBL APT repository
echo "Adding DRBL APT repository..."
echo "deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/drbl.list
echo "deb http://free.nchc.org.tw/drbl-core drbl stable" | sudo tee -a /etc/apt/sources.list.d/drbl.list

# Step 3: Update package list
echo "Updating package list..."
sudo apt-get update

# Step 4: Install DRBL and dependencies
echo "Installing DRBL and dependencies..."
sudo apt-get install -y drbl gawk isc-dhcp-server tftpd-hpa

echo "Initial DRBL setup complete."
echo "Next, you must run the following interactive commands to configure the DRBL environment:"
echo "1. sudo drblsrv -i"
echo "2. sudo drblpush -i"
