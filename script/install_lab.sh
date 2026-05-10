#!/usr/bin/env bash

# Preparando ambiente para o laboratório de RHEL 9
# Autor: Alexeiev
# Data: 2026-05-10


DIR_MATERIALS=/var/www/html/repos/materials
DIR_LABRHEL=/var/www/html/labrhel
DIR_CONFS=../confs
HOSTS_FILE=${DIR_CONFS}/hosts
DIR_WWW=../www

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
cp $HOSTS_FILE /etc/hosts
restorecon -R /etc/hosts

# Update do sistema
echo "Atualizando o sistema..."
dnf update -y

# install packages
echo "Instalando pacotes necessários..."
dnf install -y httpd bash-completion ansible-core
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

# Criar usuário admin
echo "Criando usuário admin..."
useradd admin -m -s /bin/bash
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
echo "Configurando o arquivo /etc/hosts para o usuário admin..."
echo  "${IP_ADDRESS} exam.example.com"

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


echo "Configuração do laboratório de RHEL 9 concluída com sucesso!"
echo "Para ter acesso ao laboratório, adicione ao seu /etc/hosts a seguinte entreda $IP_ADDRESS exam.example.com"
echo "Acesse o laboratório através do navegador usando o endereço: http://exam.example.com/"
