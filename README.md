# clonezilla-server-setup-on-Ubuntu

==============================================================
            Clonezilla PXE Boot Setup - Status Report
==============================================================

[1] Server Configuration
-----------------------
- TFTP Server: tftpd-hpa
  * Directory: /tftpboot/nbi_img
- NFS Server: exported directory /tftpboot/nbi_img/clonezilla
- DHCP Server: isc-dhcp-server active and running

[2] Important Files
------------------
- Kernel: /tftpboot/vmlinuz-pxe
- Initrd: /tftpboot/initrd-pxe.img
- Root filesystem: /tftpboot/nbi_img/clonezilla/filesystem.squashfs
- PXELINUX config: /tftpboot/pxelinux.cfg/default

[3] PXELINUX Menu Configuration
-------------------------------
Current active menu entry:

LABEL clonezilla
  MENU LABEL Clonezilla Live (NFS Root)
  KERNEL vmlinuz-pxe
  APPEND initrd=initrd-pxe.img boot=live netboot=nfs nfsroot=192.168.100.1:/tftpboot/nbi_img/clonezilla fetch=nfs://192.168.100.1:/tftpboot/nbi_img/clonezilla/filesystem.squashfs ip=dhcp components quiet
  TEXT HELP
    * Clonezilla boots directly with NFS root filesystem
  ENDTEXT

Other append entries commented out for testing:
# append initrd=initrd-pxe.img boot=live root=/dev/ram0 union=overlay noswap noprompt vga=788
# append initrd=initrd-pxe.img devfs=nomount drblthincli=off selinux=0 quiet text 1 edd=on

[4] Setup Steps Executed
-----------------------
1. Installed and configured tftp-hpa and verified TFTP server works:
   $ sudo apt install tftp-hpa
   $ ls /tftpboot/nbi_img/
2. Copied Clonezilla live files:
   $ sudo cp clonezilla-live/live/vmlinuz /tftpboot/vmlinuz-pxe
   $ sudo cp clonezilla-live/live/initrd.img /tftpboot/initrd-pxe.img
   $ sudo mkdir -p /tftpboot/clonezilla
   $ sudo cp clonezilla-live/live/filesystem.squashfs /tftpboot/clonezilla/
3. Configured NFS exports:
   $ sudo nano /etc/exports
   $ sudo exportfs -ra
4. Verified NFS exports:
   $ showmount -e
5. PXELINUX menu created and tested, loop device mounted for ISO testing:
   $ LOOP_DEV=$(sudo losetup -f --show ~/Downloads/clonezilla-live-3.0.2-21-amd64.iso)
   $ sudo mount $LOOP_DEV /mnt/clonezilla_alt
   $ sudo umount /mnt/clonezilla_alt
   $ sudo losetup -d $LOOP_DEV
6. Restarted TFTP, NFS, DHCP servers:
   $ sudo systemctl restart tftpd-hpa nfs-kernel-server isc-dhcp-server

[5] Errors and Issues Encountered
---------------------------------
1. Initial TFTP failure:
   - 'tftp' command not found; server lacked tftp-hpa.
   - Fixed by installing tftp-hpa.

2. PXE boot failure on client:
   - Error: "You need to load the kernel first"
   - Cause: incorrect TFTP file path or missing permissions.
   - Fixed by moving files to /tftpboot/nbi_img and correcting fetch paths.

3. Boot error from client:
   - "No root device specified. Boot arguments must include a root= parameter."
   - Cause: missing 'root=' in APPEND line for PXELINUX.
   - Still needs verification with proper NFS root.

4. Multiple PXELINUX labels:
   - Confusion between commented 'PXE Clonezilla Live' label and main 'clonezilla' label.
   - Adjusted active label for testing and made others commented out.

5. NFS over TCP not available:
   - Some clients failed to mount filesystem via NFS.
   - Recommended to confirm server NFS options.

[6] Current Status
-----------------
- PXE client successfully retrieves kernel and initrd.
- Clonezilla Live menu entry is visible on GRUB/DRBL menu.
- Booting into Clonezilla Live still fails due to NFS/root configuration.
- Server-side files and permissions verified and correct.
- DHCP is operational and assigning IPs correctly to PXE clients.

[7] Next Steps
--------------
1. Update PXELINUX 'APPEND' line to include proper NFS root and root= parameter.
2. Test PXE boot on a client.
3. Confirm network mount of filesystem.squashfs is successful.
4. Document configuration changes for future reference.
==============================================================
