# DRBL Server Setup Guide for Ubuntu

This guide will walk you through setting up a DRBL (Diskless Remote Boot in Linux) server on your Ubuntu machine.

## 1. Run the DRBL Setup Script

First, you need to execute the `drbl_setup.sh` script with root privileges. This script will perform the initial installation of the DRBL server software.

Open a terminal and run the following command:

```bash
sudo bash drbl_setup.sh
```

**Note:** This script is designed for Ubuntu 22.04 (Jammy), as specified in the DRBL documentation. Since you are using Ubuntu 25.04, there's a chance of encountering unexpected issues.

## 2. Interactive DRBL Configuration

Once the script has finished, you need to run two interactive commands to configure the DRBL environment. These commands will ask you a series of questions about your network configuration and desired setup.

It is highly recommended to have the following information ready:

*   Your network interface names (e.g., `eth0`, `eth1`)
*   The IP address ranges you want to use for your client machines
*   Whether you want to use Full DRBL, Full Clonezilla, DRBL SSI, or Clonezilla Box mode.

### a. Configure DRBL Server

Run the following command in your terminal:

```bash
sudo drblsrv -i
```

Follow the on-screen prompts to configure the DRBL server. You can refer to the `drbl_installation` file for more detailed information about the available options.

### b. Push Configuration to Clients

After configuring the DRBL server, you need to push the configuration to the client machines. Run the following command:

```bash
sudo drblpush -i
```

This command will configure services like DHCP, TFTP, and NFS, and prepare the necessary files for your client machines to boot from the network.

## 3. Client Setup

Once the DRBL server is fully configured, you will need to set up your client machines to boot from the network. The `drbl_installation` file provides detailed instructions on how to do this for different scenarios (PXE, floppy, CDROM, or local hard drive).

## 4. Starting a Clonezilla Save Session

To begin saving an image from a client machine, you use the `drbl-ocs` command. This command configures the PXE boot menu to launch Clonezilla in a specific mode.

Here is an example command to save the disk from a single client to an image named `my-first-image`. The client will be prompted to start, and will power off when finished.

```bash
sudo drbl-ocs -g auto -e1 auto -e2 -c -r -j2 -p poweroff --clients-to-wait 1 startdisk save my-first-image ask_user
```

## 5. Fixing the Bootloader (Important)

A known issue with `drbl-ocs` is that it can sometimes delete essential bootloader files from the TFTP directory, causing clients to get stuck in a "timer loop".

If you experience this, you must run the following command **after** running `drbl-ocs` to restore the necessary files:

```bash
sudo cp /usr/lib/syslinux/modules/bios/* /tftpboot/nbi_img/
```

This command copies the required SYSLINUX BIOS modules back into the TFTP boot image directory, allowing clients to boot correctly into the Clonezilla session.

Good luck!
