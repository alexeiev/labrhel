# Perguntas

## 1. Instale e configure o Ansible no nó de controle da seguinte forma:
* Instale os pacotes necessários em control.lab.example.com.
* Crie um arquivo de inventário estático chamado /home/greg/ansible/inventory da seguinte forma:
    -- node1 é membro do grupo de hosts de desenvolvimento (dev)
    -- node2 é membro do grupo de hosts de teste (test)
    -- node3 e node4 são membros do grupo de hosts de produção (prod)
    -- node5 é membro do grupo de hosts de balanceadores (balancers)
    -- O grupo prod é membro do grupo de hosts webservers
* Crie um arquivo de configuração chamado /home/greg/ansible/ansible.cfg da seguinte forma:
    -- O arquivo de inventário de hosts /home/greg/ansible/inventory está definido
    -- O local das roles usadas em playbooks está definido como /home/greg/ansible/roles
    -- O local de instalação da Coleção de Conteúdo Ansible /home/greg/ansible/mycollection

## 2. Crie yum_repo.yml para configurar o repositório em todos os nós.
i) Nome = EX294_BASE
   Descrição = EX294 base software
   URL = http://content.example.com/rhel9/BaseOS
   GPG está desativado (na prova é ativado).
   Repositório está ativado.
ii) Nome = EX294_STREAM
    Descrição = EX294 stream software
    URL = http://content.example.com/rhel9/AppStream
    GPG está desativado (na prova é ativado).
    Repositório está ativado.

## 3. Instalar pacotes em vários grupos.
i) Instale os pacotes php e mariadb nos grupos dev, test e prod.
ii) Instale o pacote de grupo "RPM Development Tools" no grupo dev.
iii) Atualize todos os pacotes para a versão mais recente no grupo dev.
iv) Use uma ação separado para cada tarefa e o nome do playbook deve ser packages.yml.

## 4. Instalação de Coleções de Conteúdo Ansible
    Instale a coleção no diretório de coleções local /home/greg/ansible/mycollection.
    Faça o download dos arquivos tar.gz das URLs fornecidas:
    coleções:
    http://content.example.com/materials/redhat-insights-1.0.7.tar.gz
    http://content.example.com/materials/community-general-5.5.0.tar.gz
    http://content.example.com/materials/redhat-rhel_system_roles-1.19.3.tar.gz

## 5. Instale roles usando o Ansible Galaxy.
    Crie um diretório 'roles' em /home/greg/ansible.
    i) Crie um playbook chamado requirements.yml no diretório de roles e baixe as roles fornecidas no diretório 'roles' usando o comando galaxy.
    ii) O nome da role deve ser balancer e fazer o download usando esta url http://content.example.com/materials/balancer.tgz
    iii) O nome da role phpinfo e fazer o download usando esta url http://content.example.com/materials/phpinfo.tgz

## 6. Usar a role de sistema RHEL SELinux.
    Crie um playbook chamado /home/greg/ansible/selinux.yml que:
    - É executado em todos os nós gerenciados
    - Usa a role selinux
    - Configura a role para usar a política: targeted
    - Configura a role para definir o estado: enforcing

## 7. Crie uma role offline chamada apache no diretório de roles.
    i) Instale o pacote httpd, o serviço deve ser iniciado e ativado na inicialização.
    ii) Ative o serviço firewalld com a regra HTTP.
    iii) Hospede a página da web usando o template index.html.j2
    iv) O index.html.j2 deve conter
        Bem-vindo a HOSTNAME em IPADDRESS
        Onde HOSTNAME é o nome de domínio totalmente qualificado.
    v) Crie um playbook chamado /home/greg/ansible/apache.yml e execute a role no grupo webservers.

## 8. Crie um playbook chamado roles.yml e ele deve executar as roles balancer e phpinfo.
    Use roles do Ansible Galaxy
    Crie um playbook chamado /home/greg/ansible/roles.yml
    * O playbook contém um play que é executado nos hosts do grupo de hosts de balanceadores e usa a role balancer.
    - Esta role configura um serviço para balancear solicitações de servidor web entre os hosts no grupo de hosts webservers.
    - Navegar para o host no grupo de hosts de balanceadores (por exemplo, http://node5.lab.example.com) produz a seguinte saída:
    Welcome to node3.lab.example.com on 172.25.250.12
    - Recarregar o navegador produz a saída do servidor web alternativo:
    Welcome to node4.lab.example.com on 172.25.250.13
    * O playbook contém um play que é executado nos hosts do grupo de hosts webservers e usa a role phpinfo.
    - Navegar para o host no grupo de hosts webservers com a URL /hello.php produz a seguinte saída:
    Hello PHP World from FQDN
    - Por exemplo, navegar para http://node3.lab.example.com/hello.php produz a seguinte saída:
    Hello PHP World from node3.lab.example.com
    junto com vários detalhes da configuração do PHP, incluindo a versão do PHP que está instalada.
    - Da mesma forma, navegar para http://node4.lab.example.com/hello.php produz a seguinte saída:
    Hello PHP World from node4.lab.example.com
    junto com vários detalhes da configuração do PHP, incluindo a versão do PHP que está instalada.

## 9. Crie e use um Volume Lógico.
    Crie um playbook chamado /home/greg/ansible/lv.yml que é executado em todos os nós gerenciados e faz o seguinte:
    * Cria um volume lógico com os seguintes requisitos:
    - O Volume Lógico é criado no grupo de volume research
    - O nome do volume lógico é data
    - O tamanho do volume lógico é 1500 MiB
    * Formata o volume lógico com o sistema de arquivos ext4
    * Se o tamanho do volume lógico solicitado não puder ser criado, a mensagem de erro
    "Could not create logical volume of that size"
    deve ser exibida e o tamanho de 800 MiB deve ser usado em vez disso.
    * Se o grupo de volume research não existir, a mensagem de erro
    "Volume group does not exist"
    deve ser exibida
    * NÃO monta o volume lógico de forma alguma.

## 10. Gere o arquivo hosts a partir de template.
    i) Baixe o template http://content.example.com/materials/hosts.j2.
    ii) O arquivo deve coletar todas as informações do nó, como ipaddress, fqdn, hostname
      e deve ser o mesmo que no arquivo /etc/hosts,
      se o playbook for executado em todos os nós gerenciados, ele deve ser armazenado em /etc/myhosts.
    
    Finalmente, o arquivo /etc/myhosts deve conter.

    127.0.0.1   materials.example.com workstation.lab.example.com exam.example.com localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

    <ip_address> node1.lab.example.com node1
    <ip_address> node2.lab.example.com node2
    <ip_address> node3.lab.example.com node3
    <ip_address> node4.lab.example.com node4
    <ip_address> node5.lab.example.com node5

    v) O nome do playbook é hosts.yml e deve ser executado no grupo dev.

## 11. Substitua o arquivo /etc/issue em todos os nós gerenciados.
    i) No grupo dev, /etc/issue deve ter o conteúdo "Development".
    ii) No grupo test, /etc/issue deve ter o conteúdo "Test".
    iii) No grupo prod, /etc/issue deve ter o conteúdo "Production".
    iv) O nome do playbook é issue.yml e deve ser executado em todos os nós gerenciados.

## 12. Crie um playbook webcontent.yml e ele deve ser executado no grupo dev.
    i) Crie um diretório /webdev e ele deve pertencer ao grupo webdev.
    ii) O diretório /webdev deve ter o tipo de contexto como "httpd".
    iii) Atribua a permissão para user=rwx, group=rwx, others=rx e a permissão especial de grupo (set-gid) deve ser aplicada a /webdev.
    iv) Crie um arquivo index.html no diretório /webdev e o arquivo deve ter o conteúdo "Development".
    v) Vincule o diretório /webdev a /var/www/html/webdev (symlink).

## 13. Colete relatórios de hardware usando playbook em todos os nós.
    i) Baixe hwreport.empty da url http://content.example.com/materials/hwreport.empty e salve-o como /root/hwreport.txt.
    ii) Modifique o arquivo com os seguintes pares chave=valor:
        - HOST = nome do host do inventário
        - MEMORY = memória total em MB
        - BIOS = versão do BIOS
        - DISK_SIZE_VDA = tamanho do disco vda
        - DISK_SIZE_VDB = tamanho do disco vdb
    iii) Se não houver informações, deve mostrar "NONE".
    iv) O nome do playbook deve ser hwreport.yml.

## 14. Crie um arquivo de variáveis vault (locker.yml) e esse arquivo deve conter a variável e seu valor.
    pw_developer é o valor Imadev
    pw_manager é o valor Imamgr
    i) O arquivo locker.yml deve ser criptografado usando a senha "whenyouwlshuponastar".
    ii) Armazene a senha no arquivo /home/greg/ansible/secret.txt que é usado para criptografar o arquivo de variáveis.

## 15. Crie contas de usuário a partir do arquivo de variáveis.
    Baixe o arquivo de variáveis http://content.example.com/materials/user_list.yml.
    O nome do playbook é users.yml e deve ser executado em todos os nós usando dois arquivos de variáveis user_list.yml e locker.yml.
    i) * Crie um grupo devops
       * Crie um usuário a partir da variável users cujo trabalho seja igual a developer e precise estar no grupo devops
       * Atribua uma senha usando o formato SHA512 e execute o playbook em dev e test.
       * A senha do usuário é {{ pw_developer }}
       * Expiração máxima da senha: 30 dias
    ii) * Crie um grupo opsmgr
        * Crie um usuário a partir da variável users cujo trabalho seja igual a manager e precise estar no grupo opsmgr
        * Atribua uma senha usando o formato SHA512 e execute o playbook em prod.
        * A senha do usuário é {{ pw_manager }}
        * Expiração máxima da senha: 30 dias
    iii) * Use a condição when para cada play.

## 16. Recrie a chave do arquivo de variáveis de http://content.example.com/materials/salaries.yml.
    i) Senha antiga: insecure4sure
    ii) Nova senha: bbe2de98389b
    iii) O arquivo deve permanecer criptografado.

## 17. Crie um cronjob para o usuário natasha em todos os nós do grupo dev, o nome do playbook é cron.yml e os detalhes do job estão abaixo:
    i) A cada 2 minutos o job executará logger "EX294 in progress".
