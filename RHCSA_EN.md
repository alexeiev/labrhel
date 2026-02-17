# Questions

## 1. Configure network settings on node1.
    Configure node1 with the following network parameters:
    - Hostname: node1.domain250.example.com
    - IPv4 address: 172.25.250.100
    - Subnet mask: 255.255.255.0 (/24)
    - Gateway: 172.25.250.254
    - DNS: 172.25.250.254

## 2. Configure YUM repositories.
    Configure the following YUM repositories on the system:
    i) Name = BaseOS
       BaseURL = http://content/rhel9.0/x86_64/dvd/BaseOS
       GPG check is disabled.
       Repository is enabled.
    ii) Name = AppStream
        BaseURL = http://content/rhel9.0/x86_64/dvd/Appstream
        GPG check is disabled.
        Repository is enabled.

## 3. Debug SELinux.
    A web server running on non-standard port 82 is unable to serve content.
    i) Configure the web server to serve files from /var/www/html on port 82.
    ii) Ensure the correct SELinux context is applied.
    iii) Configure the firewall to allow traffic on port 82.
    iv) The web server service must start automatically on boot.

## 4. Create user accounts.
    i) Create a group called sysmgrs.
    ii) Create user natasha with sysmgrs as a supplementary group.
    iii) Create user harry with sysmgrs as a supplementary group.
    iv) Create user sarah with no interactive shell access (nologin). Sarah must not be a member of sysmgrs.
    v) Set the password flectrag for natasha, harry and sarah.

## 5. Configure a cron job.
    Configure a cron job for user harry:
    i) The job runs daily at 14:23.
    ii) The command to execute is: /usr/bin/echo hello

## 6. Create a collaborative directory.
    Create the directory /home/managers with the following requirements:
    i) Group owner is sysmgrs.
    ii) The directory is readable, writable and accessible by sysmgrs members, but not by any other user.
       (root has access to all files on the system.)
    iii) Files created in /home/managers automatically have their group owner set to sysmgrs (SGID bit).
    iv) Permissions: 2770

## 7. Configure NTP time synchronization.
    Configure the system as an NTP client using the time server materials.example.com.

## 8. Configure autofs.
    Configure autofs to automatically mount the remote user home directory with the following requirements:
    i) materials.example.com (172.25.254.254) NFS-exports /rhome/remoteuser1 to your system.
    ii) The home directory of remoteuser1 should be automatically mounted on /rhome/remoteuser1.
    iii) The home directory of remoteuser1 should be writable.
    iv) remoteuser1 password is flectrag.

## 9. Create a user account with a specific UID.
    i) Create a user manalo with UID 3533.
    ii) Set the password for manalo to flectrag.

## 10. Find files by ownership.
    Find all files on the system owned by user jacques and copy them to the directory /root/findfiles.

## 11. Find a string in a file.
    Find all lines in the file /usr/share/xml/iso-codes/iso_639_3.xml that contain the string "ng".
    Put a copy of all these lines in the file /root/list.
    The file /root/list must not contain empty lines and the order of the lines must be the same as the original file.

## 12. Create an archive.
    Create a tar archive compressed with bzip2 of the contents of /usr/local.
    Save the archive as /root/backup.tar.bz2.

## 13. Build a Podman image.
    As the user wallah:
    i) Download the Containerfile from http://classroom/Containerfile.
    ii) Build an image named pdf using the downloaded Containerfile.

## 14. Create a Podman systemd service.
    As the user wallah, configure a systemd service for a container with the following requirements:
    i) Container name is ascii2pdf.
    ii) Use the pdf image built in the previous question.
    iii) Mount /opt/file on the host to /dir1 in the container.
    iv) Mount /opt/progress on the host to /dir2 in the container.
    v) The container must automatically start on system reboot without manual intervention.

## 15. Configure sudo access.
    Allow members of the sysmgrs group to use sudo to run any command without being prompted for a password.

## 16. Reset the root password on node2.
    Reset the root password on node2 to flectrag.
    You should be able to access the node2 system using SSH with the new password.
    (Use rd.break or init=/bin/bash kernel boot parameter methods.)

## 17. Configure YUM repositories on node2.
    Configure the same YUM repositories on node2 as configured in Question 2:
    i) Name = BaseOS
       BaseURL = http://content/rhel9.0/x86_64/dvd/BaseOS
       GPG check is disabled.
       Repository is enabled.
    ii) Name = AppStream
        BaseURL = http://content/rhel9.0/x86_64/dvd/Appstream
        GPG check is disabled.
        Repository is enabled.

## 18. Extend a Logical Volume.
    Resize the logical volume vo and its filesystem to 230 MiB.
    i) Make sure the filesystem contents remain intact.
    ii) The acceptable size range is 213 MiB to 243 MiB.

## 19. Add a swap partition.
    Add a swap partition of 512 MiB to the system.
    i) The swap partition must be automatically mounted on boot.
    ii) Do not remove or modify any existing swap partitions.

## 20. Create a Logical Volume.
    Create a new logical volume with the following requirements:
    i) Logical volume name: qa
    ii) Volume group name: qagroup
    iii) Logical volume size: 60 extents
    iv) Physical extent size in the volume group: 16 MiB
    v) Format the logical volume with the vfat file system.
    vi) Mount the logical volume at /mnt/qa automatically on boot.

## 21. Set the recommended tuned profile.
    i) Install the tuned package if not already installed.
    ii) Identify the system's recommended tuned profile.
    iii) Apply and enable the recommended profile as the default.
