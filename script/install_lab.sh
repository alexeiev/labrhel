#!/usr/bin/env bash

# Preparando ambiente para o laboratório de RHEL 9
# Autor: Alexeiev
# Data: 2026-05-10

DIR_PROJECT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
DIR_MATERIALS=/var/www/html/repos/materials
DIR_LABRHEL=/var/www/html/labrhel
DIR_LAB_ASSETS=/var/lib/lab-ex294
DIR_CONFS=${DIR_PROJECT}/confs
HOSTS_FILE=${DIR_CONFS}/hosts
DIR_WWW=${DIR_PROJECT}/www
BIN_SCRIPTS=${DIR_PROJECT}/script
BIN_REPO=${BIN_SCRIPTS}/create_repo_ex294.sh

EE_IMAGE_URL=https://github.com/alexeiev/labrhel/releases/download/lab-assets-v1/ee-supported-rhel8.tar.gz
EE_IMAGE_GZIP=${DIR_LAB_ASSETS}/ee-supported-rhel8.tar.gz
EE_IMAGE_ARCHIVE=${DIR_LAB_ASSETS}/ee-supported-rhel8.tar
EE_IMAGE_GZIP_SHA256=5bc1217cfd78629305c6a10f3f7479dba337a20f5b99ea249c12ed87acba3928
EE_IMAGE_TAR_SHA256=8d4936606853fd4101abbc5719550f06d6a1b286cd357854f560c89a718d5da7
EE_IMAGE_ID=sha256:98963ebb0b830f2fe63ce44f31de51fcd1599d445bbb01c10d95f91e334f87ff
EE_IMAGE_NAME=registry.redhat.io/ansible-automation-platform-24/ee-supported-rhel8:latest

DEV_TOOLS_IMAGE_URL=https://github.com/alexeiev/labrhel/releases/download/lab-assets-v1/ansible-dev-tools-rhel8.tar.gz
DEV_TOOLS_IMAGE_GZIP=${DIR_LAB_ASSETS}/ansible-dev-tools-rhel8.tar.gz
DEV_TOOLS_IMAGE_ARCHIVE=${DIR_LAB_ASSETS}/ansible-dev-tools-rhel8.tar
DEV_TOOLS_IMAGE_GZIP_SHA256=a2a70dc17b9e2951e1886738dab3129ffb82362fe167c1928e3809b969cb4fdc
DEV_TOOLS_IMAGE_TAR_SHA256=8cbc5edb7de0281336f153c4fd326de62ebf0f755bc0a162945710e413e009d7
DEV_TOOLS_IMAGE_ID=sha256:d4d4c4fa7e89bf5d9f3ad03343f340b7903c698772f13b81f42801245f993835
DEV_TOOLS_IMAGE_NAME=registry.redhat.io/ansible-automation-platform-25/ansible-dev-tools-rhel8:latest

STUDENT_PASSWORD=${STUDENT_PASSWORD:-student}
DEVOPS_PASSWORD=${DEVOPS_PASSWORD:-redhat}
GREG_PASSWORD=${GREG_PASSWORD:-redhat}
LAB_PROXMOX_HOST=${PROXMOX_HOST:-SEU_HOST_PROXMOX}
LAB_PROXMOX_API_USER=${PROXMOX_API_USER:-lab-rhel@pve!secret}
LAB_PROXMOX_TOKEN_SECRET=${PROXMOX_TOKEN_SECRET:-SEU_SECRET}

ensure_user() {
    local username=$1
    local uid=$2
    local password=$3
    local grant_sudo=${4:-no}

    if id -u "$username" >/dev/null 2>&1; then
        echo "Usuário ${username} já existe."
    else
        echo "Criando usuário ${username}..."
        useradd --create-home --shell /bin/bash --uid "$uid" "$username"
        echo "${username}:${password}" | chpasswd
    fi

    if [ "$grant_sudo" = yes ]; then
        printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$username" > "/etc/sudoers.d/${username}"
        chmod 0440 "/etc/sudoers.d/${username}"
        visudo -cf "/etc/sudoers.d/${username}" >/dev/null
    fi
}

ensure_gnome() {
    if rpm -q gnome-shell gdm >/dev/null 2>&1; then
        echo "GNOME já está instalado."
    else
        echo "GNOME não encontrado. Instalando o ambiente Server with GUI..."
        if ! dnf group install -y "Server with GUI"; then
            echo "ERRO: Não foi possível instalar o ambiente gráfico GNOME."
            return 1
        fi
    fi

    systemctl set-default graphical.target
    systemctl enable gdm
}

install_vscode() {
    if rpm -q code >/dev/null 2>&1; then
        echo "Visual Studio Code já está instalado."
        return 0
    fi

    echo "Configurando o repositório oficial do Visual Studio Code..."
    if ! rpm --import https://packages.microsoft.com/keys/microsoft.asc; then
        echo "ERRO: Não foi possível importar a chave do repositório do VS Code."
        return 1
    fi

    cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    echo "Instalando o Visual Studio Code..."
    if ! dnf install -y code; then
        echo "ERRO: Não foi possível instalar o Visual Studio Code."
        return 1
    fi
}

configure_student_desktop() {
    local user_home
    local user_group
    local desktop_dir
    local icon_dir
    local desktop_file

    user_home=$(getent passwd student | cut -d: -f6)
    user_group=$(id -gn student)
    desktop_dir=${user_home}/Desktop
    icon_dir=${user_home}/.local/share/icons

    echo "Instalando os atalhos no desktop do usuário student..."
    install -d -m 0755 -o student -g "$user_group" \
        "$desktop_dir" "$icon_dir"
    install -m 0644 -o student -g "$user_group" \
        "${DIR_CONFS}/desktop/redhat.png" "${icon_dir}/redhat.png"

    for desktop_file in "${DIR_CONFS}/desktop/"*.desktop; do
        [ -e "$desktop_file" ] || continue
        install -m 0755 -o student -g "$user_group" \
            "$desktop_file" "$desktop_dir/$(basename "$desktop_file")"

        if command -v dbus-run-session >/dev/null 2>&1 && \
           command -v gio >/dev/null 2>&1; then
            runuser -u student -- dbus-run-session -- \
                gio set "$desktop_dir/$(basename "$desktop_file")" \
                metadata::trusted true >/dev/null 2>&1 || true
        fi
    done

    restorecon -RF "$desktop_dir" "$icon_dir"
}

install_lab_cli() {
    echo "Instalando o utilitário lab-ex294..."
    install -m 0755 "${BIN_SCRIPTS}/lab-ex294" /usr/local/bin/lab-ex294
    install -d -m 0755 /etc/bash_completion.d
    install -m 0644 \
        "${DIR_CONFS}/bash_completion.d/lab-ex294_completion" \
        /etc/bash_completion.d/lab-ex294
}

configure_lab_cli_user() {
    local username=$1
    local user_home
    local user_group
    local config_dir
    local env_file
    local bashrc_file

    user_home=$(getent passwd "$username" | cut -d: -f6)
    user_group=$(id -gn "$username")
    config_dir=${user_home}/.config/lab-ex294
    env_file=${config_dir}/env
    bashrc_file=${user_home}/.bashrc

    install -d -m 0700 -o "$username" -g "$user_group" "$config_dir"

    if [ ! -f "$env_file" ]; then
        install -m 0600 -o "$username" -g "$user_group" \
            /dev/null "$env_file"
    fi

    chown "$username:$user_group" "$env_file"
    chmod 0600 "$env_file"

    if ! grep -q '^export PROXMOX_HOST=' "$env_file"; then
        printf "export PROXMOX_HOST='%s'\n" \
            "$LAB_PROXMOX_HOST" >> "$env_file"
    fi

    if ! grep -q '^export PROXMOX_API_USER=' "$env_file"; then
        printf "export PROXMOX_API_USER='%s'\n" \
            "$LAB_PROXMOX_API_USER" >> "$env_file"
    fi

    if ! grep -q '^export PROXMOX_TOKEN_SECRET=' "$env_file"; then
        printf "export PROXMOX_TOKEN_SECRET='%s'\n" \
            "$LAB_PROXMOX_TOKEN_SECRET" >> "$env_file"
    fi

    if ! grep -q '^# EX294 Lab Helper$' "$bashrc_file" 2>/dev/null; then
        cat >> "$bashrc_file" <<'EOF'

if [ -f "$HOME/.config/lab-ex294/env" ]; then
    source "$HOME/.config/lab-ex294/env"
fi

# EX294 Lab Helper
printf '\n'
printf '============================================================\n'
printf '                  RED HAT EX294 LAB\n'
printf '============================================================\n'
printf '\n'
printf ' Para iniciar ou restaurar o laboratório, utilize:\n'
printf '\n'
printf '     lab-ex294 start\n'
printf '\n'
printf ' Para finalizar o laboratório e restaurar as VMs:\n'
printf '\n'
printf '     lab-ex294 finish\n'
printf '\n'
printf ' Para mais informações:\n'
printf '\n'
printf '     lab-ex294 help\n'
printf '\n'
printf '============================================================\n'
printf '\n'
EOF
    fi

    chown "$username:$user_group" "$bashrc_file"
}

create_greg_ssh_key() {
    local ssh_dir=/home/greg/.ssh
    local private_key=${ssh_dir}/id_rsa

    install -d -m 0700 -o greg -g greg "$ssh_dir"

    if [ ! -f "$private_key" ]; then
        echo "Criando chave SSH para o usuário greg..."
        su - greg -c "ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ''"
    fi

    echo "Chave pública SSH do usuário greg:"
    echo "Copie esta chave para os managed nodes para permitir acesso sem senha:"
    cat "${private_key}.pub"
}

download_container_image() {
    local image_description=$1
    local image_url=$2
    local image_gzip=$3
    local image_archive=$4
    local gzip_sha256=$5
    local tar_sha256=$6
    local gzip_tmp=${image_gzip}.part
    local tar_tmp=${image_archive}.part

    install -d -m 0755 "$DIR_LAB_ASSETS"

    if [ -f "$image_archive" ] && \
       echo "${tar_sha256}  ${image_archive}" | \
           sha256sum --check --status; then
        echo "Archive íntegro já disponível: ${image_description}."
        chmod 0644 "$image_archive"
        return 0
    fi

    if [ ! -f "$image_gzip" ] || \
       ! echo "${gzip_sha256}  ${image_gzip}" | \
           sha256sum --check --status; then
        echo "Baixando imagem compactada: ${image_description}..."
        if ! curl --fail --location --retry 3 --retry-delay 5 \
            --output "$gzip_tmp" "$image_url"; then
            echo "ERRO: Não foi possível baixar ${image_description}."
            return 1
        fi

        if ! echo "${gzip_sha256}  ${gzip_tmp}" | \
            sha256sum --check --status; then
            echo "ERRO: O checksum do arquivo compactado é inválido."
            rm -f "$gzip_tmp"
            return 1
        fi

        mv -f "$gzip_tmp" "$image_gzip"
    fi

    echo "Descompactando ${image_gzip}..."
    if ! gzip --decompress --stdout "$image_gzip" > "$tar_tmp"; then
        echo "ERRO: Não foi possível descompactar ${image_description}."
        rm -f "$tar_tmp"
        return 1
    fi

    if ! echo "${tar_sha256}  ${tar_tmp}" | \
        sha256sum --check --status; then
        echo "ERRO: O checksum do archive descompactado é inválido."
        rm -f "$tar_tmp"
        return 1
    fi

    mv -f "$tar_tmp" "$image_archive"
    chmod 0644 "$image_archive"
    rm -f "$image_gzip"
}

import_container_image() {
    local image_description=$1
    local image_archive=$2
    local image_id=$3
    local image_name=$4
    local podman_user=$5
    local load_output

    if su - "$podman_user" -c "podman image exists '${image_name}'"; then
        echo "Imagem já importada para ${podman_user}: ${image_description}."
        return 0
    fi

    echo "Importando ${image_description} no Podman de ${podman_user}..."
    if ! load_output=$(su - "$podman_user" -c \
        "podman load --input '${image_archive}'" 2>&1); then
        echo "$load_output"
        echo "ERRO: Não foi possível importar ${image_description} no Podman."
        return 1
    fi
    echo "$load_output"

    if ! su - "$podman_user" -c "podman image exists '${image_id}'"; then
        echo "ERRO: A imagem importada não possui o ID esperado ${image_id}."
        return 1
    fi

    if ! su - "$podman_user" -c "podman tag '${image_id}' '${image_name}'"; then
        echo "ERRO: Não foi possível aplicar a tag ${image_name}."
        return 1
    fi

    echo "Imagem disponível para ${podman_user} como ${image_name}."
}

if [ "$EUID" -ne 0 ]; then
    echo "ERRO: Este script deve ser executado como root."
    exit 1
fi

if ! subscription-manager repos >/dev/null 2>&1; then
    echo "ERRO: O sistema não está registrado ou não tem uma subscrição ativa."
    echo "      Use 'subscription-manager register --username <username>' para registrar o sistema."
    exit 1
fi

IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Endereço IP do host Workstation: $IP_ADDRESS"

if grep -q '^IP' "$HOSTS_FILE"; then
    echo "Por favor, atualize $HOSTS_FILE com os endereços IP corretos."
    exit 1
else
    echo "Configurando o hostname..."
    hostnamectl set-hostname workstation

    echo "Copiando o arquivo de hosts para /etc..."
    cp -f "$HOSTS_FILE" /etc/hosts
    restorecon -F /etc/hosts
fi



echo "Atualizando o sistema..."
dnf update -y

echo "Instalando pacotes necessários..."
dnf install -y \
    httpd \
    bash-completion \
    ansible-core \
    zstd \
    gzip \
    createrepo_c \
    dnf-plugins-core \
    curl \
    podman \
    firefox \
    gnome-terminal \
    python3-requests \
    policycoreutils-python-utils \
    firewalld \
    sudo
dnf install -y \
    --enablerepo=ansible-automation-platform-2.4-for-rhel-9-x86_64-rpms \
    ansible-navigator

if ! ensure_gnome; then
    exit 1
fi

if ! install_vscode; then
    exit 1
fi

echo "Criando diretórios para repositórios e laboratório..."
install -d -m 0755 "$DIR_MATERIALS" "$DIR_LABRHEL" "$DIR_LAB_ASSETS"

echo "Copiando arquivos de configuração do Apache..."
cp -f "${DIR_CONFS}/httpd/"* /etc/httpd/conf.d/
restorecon -RF /etc/httpd/conf.d/

echo "Copiando a aplicação web do laboratório..."
cp -rf "${DIR_WWW}/"* "$DIR_LABRHEL/"

echo "Copiando materiais do laboratório..."
find "${DIR_CONFS}/materials" -maxdepth 1 -type f \
    ! -name 'ee-supported-rhel8.tar.gz' \
    ! -name 'ansible-dev-tools-rhel8.tar.gz' \
    -exec cp -f {} "$DIR_MATERIALS/" \;
restorecon -RF "$DIR_MATERIALS"

ensure_user student 1005 "$STUDENT_PASSWORD" yes
ensure_user devops 1010 "$DEVOPS_PASSWORD" yes
ensure_user greg 1011 "$GREG_PASSWORD" yes

create_greg_ssh_key

echo "Criando diretório do Ansible no home de greg..."
install -d -m 0755 -o greg -g greg /home/greg/ansible
cp -rf "${DIR_CONFS}/ansible/"* /home/greg/ansible/
chown -R greg:greg /home/greg/ansible
restorecon -RF /home/greg/ansible/

loginctl enable-linger greg
loginctl enable-linger student

install_lab_cli
configure_lab_cli_user student
configure_student_desktop

if ! download_container_image \
    "execution environment" \
    "$EE_IMAGE_URL" \
    "$EE_IMAGE_GZIP" \
    "$EE_IMAGE_ARCHIVE" \
    "$EE_IMAGE_GZIP_SHA256" \
    "$EE_IMAGE_TAR_SHA256"; then
    exit 1
fi

if ! download_container_image \
    "Ansible Development Tools" \
    "$DEV_TOOLS_IMAGE_URL" \
    "$DEV_TOOLS_IMAGE_GZIP" \
    "$DEV_TOOLS_IMAGE_ARCHIVE" \
    "$DEV_TOOLS_IMAGE_GZIP_SHA256" \
    "$DEV_TOOLS_IMAGE_TAR_SHA256"; then
    exit 1
fi

echo "Configurando o firewall para permitir tráfego HTTP..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

echo "Configurando repositórios para o laboratório..."
bash "$BIN_REPO"

echo "Configurando contextos SELinux para o Apache..."
semanage fcontext -a -t httpd_sys_content_t "${DIR_LABRHEL}(/.*)?" 2>/dev/null || \
    semanage fcontext -m -t httpd_sys_content_t "${DIR_LABRHEL}(/.*)?"
semanage fcontext -a -t httpd_sys_content_t "${DIR_MATERIALS}(/.*)?" 2>/dev/null || \
    semanage fcontext -m -t httpd_sys_content_t "${DIR_MATERIALS}(/.*)?"
restorecon -RF "$DIR_LABRHEL" "$DIR_MATERIALS"

echo "Iniciando e habilitando o Apache..."
systemctl enable --now httpd

if ! import_container_image \
    "execution environment" \
    "$EE_IMAGE_ARCHIVE" \
    "$EE_IMAGE_ID" \
    "$EE_IMAGE_NAME" \
    greg; then
    exit 1
fi

if ! import_container_image \
    "Ansible Development Tools" \
    "$DEV_TOOLS_IMAGE_ARCHIVE" \
    "$DEV_TOOLS_IMAGE_ID" \
    "$DEV_TOOLS_IMAGE_NAME" \
    greg; then
    exit 1
fi

echo "Configuração do laboratório de RHEL 9 concluída com sucesso!"
echo "Acesse o laboratório em http://exam.example.com/"
echo "Copie $HOSTS_FILE para os managed nodes."

if [ "$LAB_PROXMOX_HOST" = SEU_HOST_PROXMOX ] || \
   [ "$LAB_PROXMOX_TOKEN_SECRET" = SEU_SECRET ]; then
    echo "AVISO: configure /home/student/.config/lab-ex294/env."
fi
