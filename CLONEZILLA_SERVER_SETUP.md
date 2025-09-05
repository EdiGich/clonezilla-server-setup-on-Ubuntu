# Clonezilla Ubuntu Server Setup for Disk Imaging

This guide details the process of setting up a dedicated Ubuntu Server to act as a Clonezilla server for capturing and deploying disk images across a network. This is ideal for labs, workshops, or any scenario requiring the mass deployment of a standardized operating system and software configuration.

## Key Concepts

*   **DRBL (Diskless Remote Boot in Linux):** Provides the underlying infrastructure (DHCP, TFT, etc.) that allows client machines to boot from the network.
*   **Clonezilla:** The disk imaging tool that runs on top of DRBL to save and restore disk images.
*   **PXE (Preboot Execution Environment):** A feature of a computer's network card that allows it to boot from a network server instead of a local hard drive.
*   **Master Image:** A single, pristine image file of a fully configured computer's hard drive, which will be replicated onto other machines.
*   **Image Repository:** A directory on the server (`/home/partimag`) where the master images are stored.

## Prerequisites

1.  **Dedicated Server:** A computer to run the Ubuntu Server OS. It should have a large enough hard drive to store the master images.
2.  **Master Machine:** The computer with the fully configured operating system (e.g., Windows 11 with all software installed) that you want to clone. For the initial image creation, this guide assumes the master disk is installed in the server itself as a secondary drive.
3.  **Ubuntu Server LTS:** A fresh installation of Ubuntu Server (an LTS version like 22.04 is recommended).
4.  **Network Switch:** All machines (server and clients) must be connected to the same local network.

---

## Part 1: Server Installation and Configuration

These steps set up the DRBL/Clonezilla services on your Ubuntu server.

### 1. Install DRBL and Clonezilla

First, we need to add the DRBL project's public key and repository to our server's package manager.

```bash
sudo apt-get update
sudo apt-get install -y gnupg
wget -q http://drbl.org/GPG-KEY-DRBL -O- | sudo apt-key add -
```

Now, add the DRBL repository to your sources list, replacing `jammy` with the appropriate codename for your Ubuntu version if necessary (`focal` for 20.04, `jammy` for 22.04).

```bash
sudo sh -c 'echo "deb http://free.nchc.org.tw/drbl-core drbl stable" >> /etc/apt/sources.list.d/drbl.list'
sudo apt-get update
sudo apt-get install -y drbl
```

### 2. Run the Initial DRBL Configuration

This wizard will configure the network services.

```bash
sudo drbl-ocs-setup
```

Follow the prompts in the wizard. For most standard setups, you can accept the default choices by pressing **Enter**.

### 3. Start the DRBL/Clonezilla Server Manager

After the initial setup, you start the main management tool with `dcs`.

```bash
sudo dcs
```

Navigate the menus:

1.  **Select mode:** Choose **`All`** (press Spacebar to select, then Enter).
2.  **Main menu:** Choose **`clonezilla-start`**.

This will launch the Clonezilla wizard, which we will use to create the master image.

---

## Part 2: Creating the Master Disk Image

In this phase, we create the `windows-11-master-image` from the secondary disk (`/dev/sdb`) inside the server.

### 1. Launch the `savedisk` Wizard

In the Clonezilla wizard started from `dcs`, make the following selections:

1.  **Image Directory:** Choose **`local_dev`** (to use the local hard drive for storage).
2.  **Repository Partition:** Select the partition where `/home/partimag` is located. This is your main Linux server partition (e.g., `/dev/sda2`). **Do NOT choose the Windows disk (`sdb`).**
3.  **Mode:** Choose **`Beginner`** mode.
4.  **Action:** Select **`savedisk`** (to save the entire disk).
5.  **Image Name:** Enter a descriptive name like `windows-11-master-image`.
6.  **Source Disk:** Choose the disk to be cloned (e.g., `/dev/sdb`).
7.  **Compression:** Select **`-z1p`** (parallel gzip, a safe default).
8.  **Splitting:** Enter **`0`** to create a single large image file.
9.  **Filesystem Check:** **`Skip checking`**. This is important as the check is not for NTFS.
10. **Image Check:** **`Yes, check the saved image`**. This verifies integrity.
11. **Post-action:** Choose **`-p poweroff`**. This is the safest default for future deployments.

### 2. Final Confirmation and Execution

Clonezilla will show you a summary of the command it's about to run and ask for final confirmation. Type **`y`** and press **Enter**.

**This does not start the imaging process!** It only configures the server and makes it ready. The server is now waiting for a client to PXE boot.

### 3. The Server as its Own Client

To start the actual imaging process, you must reboot the server and tell it to boot from the network *one time*.

1.  **Reboot the server:** `sudo reboot`
2.  During startup, press the appropriate key (**F12, Esc, F10**) to enter the **Boot Menu**.
3.  From the boot device list, select the option for **Network Boot** or **PXE Boot**.

The machine will now boot from its own network service, load the Clonezilla environment you just configured, and automatically begin the `savedisk` process. You will see progress bars as the image is created.

When finished, the machine will power off. Your master image is now successfully created and stored in `/home/partimag/windows-11-master-image` on the server. You can now power the server back on and let it boot normally from its hard drive for the next phase.

---

## Part 3: Deploying the Image to Client Machines

With the master image created, you can now use the server to deploy it to other laptops. The process is similar to the creation step but in reverse.

1.  Run `sudo dcs` and start the Clonezilla wizard.
2.  This time, choose the **`restoredisk`** option.
3.  Select the image you want to deploy (e.g., `windows-11-master-image`).
4.  Select the target disk on the client machines.
5.  Confirm your choices. The server will now be ready to deploy the image.
6.  Power on your client laptops and have them **PXE boot** from the network. They will connect to the server, and the image restoration process will begin automatically.
