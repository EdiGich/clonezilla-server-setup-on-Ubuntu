# Clonezilla Ubuntu Server Setup Guide (Revised)

This guide details the corrected and verified process of setting up a dedicated Ubuntu Server to act as a Clonezilla server for capturing and deploying disk images across a network.

## Key Concepts

*   **DRBL (Diskless Remote Boot in Linux):** Provides the core network services (DHCP, TFTP) that allow client machines to boot a temporary OS from the network.
*   **Clonezilla:** The disk imaging tool that runs on the client after booting from the DRBL server.
*   **PXE (Preboot Execution Environment):** A feature of a computer's network card that allows it to boot from a network server.
*   **Master Image:** A file containing the full contents of a perfectly configured hard drive, which can be deployed to other machines.
*   **Image Repository:** The directory on the server where master images are stored (by default, `/home/partimag`).

## Prerequisites

1.  **Dedicated Server:** A PC running a fresh installation of Ubuntu Server LTS (22.04 is recommended).
2.  **Two Network Interfaces on Server:**
    *   One connected to the **internet** (for updates). Let's call this the "WAN" port.
    *   One dedicated to the **imaging network** where client PCs will connect. Let's call this the "LAN" port.
3.  **Network Switch:** To connect the server's LAN port and all client PCs for imaging.

---

## Part 1: Server Installation and Configuration

These steps install the necessary software and configure the network services.

### 1. Update and Add DRBL Repository

First, ensure your server's package list is up-to-date and install the tools needed to add the DRBL repository securely.

```bash
sudo apt-get update
sudo apt-get install -y gnupg wget
```

Now, add the DRBL project's GPG key and repository information.

```bash
wget -q http://drbl.org/GPG-KEY-DRBL -O- | sudo gpg --dearmor -o /usr/share/keyrings/drbl-keyring.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/drbl-keyring.gpg] http://free.nchc.org.tw/drbl-core drbl stable" > /etc/apt/sources.list.d/drbl.list'
```

### 2. Install DRBL and DHCP Server

Update the package list again, then install the DRBL package. **Crucially, we will also manually install the DHCP server**, as the DRBL scripts sometimes fail to do this automatically.

```bash
sudo apt-get update
sudo apt-get install -y drbl isc-dhcp-server
```

### 3. Run the DRBL Push Configuration

This is the main configuration wizard. It will set up all the network services based on your answers.

```bash
sudo drblpush -i
```

Answer the questions in the wizard carefully, using the values we found to be successful:

*   **Hostname:** `ceh-System` (or accept default)
*   **NIS/YP domain:** `drbl` (or accept default)
*   **DNS Service:** `[N/n]` No
*   **Network Interface (WAN):** Choose your internet-facing network card.
*   **Network Interface (LAN):** Choose your imaging network card (e.g., `enp6s0`).
*   **DHCP IP Range:** `192.168.100.0` (Accept this if offered).
*   **DRBL Mode:** `[1]` (DRBL SSI Mode)
*   **Clonezilla Mode:** `[1]` (Clonezilla box mode)
*   **Image Directory:** `/home/partimag` (Accept default)
*   **Firewall Rules:** `[y/N]` y
*   **Graphical Menu:** `[Y/n]` Y
*   **For all other questions,** you can safely accept the default by pressing **Enter**.
*   When asked **"Do you want to run this command now?"** at the end, answer `y`.

After the script finishes, confirm the DHCP service is running:

```bash
sudo ss -lupn | grep ':67'
```
You should see output indicating that `dhcpd` is listening. If not, the configuration failed.

---

## Part 2: Saving an Image from a Client PC

1.  Connect the "master" client PC (the one you want to clone) to the imaging network switch.
2.  On the **server**, run the following command to start a "save" session waiting for one client:
    ```bash
    sudo drbl-ocs -b -g auto -e1 auto -e2 -c -r -j2 -p poweroff --clients-to-wait 1 savedisk ask_user ask_user
    ```
3.  Boot the **client PC**. Enter its BIOS/UEFI menu and select **PXE Boot** (or Network Boot) as the first boot device.
4.  The client will get an IP address from the server and boot into the Clonezilla interface.
5.  Follow the on-screen prompts on the **client** to name the image and confirm the source disk you want to save. The image will be saved to `/home/partimag/` on the server.

---

## Part 3: Deploying an Image to Client PCs

### To a Single Client

1.  On the **server**, run the following command, replacing `MY_IMAGE_NAME` with the name of the image you want to deploy:
    ```bash
    sudo drbl-ocs -b -g auto -e1 auto -e2 -c -r -j2 -p poweroff restoredisk MY_IMAGE_NAME ask_user
    ```
2.  PXE boot the target client PC. It will boot into Clonezilla and begin the restoration process automatically after you confirm the target disk on the client.

### To Multiple Clients (Multicast)

1.  On the **server**, run this command, replacing `MY_IMAGE_NAME` and adjusting the number of clients (`--clients-to-wait 5`):
    ```bash
    sudo drbl-ocs -b -g auto -e1 auto -e2 -c -r -j2 -p poweroff --clients-to-wait 5 multicast_restoredisk MY_IMAGE_NAME sda
    ```
    *(This waits for 5 clients before starting the deployment to the `sda` disk on all of them simultaneously.)*
2.  PXE boot all the target client PCs. The server will wait until the specified number of clients have connected, then begin sending the image to all of them at once.
