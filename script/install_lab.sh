#!/usr/bin/env bash

# Preparando ambiente para o laboratório de RHEL 9
# Autor: Alexeiev
# Data: 2026-05-10


DIR_MATERIALS=/var/www/html/repos/materials
DIR_LABRHEL=/var/www/html/labrhel
DIR_CONFS=./confs
HOSTS_FILE=${DIR_CONFS}/hosts
DIR_WWW=./www
BIN_SCRIPTS=./script
BIN_REPO=${BIN_SCRIPTS}/create_ex294_repo.sh
EE_IMAGE_URL=https://github.com/alexeiev/labrhel/releases/download/lab-assets-v1/ee-supported-rhel8.tar.gz
EE_IMAGE_ARCHIVE=${DIR_MATERIALS}/ee-supported-rhel8.tar.gz
EE_IMAGE_SHA256=5bc1217cfd78629305c6a10f3f7479dba337a20f5b99ea249c12ed87acba3928
EE_IMAGE_ID=sha256:98963ebb0b830f2fe63ce44f31de51fcd1599d445bbb01c10d95f91e334f87ff
EE_IMAGE_NAME=registry.redhat.io/ansible-automation-platform-24/ee-supported-rhel8:latest

download_execution_environment() {
    local download_tmp="${EE_IMAGE_ARCHIVE}.part"

    if [ -f "$EE_IMAGE_ARCHIVE" ] && \
       echo "${EE_IMAGE_SHA256}  ${EE_IMAGE_ARCHIVE}" | sha256sum --check --status; then
        echo "Imagem do execution environment já está disponível e íntegra."
        return 0
    fi

    echo "Baixando imagem do execution environment..."
    if ! curl --fail --location --retry 3 --retry-delay 5 \
        --output "$download_tmp" "$EE_IMAGE_URL"; then
        echo "ERRO: Não foi possível baixar a imagem do execution environment."
        return 1
    fi

    if ! echo "${EE_IMAGE_SHA256}  ${download_tmp}" | sha256sum --check --status; then
        echo "ERRO: O checksum da imagem baixada é inválido."
        return 1
    fi

    mv -f "$download_tmp" "$EE_IMAGE_ARCHIVE"
    chmod 0644 "$EE_IMAGE_ARCHIVE"
}

import_execution_environment() {
    local load_output

    if su - admin -c "podman image exists '${EE_IMAGE_NAME}'"; then
        echo "Imagem do execution environment já está importada."
        return 0
    fi

    echo "Importando imagem do execution environment no Podman do usuário admin..."
    if ! load_output=$(su - admin -c "podman load --input '${EE_IMAGE_ARCHIVE}'" 2>&1); then
        echo "$load_output"
        echo "ERRO: Não foi possível importar a imagem no Podman."
        return 1
    fi
    echo "$load_output"

    if ! su - admin -c "podman image exists '${EE_IMAGE_ID}'"; then
        echo "ERRO: A imagem importada não possui o ID esperado ${EE_IMAGE_ID}."
        return 1
    fi

    if ! su - admin -c "podman tag '${EE_IMAGE_ID}' '${EE_IMAGE_NAME}'"; then
        echo "ERRO: Não foi possível aplicar a tag ${EE_IMAGE_NAME}."
        return 1
    fi

    echo "Imagem disponível como ${EE_IMAGE_NAME}."
}

# Verificar se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    echo "ERRO: Este script deve ser executado como root."
    exit 1
fi

# Validar se temos subscrição ativa
if ! subscription-manager status &>/dev/null; then
    echo "ERRO: O sistema não está registrado ou não tem uma subscrição ativa."
    echo "      Use 'subscription-manager register --username <username>' para registrar o sistema."
    exit 1
fi

# Coletar o endereço ip do host
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "Endereço IP do host Workstation: $IP_ADDRESS"

# Validar se os IPs foram modificados no ficheiro de hosts.
if grep -q "^IP" "$HOSTS_FILE"; then
    echo "      Por favor, atualize o arquivo de hosts com o endereço IP correto da Workstation e dos outros nodes."
    echo "      Edite o arquivo $HOSTS_FILE e substitua 'IP' pelo endereço IP do host Workstation."
    exit 1
fi

#Configurar o hostname
echo "Configurando o hostname..."
hostnamectl set-hostname workstation
#Copiar o arquivo de hosts para o diretório /etc
echo "Copiando o arquivo de hosts para o diretório /etc..."
cp -f $HOSTS_FILE /etc/hosts
restorecon -R /etc/hosts

# Update do sistema
echo "Atualizando o sistema..."
dnf update -y

# install packages
echo "Instalando pacotes necessários..."
dnf install -y httpd bash-completion ansible-core zstd createrepo_c curl podman
dnf install -y --enablerepo=ansible-automation-platform-2.4-for-rhel-9-x86_64-rpms ansible-navigator

# Criar diretórios para repositórios e laboratório
echo "Criando diretórios para repositórios e laboratório..."
mkdir -p $DIR_MATERIALS
mkdir -p $DIR_LABRHEL

# Copiar repositórios para o diretório do Apache
echo "Copiando Arquivos de configuração do Apache..."
cp -r ${DIR_CONFS}/httpd/* /etc/httpd/conf.d/
restorecon -R /etc/httpd/conf.d/

echo "Copiando repositórios para o diretório do Apache..."
cp -r ${DIR_WWW}/* ${DIR_LABRHEL}/

# Copiar arquivos de materials para o diretório do Apache
echo "Copiando arquivos de materials para o diretório do Apache..."
cp -r ${DIR_CONFS}/materials/* ${DIR_MATERIALS}/
restorecon -R ${DIR_MATERIALS}/

if ! download_execution_environment; then
    exit 1
fi

# Criar usuário admin
echo "Criando usuário admin..."
useradd admin -m -s /bin/bash --uid 1010
echo "admin:redhat" | chpasswd
echo "Adicionando usuário admin ao grupo wheel..."
echo "admin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/admin

# criar chave SSH para o usuário admin
echo "Criando chave SSH para o usuário admin..."
su - admin -c "ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ''"
# Exibir a chave pública para o usuário admin
echo "Chave pública SSH para o usuário admin:"
echo "Copiar essa chave para os outros nodes para permitir acesso sem senha:"
cat /home/admin/.ssh/id_rsa.pub

# Configurar o firewall para permitir o tráfego HTTP
echo "Configurando o firewall para permitir o tráfego HTTP..."
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Configurar o /etc/hosts da maquina do usuário
echo "Configurando o arquivo /etc/hosts para o seu computador. Adicione a seguinte entrada."
echo -e "${IP_ADDRESS} exam.example.com\n"

# Configurar repositórios para o laboratório
echo "Configurando repositórios para o laboratório..."
bash $BIN_REPO

# Configurar o SELinux para permitir o Apache acessar os arquivos do laboratório
echo "Configurando o SELinux para permitir o Apache acessar os arquivos do laboratório..."
semanage fcontext -a -t httpd_sys_content_t "${DIR_LABRHEL}(/.*)?"
semanage fcontext -a -t httpd_sys_content_t "${DIR_MATERIALS}(/.*)?"
restorecon -R ${DIR_LABRHEL}/
restorecon -R ${DIR_MATERIALS}/

# Iniciar o serviço do Apache e habilitá-lo para iniciar na inicialização
echo "Iniciando o serviço do Apache e habilitando-o para iniciar na inicialização..."
systemctl start httpd
systemctl enable httpd

# Criando diretório do ansible no home do admin
echo "Criando diretório do Ansible no home do admin..."
mkdir -p /home/admin/ansible
chown -R admin:admin /home/admin/ansible
cp -r ${DIR_CONFS}/ansible/* /home/admin/ansible/
restorecon -R /home/admin/ansible/
loginctl enable-linger 1010

if ! import_execution_environment; then
    exit 1
fi


echo "Configuração do laboratório de RHEL 9 concluída com sucesso!"
echo -e "Para ter acesso ao laboratório, adicione ao seu /etc/hosts a seguinte entreda $IP_ADDRESS exam.example.com\n"
echo -e "Copiar o arquivo de /etc/hosts para os seus nodes gerenciados ${HOSTS_FILE} \n"
echo "Acesse o laboratório através do navegador usando o endereço: http://exam.example.com/"
