# Comprehensive Guide to Setting Up a DRBL/Clonezilla Server on Ubuntu


## Introduction

This document provides a comprehensive, step-by-step guide to setting up a dedicated DRBL/Clonezilla server using Ubuntu Server. This server will allow you to capture a "master" disk image from one computer and deploy it to many other computers simultaneously over the network.

## Core Concepts

*   **DRBL (Diskless Remote Boot in Linux):** The underlying technology that provides network services (DHCP, TFTP) allowing client machines to boot a temporary OS from the network without needing their own hard drive.
*   **Clonezilla:** The powerful disk imaging tool that runs on the client machines after they boot from the DRBL server.
*   **PXE (Preboot Execution Environment):** A feature built into most network cards that allows a computer to boot from a network server instead of a local disk.

## Part 1: Prerequisites and Initial Server Setup

### 1.1 Hardware Requirements

The most critical requirement for a stable and efficient Clonezilla server is the network configuration.

*   **Server PC:** A dedicated computer to run the Ubuntu Server.
*   **Two Network Ports:** Your server computer should have **at least two Ethernet ports**.
    *   **Port 1 (WAN/Internet):** Connects to your main network for internet access (for downloading software and updates).
    *   **Port 2 (LAN/Imaging):** Connects to a dedicated, isolated network switch. All client computers that you want to clone will connect to this switch. This separation is crucial to prevent the DRBL's DHCP server from conflicting with your main network's DHCP server.
*   **Network Switch:** A basic, unmanaged network switch for your private imaging network.

### 1.2 Operating System Installation

1.  **Download Ubuntu Server:** Go to the official Ubuntu website and download the latest **Ubuntu Server LTS (Long-Term Support)** version. The "Live Server" installer is the correct choice.
2.  **Create Bootable USB:** Use a tool like Rufus or BalenaEtcher to create a bootable USB drive with the Ubuntu Server ISO.
3.  **Install Ubuntu:** Boot the server PC from the USB and follow the on-screen instructions to install Ubuntu Server. The default options are generally fine.

### 1.3 (Optional) Install a Desktop Environment

For easier navigation and file management, you may want to install a lightweight desktop environment.

```bash
# Update your package list
sudo apt update && sudo apt upgrade -y

# Install the Lubuntu desktop environment (lightweight and efficient)
sudo apt install lubuntu-desktop -y

# Reboot the server after installation
sudo reboot
```

## Part 2: DRBL/Clonezilla Software Installation

1.  **Add GPG Key and Repository:** Open a terminal and run the following commands to trust the DRBL project's software repository.

    ```bash
    wget -qO - https://drbl.org/GPG-KEY-DRBL | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/drbl.gpg
    echo "deb http://free.nchc.org.tw/drbl stable main" | sudo tee /etc/apt/sources.list.d/drbl.list
    ```

2.  **Install DRBL and Clonezilla:** Update your package list again and install the required packages.

    ```bash
    sudo apt update
    sudo apt install drbl clonezilla
    ```

## Part 3: Network Configuration (The Critical Step)

### 3.1 Identify Network Interfaces

First, identify the names of your two network interfaces. Run the command:
`ip a`
You will see outputs like `enp3s0`, `enp6s0`, etc. Note which one is connected to the internet and which one will be for your private cloning network.

### 3.2 Set a Static IP for the Imaging Port

The network port serving your private cloning network **must have a static IP address**. This is because it will be the DHCP server and gateway for all the client PCs. It cannot have an address that changes.

A standard and recommended configuration is:
*   **IP Address:** `192.168.100.1`
*   **Subnet Mask:** `255.255.255.0` (or `/24`)

The simplest way to manage this in modern Ubuntu is with `NetworkManager`.

1.  **Give NetworkManager Control:** Ensure the file `/etc/netplan/01-network-manager-all.yaml` exists and contains the following to let NetworkManager control all devices.
    ```yaml
    network:
      version: 2
      renderer: NetworkManager
    ```
    Apply the change with `sudo netplan apply`.

2.  **Create the Static IP Profile:** Use `nmcli` (NetworkManager Command Line Interface) to create a persistent profile. Replace `enp3s0` with the name of your imaging network port.
    ```bash
    sudo nmcli connection add type ethernet con-name "drbl-private" ifname enp3s0 ipv4.method manual ipv4.addresses 192.168.100.1/24
    ```

3.  **Activate the Connection:**
    ```bash
    sudo nmcli connection up drbl-private
    ```
    Verify with `ifconfig enp3s0` to confirm the IP is set correctly.

## Part 4: Configure DRBL Services

With the software installed and the network configured, you now need to tell DRBL how to operate.

1.  **Run the Server Configurator:**
    ```bash
    sudo drblsrv -i
    ```
    This will start an interactive script. Answer the questions carefully, paying attention to:
    *   **Hostname:** Give your server a name.
    *   **Network Interface for DRBL:** Choose the interface you set with the static IP (e.g., `enp3s0`).
    *   **DRBL Mode:** Choose "Full DRBL" (Mode 0).
    *   For most other questions, the default answers are fine.

2.  **Push the Configuration:** This command takes your answers from the previous step and configures all the system services (DHCP, TFTP, etc.).
    ```bash
    sudo drblpush -i
    ```
    Again, an interactive script will start.
    *   Confirm the settings.
    *   When asked if you want to start the services, say **Yes**.

Your server is now running and ready to serve clients.

## Part 5: Capturing and Deploying Images

### 5.1 Setting Up a Client Boot Menu (Recommended)

The most flexible way to run your server is to have it present a menu to any client that boots from the network. The client can then choose whether to save an image or restore an image.

1.  **Run the DCS Command:**
    ```bash
    sudo dcs
    ```
2.  **Select "All":** Choose to select all clients.
3.  **Choose "clonezilla-start":** This enters the Clonezilla menu.
4.  **Select "Beginner" mode.**
5.  **Choose "select-in-client":** This is the key option. It tells the server to let the client decide the action.
6.  For the remaining options (compression, etc.), the defaults are usually fine.

Now, your server will sit and wait. Any client that PXE boots will be presented with the Clonezilla Live menu where they can choose to `savedisk`, `restoredisk`, etc., on their own.

### 5.2 Capturing the Master Image

1.  If you used the "select-in-client" method above, boot your master client via PXE. Go to your "master" client computer, make sure it's connected to the private cloning network, and boot it up. Use the boot menu (e.g., F12, F10, ESC) to select **PXE Boot** or **Network Boot**.
2.  At the menu, choose `savedisk`.
3.  Give the image a name (e.g., `win10-office-master-v1`).
4.  Select the source disk to save.
5.  Confirm and let the process run. The image will be saved to `/home/partimag/` on your server.

### 5.3 Deploying the Master Image

1.  Boot your target clients via PXE.
2.  At the menu, choose `restoredisk`.
3.  Select the image you want to restore from the list.
4.  Select the target disk to overwrite.
5.  **Confirm multiple times (this is destructive!).**
6.  The cloning will begin. If you choose a multicast option, all clients will start at the same time.

---

This completes the setup. You now have a robust, network-based cloning solution.

### Reference
*   Official DRBL Installation Documentation: [https://drbl.org/installation/](https://drbl.org/installation/)
