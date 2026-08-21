# Laboratório Red Hat

Este projeto prepara uma workstation RHEL 9 para estudos práticos dos exames
Red Hat. O instalador configura a interface gráfica, Ansible, Podman, Apache,
Visual Studio Code, acesso remoto via XRDP, repositórios RPM locais, materiais
dos exercícios e a interface web com os simulados RHCSA, RHCE e OpenShift.

O laboratório também inclui o comando `lab-ex294`, usado pelo usuário
`student` para restaurar, iniciar e finalizar as VMs do ambiente no Proxmox.

## Arquitetura do laboratório

O ambiente utiliza uma workstation e cinco managed nodes:

| Máquina | Função |
| --- | --- |
| `workstation` | Interface gráfica, Ansible, Podman, Apache e simulados |
| `node1` | Managed node RHEL 9 |
| `node2` | Managed node RHEL 9 |
| `node3` | Managed node RHEL 9 |
| `node4` | Managed node RHEL 9 |
| `node5` | Managed node RHEL 9 |

Crie cinco VMs QEMU/KVM no Proxmox para os managed nodes. Caso a workstation
também seja executada no Proxmox, o ambiente completo terá seis VMs.

As cinco VMs gerenciadas devem possuir:

- RHEL 9 instalado;
- rede acessível pela workstation;
- hostname e endereço IP correspondentes ao arquivo `confs/hosts`;
- tag Proxmox exatamente igual a `RHCE-NODES`;
- snapshot exatamente igual a `Maquina_pronta`;
- snapshot criado preferencialmente com a VM desligada.

O comando `lab-ex294` descobre automaticamente as VMs pela tag e exige que
todas possuam o snapshot indicado.

## Requisitos da workstation

- RHEL 9 x86_64 registrado no Red Hat Subscription Management;
- acesso aos repositórios BaseOS e AppStream;
- acesso ao repositório do Ansible Automation Platform 2.4;
- acesso à internet para pacotes, para o repositório oficial do Visual Studio
  Code, para o EPEL 9 e para as imagens disponibilizadas na GitHub Release;
- conectividade HTTPS com a porta `8006` do Proxmox;
- endereço IP estável;
- acesso de `root` ou `sudo`;
- pelo menos 4 vCPUs, 8 GB de RAM e 60 GB livres;
- recomendação de 8 vCPUs, 16 GB de RAM e 100 GB livres.

Os valores de CPU, memória e disco são recomendações deste projeto. O espaço
necessário pode aumentar conforme a quantidade de RPMs baixados para os
repositórios locais.

Uma instalação minimal é suportada. O script detecta `gnome-shell` e `gdm` e,
quando necessário, instala o grupo `Server with GUI`, habilita o GDM e define
o boot gráfico como padrão. O Visual Studio Code stable é instalado pelo
[repositório RPM oficial da Microsoft](https://code.visualstudio.com/docs/setup/linux).
O instalador também habilita o CodeReady Builder e instala o EPEL 9 para obter
os pacotes do XRDP, seguindo o procedimento de instalação do
[EPEL para RHEL 9](https://docs.fedoraproject.org/en-US/epel/getting-started/).

## Preparar as VMs gerenciadas

O Ansible é executado na workstation como `greg` e conecta aos managed nodes
como `devops`. Garanta que o usuário `devops` exista nos cinco nodes, tenha
sudo sem senha e receba a chave pública exibida pelo instalador.

Exemplo para copiar a chave depois da instalação, executado como `greg`:

```bash
for node in node1 node2 node3 node4 node5; do
    ssh-copy-id "devops@${node}"
done
```

## Criar o acesso de API no Proxmox

Execute os comandos abaixo como `root` em um nó do Proxmox. Os exemplos usam:

- usuário: `lab-rhel@pve`;
- token: `secret`;
- papel: `LabRHELLab`.

Crie o usuário e o papel com somente as permissões utilizadas pelo
`lab-ex294`:

```bash
pveum user add lab-rhel@pve -comment "API do laboratório Red Hat"

pveum role add LabRHELLab \
    -privs "VM.Audit VM.PowerMgmt VM.Snapshot.Rollback"
```

Crie o token com separação de privilégios:

```bash
pveum user token add lab-rhel@pve secret -privsep 1
```

O secret do token é exibido somente no momento da criação. Copie o valor
apresentado no campo `value` e guarde-o em local seguro.

Conceda o papel ao usuário e ao token somente nas cinco VMs do laboratório.
Substitua os VMIDs do exemplo pelos IDs reais:

```bash
for VMID in 201 202 203 204 205; do
    pveum acl modify "/vms/${VMID}" \
        -user lab-rhel@pve \
        -role LabRHELLab

    pveum acl modify "/vms/${VMID}" \
        -token 'lab-rhel@pve!secret' \
        -role LabRHELLab
done
```

Como o token usa `privsep=1`, suas permissões são a interseção das permissões
do usuário e das permissões atribuídas diretamente ao token. Mais detalhes
estão no [Proxmox VE Administration Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.pdf).

Valide as permissões:

```bash
pveum user permissions lab-rhel@pve
pveum user token permissions lab-rhel@pve secret
```

## Configurar os endereços do laboratório

Antes de executar o instalador, edite `confs/hosts` e substitua os valores que
começam com `IP` pelos endereços da workstation e dos cinco managed nodes.

A workstation também responde pelos nomes:

- `exam.example.com`, para a interface dos simulados;
- `content.example.com`, para os repositórios e materiais.

## Executar a instalação

Na workstation, clone o repositório e execute o instalador como `root`:

```bash
git clone https://github.com/alexeiev/labrhel.git
cd labrhel
sudo bash script/install_lab.sh
```

Também é possível fornecer a configuração do Proxmox já na primeira execução:

```bash
sudo \
    PROXMOX_HOST='192.0.2.10' \
    PROXMOX_API_USER='lab-rhel@pve!secret' \
    PROXMOX_TOKEN_SECRET='SECRET_GERADO_PELO_PROXMOX' \
    bash script/install_lab.sh
```

`PROXMOX_HOST` deve conter apenas o IP ou hostname, sem `https://` e sem a
porta. A API utiliza a porta `8006`.

O instalador cria os usuários locais abaixo quando eles ainda não existem:

| Usuário | Senha inicial | Uso |
| --- | --- | --- |
| `student` | `student` | Login gráfico e gerenciamento das VMs |
| `greg` | `redhat` | Ansible e execution environment Podman |
| `devops` | `redhat` | Conta correspondente ao usuário remoto dos nodes |

As senhas iniciais podem ser substituídas na primeira execução usando as
variáveis `STUDENT_PASSWORD`, `GREG_PASSWORD` e `DEVOPS_PASSWORD`.

O instalador também cria no desktop de `student` atalhos para a interface do
exame e para o terminal. O ícone do exame é instalado em
`/home/student/.local/share/icons/redhat.png`.

## Acesso remoto via RDP

O instalador instala `xrdp`, `xorgxrdp` e `xrdp-selinux`, habilita o serviço
`xrdp` no boot e libera `3389/tcp` no `firewalld`. O backend Xorg cria uma
sessão GNOME independente para a conexão remota. Esses componentes seguem as
[recomendações do projeto XRDP](https://github.com/neutrinolabs/xrdp).

Use um cliente RDP para acessar o endereço IP da workstation na porta `3389`:

```text
Servidor: IP_DA_WORKSTATION:3389
Usuário: student
Senha inicial: student
Sessão: Xorg
```

Se `STUDENT_PASSWORD` foi fornecida durante a instalação, utilize esse valor.
Evite manter o mesmo usuário conectado simultaneamente no console gráfico e
via XRDP; finalize a sessão local de `student` antes de iniciar a conexão RDP.

> **Segurança:** a conta `student` possui `sudo` sem senha neste laboratório.
> Troque a senha inicial e exponha a porta `3389` somente em uma rede confiável.

## Configuração do Proxmox no usuário student

Somente o usuário `student` recebe a configuração de acesso ao Proxmox. O
arquivo criado pelo instalador é:

```text
/home/student/.config/lab-ex294/env
```

Ele possui permissão `0600` e deve conter:

```bash
export PROXMOX_HOST='192.0.2.10'
export PROXMOX_API_USER='lab-rhel@pve!secret'
export PROXMOX_TOKEN_SECRET='SECRET_GERADO_PELO_PROXMOX'
```

Se os valores não foram fornecidos na instalação, entre como `student` e edite
somente esse arquivo:

```bash
vi ~/.config/lab-ex294/env
chmod 600 ~/.config/lab-ex294/env
```

Não é necessário modificar o script Python. A CLI lê automaticamente as três
variáveis do ambiente ou do arquivo acima.

## Utilizar o laboratório

Entre graficamente como `student` e use:

```bash
lab-ex294 start
```

O comando valida as VMs, restaura `Maquina_pronta` e inicia os cinco nodes.

Para encerrar o estudo, restaurar novamente o snapshot e deixar as VMs
desligadas:

```bash
lab-ex294 finish
```

Para consultar a ajuda:

```bash
lab-ex294 help
```

Depois de configurar a resolução de nomes no computador utilizado para acessar
a workstation, abra:

```text
http://exam.example.com/
```

## Imagens de container

Durante a instalação, as imagens são baixadas da
[GitHub Release Lab Assets v1](https://github.com/alexeiev/labrhel/releases/tag/lab-assets-v1),
validadas por SHA-256 e descompactadas em:

```text
/var/lib/lab-ex294/ee-supported-rhel8.tar
/var/lib/lab-ex294/ansible-dev-tools-rhel8.tar
```

Os archives são legíveis por todos os usuários. As imagens são importadas no
armazenamento rootless do Podman de `greg` e recebem estas tags:

```text
registry.redhat.io/ansible-automation-platform-24/ee-supported-rhel8:latest
registry.redhat.io/ansible-automation-platform-25/ansible-dev-tools-rhel8:latest
```

A primeira tag é a utilizada pelo Ansible Navigator no arquivo
`confs/ansible/ansible-navigator.yml`.
