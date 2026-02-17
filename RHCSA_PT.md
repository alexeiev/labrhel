# Perguntas

## 1. Configurar as definicoes de rede no node1.
    Configure o node1 com os seguintes parametros de rede:
    - Hostname: node1.domain250.example.com
    - Endereco IPv4: 172.25.250.100
    - Mascara de sub-rede: 255.255.255.0 (/24)
    - Gateway: 172.25.250.254
    - DNS: 172.25.250.254

## 2. Configurar repositorios YUM.
    Configure os seguintes repositorios YUM no sistema:
    i) Nome = BaseOS
       BaseURL = http://content/rhel9.0/x86_64/dvd/BaseOS
       Verificacao GPG desativada.
       Repositorio ativado.
    ii) Nome = AppStream
        BaseURL = http://content/rhel9.0/x86_64/dvd/Appstream
        Verificacao GPG desativada.
        Repositorio ativado.

## 3. Depurar o SELinux.
    Um servidor web a correr na porta nao padrao 82 nao consegue servir conteudo.
    i) Configure o servidor web para servir ficheiros de /var/www/html na porta 82.
    ii) Garanta que o contexto SELinux correto esta aplicado.
    iii) Configure a firewall para permitir trafego na porta 82.
    iv) O servico do servidor web deve iniciar automaticamente no arranque.

## 4. Criar contas de utilizador.
    i) Crie um grupo chamado sysmgrs.
    ii) Crie o utilizador natasha com sysmgrs como grupo suplementar.
    iii) Crie o utilizador harry com sysmgrs como grupo suplementar.
    iv) Crie o utilizador sarah sem acesso a shell interativa (nologin). Sarah nao deve ser membro de sysmgrs.
    v) Defina a senha flectrag para natasha, harry e sarah.

## 5. Configurar um cron job.
    Configure um cron job para o utilizador harry:
    i) O job executa diariamente as 14:23.
    ii) O comando a executar e: /usr/bin/echo hello

## 6. Criar um diretorio colaborativo.
    Crie o diretorio /home/managers com os seguintes requisitos:
    i) O grupo proprietario e sysmgrs.
    ii) O diretorio e legivel, gravavel e acessivel por membros do sysmgrs, mas nao por qualquer outro utilizador.
       (root tem acesso a todos os ficheiros do sistema.)
    iii) Ficheiros criados em /home/managers tem automaticamente o grupo proprietario definido como sysmgrs (bit SGID).
    iv) Permissoes: 2770

## 7. Configurar sincronizacao de tempo NTP.
    Configure o sistema como cliente NTP usando o servidor de tempo materials.example.com.

## 8. Configurar o autofs.
    Configure o autofs para montar automaticamente o diretorio home remoto com os seguintes requisitos:
    i) materials.example.com (172.25.254.254) exporta via NFS /rhome/remoteuser1 para o seu sistema.
    ii) O diretorio home de remoteuser1 deve ser automaticamente montado em /rhome/remoteuser1.
    iii) O diretorio home de remoteuser1 deve ser gravavel.
    iv) A senha de remoteuser1 e flectrag.

## 9. Criar uma conta de utilizador com UID especifico.
    i) Crie o utilizador manalo com UID 3533.
    ii) Defina a senha de manalo como flectrag.

## 10. Encontrar ficheiros por proprietario.
    Encontre todos os ficheiros no sistema pertencentes ao utilizador jacques e copie-os para o diretorio /root/findfiles.

## 11. Encontrar uma string num ficheiro.
    Encontre todas as linhas no ficheiro /usr/share/xml/iso-codes/iso_639_3.xml que contenham a string "ng".
    Coloque uma copia de todas estas linhas no ficheiro /root/list.
    O ficheiro /root/list nao deve conter linhas vazias e a ordem das linhas deve ser a mesma do ficheiro original.

## 12. Criar um arquivo compactado.
    Crie um arquivo tar comprimido com bzip2 do conteudo de /usr/local.
    Salve o arquivo como /root/backup.tar.bz2.

## 13. Construir uma imagem Podman.
    Como utilizador wallah:
    i) Faca o download do Containerfile de http://classroom/Containerfile.
    ii) Construa uma imagem chamada pdf usando o Containerfile descarregado.

## 14. Criar um servico systemd com Podman.
    Como utilizador wallah, configure um servico systemd para um container com os seguintes requisitos:
    i) O nome do container e ascii2pdf.
    ii) Use a imagem pdf construida na questao anterior.
    iii) Monte /opt/file do host em /dir1 no container.
    iv) Monte /opt/progress do host em /dir2 no container.
    v) O container deve iniciar automaticamente no reboot do sistema sem intervencao manual.

## 15. Configurar acesso sudo.
    Permita que os membros do grupo sysmgrs usem sudo para executar qualquer comando sem que lhes seja pedida uma senha.

## 16. Recuperar a senha de root no node2.
    Redefina a senha de root no node2 para flectrag.
    Deve ser possivel aceder ao sistema node2 usando SSH com a nova senha.
    (Use os metodos de parametro de arranque do kernel rd.break ou init=/bin/bash.)

## 17. Configurar repositorios YUM no node2.
    Configure os mesmos repositorios YUM no node2 conforme configurado na Questao 2:
    i) Nome = BaseOS
       BaseURL = http://content/rhel9.0/x86_64/dvd/BaseOS
       Verificacao GPG desativada.
       Repositorio ativado.
    ii) Nome = AppStream
        BaseURL = http://content/rhel9.0/x86_64/dvd/Appstream
        Verificacao GPG desativada.
        Repositorio ativado.

## 18. Expandir um Volume Logico.
    Redimensione o volume logico vo e o seu sistema de ficheiros para 230 MiB.
    i) Certifique-se de que o conteudo do sistema de ficheiros permanece intacto.
    ii) O intervalo de tamanho aceitavel e de 213 MiB a 243 MiB.

## 19. Adicionar uma particao swap.
    Adicione uma particao swap de 512 MiB ao sistema.
    i) A particao swap deve ser montada automaticamente no arranque.
    ii) Nao remova nem modifique as particoes swap existentes.

## 20. Criar um Volume Logico.
    Crie um novo volume logico com os seguintes requisitos:
    i) Nome do volume logico: qa
    ii) Nome do grupo de volumes: qagroup
    iii) Tamanho do volume logico: 60 extents
    iv) Tamanho do extent fisico no grupo de volumes: 16 MiB
    v) Formate o volume logico com o sistema de ficheiros vfat.
    vi) Monte o volume logico em /mnt/qa automaticamente no arranque.

## 21. Definir o perfil tuned recomendado.
    i) Instale o pacote tuned se ainda nao estiver instalado.
    ii) Identifique o perfil tuned recomendado pelo sistema.
    iii) Aplique e ative o perfil recomendado como padrao.
