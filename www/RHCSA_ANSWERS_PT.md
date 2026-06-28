# RHCSA (EX200) - Respostas

## 1. Configurar as definicoes de rede no node1

Configure o node1 com hostname, endereco IPv4, mascara de sub-rede, gateway e DNS.

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

### Validar

```
hostname
ip a
cat /etc/resolv.conf
```

## 2. Configurar repositorios YUM

Configure os repositorios BaseOS e AppStream no sistema com GPG desativado.

### Criar ficheiro: /etc/yum.repos.d/rhel.repo

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

### Validar

```
dnf repolist -v
```

## 3. Depurar o SELinux

Um servidor web na porta 82 nao consegue servir conteudo. Corrija o contexto SELinux, configure a firewall e ative o servico.

### Verificar e corrigir contexto SELinux

```
# Check current context
ls -Z /var/www/html/

# Fix file context if needed
semanage fcontext -m -t httpd_sys_content_t '/var/www/html(/.*)?'
restorecon -Rv /var/www/html
```

### Adicionar porta ao SELinux

```
semanage port -a -t http_port_t -p tcp 82
```

### Configurar firewall

```
firewall-cmd --permanent --add-port=82/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
```

### Ativar servico

```
systemctl enable --now httpd
```

### Validar

```
curl http://localhost:82
```

## 4. Criar contas de utilizador

Crie o grupo sysmgrs, os utilizadores natasha e harry (com sysmgrs como grupo suplementar), sarah (sem shell interativa), e defina a senha flectrag.

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

### Validar

```
id natasha
id harry
id sarah
```

## 5. Configurar um cron job

Configure um cron job para o utilizador harry que executa diariamente as 14:23 o comando /usr/bin/echo hello.

### Commands

```
systemctl enable --now crond

crontab -u harry -e
# Add the following line:
23 14 * * * /usr/bin/echo hello
```

### Validar

```
crontab -u harry -l
```

## 6. Criar um diretorio colaborativo

Crie /home/managers com grupo proprietario sysmgrs, permissoes 2770 (SGID).

### Commands

```
mkdir /home/managers
chown :sysmgrs /home/managers
chmod 2770 /home/managers
```

### Validar

```
ls -ld /home/managers
# Expected: drwxrws--- 2 root sysmgrs ... /home/managers
```

## 7. Configurar sincronizacao de tempo NTP

Configure o sistema como cliente NTP usando o servidor materials.example.com.

### Editar /etc/chrony.conf

```
# Add the following line to /etc/chrony.conf:
server materials.example.com iburst
```

### Reiniciar servico

```
systemctl enable --now chronyd
systemctl restart chronyd
```

### Validar

```
chronyc sources
```

## 8. Configurar o autofs

Configure o autofs para montar automaticamente /rhome/remoteuser1 via NFS de materials.example.com. O diretorio deve ser gravavel.

### Instalar e ativar

```
dnf -y install autofs
systemctl enable --now autofs
```

### Editar /etc/auto.master

```
# Add the following line to /etc/auto.master:
/rhome /etc/auto.rhome
```

### Criar /etc/auto.rhome

```
remoteuser1 -rw materials.example.com:/rhome/remoteuser1
```

### Reiniciar servico

```
systemctl restart autofs
```

### Validar

```
su - remoteuser1
# Password: flectrag
pwd
# Expected: /rhome/remoteuser1
```

## 9. Criar conta de utilizador com UID especifico

Crie o utilizador manalo com UID 3533 e senha flectrag.

### Commands

```
useradd -u 3533 manalo
echo flectrag | passwd manalo --stdin
```

### Validar

```
id manalo
# Expected: uid=3533(manalo) ...
```

## 10. Encontrar ficheiros por proprietario

Encontre todos os ficheiros pertencentes ao utilizador jacques e copie-os para /root/findfiles.

### Commands

```
mkdir /root/findfiles
find / -user jacques -exec cp -a {} /root/findfiles \;
```

### Validar

```
ls -la /root/findfiles
```

## 11. Encontrar uma string num ficheiro

Encontre todas as linhas contendo "ng" em iso_639_3.xml e salve em /root/list sem linhas vazias.

### Commands

```
grep ng /usr/share/xml/iso-codes/iso_639_3.xml > /root/list
```

### Validar

```
cat /root/list | head
wc -l /root/list
```

## 12. Criar um arquivo compactado

Crie um arquivo tar comprimido com bzip2 do conteudo de /usr/local e salve como /root/backup.tar.bz2.

### Commands

```
tar -cvjf /root/backup.tar.bz2 /usr/local
```

### Validar

```
tar -tf /root/backup.tar.bz2 | head
file /root/backup.tar.bz2
```

## 13. Construir uma imagem Podman

Como utilizador wallah, baixe o Containerfile e construa uma imagem chamada pdf.

### Instalar ferramentas de container

```
dnf -y install container-tools
```

### Construir imagem (como wallah)

```
ssh wallah@node1

wget http://classroom/Containerfile
podman build -t pdf .
```

### Validar

```
podman images
# Should show the pdf image
```

## 14. Criar um servico systemd com Podman

Como wallah, crie o container ascii2pdf usando a imagem pdf, monte /opt/file em /dir1 e /opt/progress em /dir2. O container deve iniciar automaticamente no reboot.

### Preparar diretorios (como root)

```
sudo mkdir /opt/file /opt/progress
sudo chown wallah:wallah /opt/file /opt/progress
```

### Criar e configurar container (como wallah)

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

### Validar

```
# After reboot:
ssh wallah@node1
podman ps
# Should show ascii2pdf running
```

## 15. Configurar acesso sudo

Permita que membros do grupo sysmgrs usem sudo para executar qualquer comando sem senha.

### Commands

```
echo '%sysmgrs ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/sysmgrs-group
```

### Validar

```
su - natasha
sudo cat /etc/shadow
# Should not prompt for password
```

## 16. Recuperar a senha de root no node2

Redefina a senha de root no node2 para flectrag usando rd.break ou init=/bin/bash.

### Metodo rd.break

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

### Metodo alternativo: init=/bin/bash

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

### Validar

```
ssh root@node2
# Password: flectrag
```

## 17. Configurar repositorios YUM no node2

Configure os mesmos repositorios YUM no node2 conforme a Questao 2.

### Copiar do node1 ou criar manualmente

```
# Option 1: Copy from node1
scp /etc/yum.repos.d/rhel.repo root@node2:/etc/yum.repos.d/

# Option 2: Create manually on node2 (same as Question 2)
```

### Conteudo: /etc/yum.repos.d/rhel.repo

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

### Validar

```
dnf repolist -v
```

## 18. Expandir um Volume Logico

Redimensione o volume logico vo e o seu sistema de ficheiros para 230 MiB (aceitavel: 213-243 MiB). O conteudo deve permanecer intacto.

### Verificar estado atual

```
lvs
df -h
blkid /dev/myvol/vo
```

### Redimensionar (ext4)

```
# For ext4 filesystem:
lvextend -L 230M /dev/myvol/vo
resize2fs /dev/myvol/vo
```

### Redimensionar (xfs)

```
# For xfs filesystem:
lvextend -L 230M /dev/myvol/vo
xfs_growfs /dev/myvol/vo
```

### Validar

```
lvs
df -h
```

## 19. Adicionar uma particao swap

Adicione uma particao swap de 512 MiB ao sistema. Deve ser montada automaticamente no arranque sem remover swap existente.

### Criar particao

```
# Check existing partitions
parted /dev/vdb unit mib print

# Create swap partition (adjust start/end based on free space)
parted /dev/vdb mkpart my-swap linux-swap 722MiB 1234MiB
```

### Formatar e ativar

```
mkswap /dev/vdb3
```

### Adicionar ao /etc/fstab

```
# Add to /etc/fstab:
/dev/vdb3 swap swap defaults 0 0
```

### Ativar

```
systemctl daemon-reload
swapon -a
```

### Validar

```
swapon --show
free -m
```

## 20. Criar um Volume Logico

Crie o LV qa no VG qagroup com 60 extents (PE 16 MiB), formate com vfat e monte em /mnt/qa automaticamente.

### Criar particao e VG

```
# Create partition (adjust based on available space)
parted /dev/vdb mkpart primary 1235MiB 2500MiB

pvcreate /dev/vdb4
vgcreate -s 16M qagroup /dev/vdb4
```

### Criar LV e formatar

```
lvcreate -n qa -l 60 qagroup
mkfs.vfat /dev/qagroup/qa
```

### Montar

```
mkdir /mnt/qa

# Add to /etc/fstab:
/dev/qagroup/qa /mnt/qa vfat defaults 0 0

systemctl daemon-reload
mount /mnt/qa
```

### Validar

```
mount | grep /mnt/qa
lvs
# LV qa should be 60 extents * 16 MiB = 960 MiB
```

## 21. Definir o perfil tuned recomendado

Instale o tuned, identifique o perfil recomendado pelo sistema e aplique-o.

### Commands

```
dnf install -y tuned
systemctl enable --now tuned

tuned-adm recommend
# Note the recommended profile (e.g., virtual-guest)

tuned-adm profile virtual-guest
```

### Validar

```
tuned-adm active
# Should show: Current active profile: virtual-guest
```
