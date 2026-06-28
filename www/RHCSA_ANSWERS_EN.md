# RHCSA (EX200) - Answers

## 1. Configure network settings on node1

Configure node1 with hostname, IPv4 address, subnet mask, gateway and DNS.

### Commands

```
hostnamectl set-hostname node1.domain250.example.com

nmcli con show
nmcli con modify 'Wired connection 1' autoconnect yes \
  ipv4.method manual \
  ipv4.addresses 172.25.250.100/24 \
  ipv4.gateway 172.25.250.254 \
  ipv4.dns 172.25.250.254

nmcli con up 'Wired connection 1'
```

### Validate

```
hostname
ip a
cat /etc/resolv.conf
```

## 2. Configure YUM repositories

Configure BaseOS and AppStream repositories on the system with GPG disabled.

### Create file: /etc/yum.repos.d/rhel.repo

```
[BaseOS]
name = BaseOS
baseurl = http://content/rhel9.0/x86_64/dvd/BaseOS
enabled = 1
gpgcheck = 0

[Appstream]
name = Appstream
baseurl = http://content/rhel9.0/x86_64/dvd/Appstream
enabled = 1
gpgcheck = 0
```

### Validate

```
dnf repolist -v
```

## 3. Debug SELinux

A web server on port 82 cannot serve content. Fix the SELinux context, configure the firewall and enable the service.

### Check and fix SELinux context

```
# Check current context
ls -Z /var/www/html/

# Fix file context if needed
semanage fcontext -m -t httpd_sys_content_t '/var/www/html(/.*)?'
restorecon -Rv /var/www/html
```

### Add port to SELinux

```
semanage port -a -t http_port_t -p tcp 82
```

### Configure firewall

```
firewall-cmd --permanent --add-port=82/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

### Enable service

```
systemctl enable --now httpd
```

### Validate

```
curl http://localhost:82
```

## 4. Create user accounts

Create group sysmgrs, users natasha and harry (with sysmgrs as supplementary group), sarah (no interactive shell), and set password flectrag.

### Commands

```
groupadd sysmgrs
useradd -G sysmgrs natasha
useradd -G sysmgrs harry
useradd -s /usr/sbin/nologin sarah

echo flectrag | passwd natasha --stdin
echo flectrag | passwd harry --stdin
echo flectrag | passwd sarah --stdin
```

### Validate

```
id natasha
id harry
id sarah
```

## 5. Configure a cron job

Configure a cron job for user harry that runs daily at 14:23 executing /usr/bin/echo hello.

### Commands

```
systemctl enable --now crond

crontab -u harry -e
# Add the following line:
23 14 * * * /usr/bin/echo hello
```

### Validate

```
crontab -u harry -l
```

## 6. Create a collaborative directory

Create /home/managers with group owner sysmgrs, permissions 2770 (SGID).

### Commands

```
mkdir /home/managers
chown :sysmgrs /home/managers
chmod 2770 /home/managers
```

### Validate

```
ls -ld /home/managers
# Expected: drwxrws--- 2 root sysmgrs ... /home/managers
```

## 7. Configure NTP time synchronization

Configure the system as an NTP client using the time server materials.example.com.

### Edit /etc/chrony.conf

```
# Add the following line to /etc/chrony.conf:
server materials.example.com iburst
```

### Restart service

```
systemctl enable --now chronyd
systemctl restart chronyd
```

### Validate

```
chronyc sources
```

## 8. Configure autofs

Configure autofs to automatically mount /rhome/remoteuser1 via NFS from materials.example.com. The directory should be writable.

### Install and enable

```
dnf -y install autofs
systemctl enable --now autofs
```

### Edit /etc/auto.master

```
# Add the following line to /etc/auto.master:
/rhome /etc/auto.rhome
```

### Create /etc/auto.rhome

```
remoteuser1 -rw materials.example.com:/rhome/remoteuser1
```

### Restart service

```
systemctl restart autofs
```

### Validate

```
su - remoteuser1
# Password: flectrag
pwd
# Expected: /rhome/remoteuser1
```

## 9. Create user account with specific UID

Create user manalo with UID 3533 and password flectrag.

### Commands

```
useradd -u 3533 manalo
echo flectrag | passwd manalo --stdin
```

### Validate

```
id manalo
# Expected: uid=3533(manalo) ...
```

## 10. Find files by ownership

Find all files owned by user jacques and copy them to /root/findfiles.

### Commands

```
mkdir /root/findfiles
find / -user jacques -exec cp -a {} /root/findfiles \;
```

### Validate

```
ls -la /root/findfiles
```

## 11. Find a string in a file

Find all lines containing "ng" in iso_639_3.xml and save to /root/list without empty lines.

### Commands

```
grep ng /usr/share/xml/iso-codes/iso_639_3.xml > /root/list
```

### Validate

```
cat /root/list | head
wc -l /root/list
```

## 12. Create an archive

Create a tar archive compressed with bzip2 of /usr/local contents and save as /root/backup.tar.bz2.

### Commands

```
tar -cvjf /root/backup.tar.bz2 /usr/local
```

### Validate

```
tar -tf /root/backup.tar.bz2 | head
file /root/backup.tar.bz2
```

## 13. Build a Podman image

As user wallah, download the Containerfile and build an image named pdf.

### Install container tools

```
dnf -y install container-tools
```

### Build image (as wallah)

```
ssh wallah@node1

wget http://classroom/Containerfile
podman build -t pdf .
```

### Validate

```
podman images
# Should show the pdf image
```

## 14. Create a Podman systemd service

As wallah, create container ascii2pdf using the pdf image, mount /opt/file to /dir1 and /opt/progress to /dir2. The container must auto-start on reboot.

### Prepare directories (as root)

```
sudo mkdir /opt/file /opt/progress
sudo chown wallah:wallah /opt/file /opt/progress
```

### Create and configure container (as wallah)

```
podman run -d --name ascii2pdf \
  -v /opt/file:/dir1:Z \
  -v /opt/progress:/dir2:Z \
  pdf

podman generate systemd -n ascii2pdf -f --new
mkdir -p ~/.config/systemd/user
mv ~/container-ascii2pdf.service ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now container-ascii2pdf
loginctl enable-linger
```

### Validate

```
# After reboot:
ssh wallah@node1
podman ps
# Should show ascii2pdf running
```

## 15. Configure sudo access

Allow members of sysmgrs group to use sudo to run any command without a password.

### Commands

```
echo '%sysmgrs ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/sysmgrs-group
```

### Validate

```
su - natasha
sudo cat /etc/shadow
# Should not prompt for password
```

## 16. Reset root password on node2

Reset the root password on node2 to flectrag using rd.break or init=/bin/bash.

### Method rd.break

```
# 1. Reboot node2 and press 'e' at the GRUB menu
# 2. Find the line starting with 'linux' and append:
rd.break
# 3. Press Ctrl+x to boot

# 4. Once in emergency mode:
mount -o remount,rw /sysroot
chroot /sysroot
echo flectrag | passwd root --stdin
touch /.autorelabel
exit
exit
# System will reboot automatically
```

### Alternative method: init=/bin/bash

```
# 1. Reboot node2 and press 'e' at the GRUB menu
# 2. Find the line starting with 'linux' and replace 'ro' with:
rw init=/bin/bash
# 3. Press Ctrl+x to boot

# 4. Once at the bash prompt:
echo flectrag | passwd root --stdin
touch /.autorelabel
exec /usr/lib/systemd/systemd
```

### Validate

```
ssh root@node2
# Password: flectrag
```

## 17. Configure YUM repositories on node2

Configure the same YUM repositories on node2 as in Question 2.

### Copy from node1 or create manually

```
# Option 1: Copy from node1
scp /etc/yum.repos.d/rhel.repo root@node2:/etc/yum.repos.d/

# Option 2: Create manually on node2 (same as Question 2)
```

### Content: /etc/yum.repos.d/rhel.repo

```
[BaseOS]
name = BaseOS
baseurl = http://content/rhel9.0/x86_64/dvd/BaseOS
enabled = 1
gpgcheck = 0

[Appstream]
name = Appstream
baseurl = http://content/rhel9.0/x86_64/dvd/Appstream
enabled = 1
gpgcheck = 0
```

### Validate

```
dnf repolist -v
```

## 18. Extend a Logical Volume

Resize the logical volume vo and its filesystem to 230 MiB (acceptable: 213-243 MiB). Contents must remain intact.

### Check current state

```
lvs
df -h
blkid /dev/myvol/vo
```

### Resize (ext4)

```
# For ext4 filesystem:
lvextend -L 230M /dev/myvol/vo
resize2fs /dev/myvol/vo
```

### Resize (xfs)

```
# For xfs filesystem:
lvextend -L 230M /dev/myvol/vo
xfs_growfs /dev/myvol/vo
```

### Validate

```
lvs
df -h
```

## 19. Add a swap partition

Add a 512 MiB swap partition to the system. It must mount automatically on boot without removing existing swap.

### Create partition

```
# Check existing partitions
parted /dev/vdb unit mib print

# Create swap partition (adjust start/end based on free space)
parted /dev/vdb mkpart my-swap linux-swap 722MiB 1234MiB
```

### Format and enable

```
mkswap /dev/vdb3
```

### Add to /etc/fstab

```
# Add to /etc/fstab:
/dev/vdb3 swap swap defaults 0 0
```

### Activate

```
systemctl daemon-reload
swapon -a
```

### Validate

```
swapon --show
free -m
```

## 20. Create a Logical Volume

Create LV qa in VG qagroup with 60 extents (PE 16 MiB), format with vfat and mount on /mnt/qa automatically.

### Create partition and VG

```
# Create partition (adjust based on available space)
parted /dev/vdb mkpart primary 1235MiB 2500MiB

pvcreate /dev/vdb4
vgcreate -s 16M qagroup /dev/vdb4
```

### Create LV and format

```
lvcreate -n qa -l 60 qagroup
mkfs.vfat /dev/qagroup/qa
```

### Mount

```
mkdir /mnt/qa

# Add to /etc/fstab:
/dev/qagroup/qa /mnt/qa vfat defaults 0 0

systemctl daemon-reload
mount /mnt/qa
```

### Validate

```
mount | grep /mnt/qa
lvs
# LV qa should be 60 extents * 16 MiB = 960 MiB
```

## 21. Set the recommended tuned profile

Install tuned, identify the system recommended profile and apply it.

### Commands

```
dnf install -y tuned
systemctl enable --now tuned

tuned-adm recommend
# Note the recommended profile (e.g., virtual-guest)

tuned-adm profile virtual-guest
```

### Validate

```
tuned-adm active
# Should show: Current active profile: virtual-guest
```
