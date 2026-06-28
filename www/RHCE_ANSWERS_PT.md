# RHCE (EX294) - Respostas

## 1. Instale e configure o Ansible no no de controle

Instale os pacotes necessarios, crie um arquivo de inventario estatico e configure o ansible.cfg no no de controle.

### Commands

```
sudo yum -y install ansible-core ansible-navigator
mkdir -p /home/greg/ansible/roles
mkdir -p /home/greg/ansible/mycollection
cd /home/greg/ansible/
```

### Inventario: /home/greg/ansible/inventory

```
[dev]
node1

[test]
node2

[prod]
node3
node4

[balancers]
node5

[webservers:children]
prod
```

### Configuracao: /home/greg/ansible/ansible.cfg

```
[defaults]
inventory = /home/greg/ansible/inventory
remote_user = greg
host_key_checking = False
roles_path = /home/greg/ansible/roles
collections_path = /home/greg/ansible/mycollection

[privilege_escalation]
become = True
```

### Validar

```
ansible --version
ansible all -m ping
```

## 2. Configurar repositorios YUM (yum_repo.yml)

Crie yum_repo.yml para configurar os repositorios EX294_BASE e EX294_STREAM em todos os nos. GPG esta desativado no lab (ativado na prova).

### Playbook: /home/greg/ansible/yum_repo.yml

```
---
- name: Configure YUM repositories
  hosts: all
  tasks:
    - name: Configure EX294_BASE repository
      yum_repository:
        file: EX294_BASE
        name: EX294_BASE
        description: "EX294 base software"
        baseurl: http://content.example.com/rhel9/BaseOS
        gpgcheck: no
        enabled: yes

    - name: Configure EX294_STREAM repository
      yum_repository:
        file: EX294_STREAM
        name: EX294_STREAM
        description: "EX294 stream software"
        baseurl: http://http://content.example.com/rhel9/AppStream
        gpgcheck: no
        enabled: yes
```

### Executar

```
ansible-navigator run yum_repo.yml -m stdout
```

## 3. Instalar pacotes (packages.yml)

Instale php e mariadb em dev, test e prod. Instale "RPM Development Tools" em dev. Atualize todos os pacotes em dev. Use uma acao separada para cada tarefa.

### Playbook: /home/greg/ansible/packages.yml

```
---
- name: Install php and mariadb
  hosts: dev,test,prod
  tasks:
    - name: Install required packages
      yum:
        name:
          - php
          - mariadb
        state: present

- name: Install RPM Development Tools
  hosts: dev
  tasks:
    - name: Install RPM Development Tools group
      yum:
        name: "@RPM Development Tools"
        state: present

- name: Update all packages
  hosts: dev
  tasks:
    - name: Upgrade all packages to the latest version
      yum:
        name: "*"
        state: latest
```

### Executar

```
ansible-navigator run packages.yml -m stdout
```

## 4. Instalar Colecoes de Conteudo Ansible

Instale as colecoes a partir das URLs fornecidas no diretorio /home/greg/ansible/mycollection.

### Requirements: /home/greg/ansible/requirements.yml

```
---
collections:
  - name: http://content.example.com/materials/redhat-insights-1.0.7.tar.gz
  - name: http://content.example.com/materials/community-general-5.5.0.tar.gz
  - name: http://content.example.com/materials/redhat-rhel_system_roles-1.19.3.tar.gz
```

### Instalar

```
ansible-galaxy collection install -r requirements.yml -p /home/greg/ansible/mycollection
```

## 5. Instalar roles usando Ansible Galaxy

Crie um diretorio roles e um arquivo requirements.yml para baixar as roles balancer e phpinfo.

### Requirements: /home/greg/ansible/roles/requirements.yml

```
---
- src: http://content.example.com/materials/haproxy.tar
  name: balancer

- src: http://content.example.com/materials/phpinfo.tar
  name: phpinfo
```

### Instalar

```
ansible-galaxy install -r /home/greg/ansible/roles/requirements.yml -p /home/greg/ansible/roles
```

## 6. Usar role de sistema RHEL SELinux (selinux.yml)

Crie um playbook que execute em todos os nos gerenciados, use a role selinux com politica targeted e estado enforcing.

### Playbook: /home/greg/ansible/selinux.yml

```
---
- name: Configure SELinux
  hosts: all
  become: true
  vars:
    selinux_policy: targeted
    selinux_state: enforcing
  tasks:
    - name: Apply SELinux role
      block:
        - name: Include selinux role
          include_role:
            name: rhel-system-roles.selinux
      rescue:
        - name: Fail if reboot not required
          fail:
            msg: "SELinux role failed"
          when: not selinux_reboot_required

        - name: Reboot managed host
          reboot:

        - name: Wait for managed host to come back
          wait_for_connection:
            delay: 10
            timeout: 300

        - name: Reapply the role
          include_role:
            name: rhel-system-roles.selinux
```

### Executar

```
ansible-navigator run selinux.yml -m stdout
```

## 7. Criar role Apache

Crie uma role offline chamada apache: instale httpd, ative firewalld com HTTP, hospede uma pagina web usando template Jinja2.

### Criar estrutura da role

```
ansible-galaxy init /home/greg/ansible/roles/apache
```

### Tasks: /home/greg/ansible/roles/apache/tasks/main.yml

```
---
- name: Install httpd
  yum:
    name: httpd
    state: latest

- name: Start and enable httpd
  systemd:
    name: httpd
    state: started
    enabled: yes

- name: Start and enable firewalld
  systemd:
    name: firewalld
    state: started
    enabled: yes

- name: Allow HTTP through firewall
  firewalld:
    service: http
    permanent: yes
    state: enabled
    immediate: yes

- name: Deploy index.html from template
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
```

### Template: /home/greg/ansible/roles/apache/templates/index.html.j2

```
Welcome to {{ ansible_fqdn }} on {{ ansible_default_ipv4.address }}
```

### Playbook: /home/greg/ansible/apache.yml

```
---
- name: Deploy Apache role
  hosts: webservers
  roles:
    - apache
```

### Executar

```
ansible-navigator run apache.yml -m stdout
```

## 8. Usar roles balancer e phpinfo (roles.yml)

Crie roles.yml para executar a role phpinfo nos webservers e a role balancer no grupo balancers.

### Playbook: /home/greg/ansible/roles.yml

```
---
- name: Use phpinfo role
  hosts: webservers
  roles:
    - phpinfo

- name: Use balancer role
  hosts: balancers
  roles:
    - balancer
```

### Executar

```
ansible-navigator run roles.yml -m stdout
```

### Validar

```
curl http://node5.lab.example.com
# Should alternate between node3 and node4

curl http://node3.lab.example.com/hello.php
# Hello PHP World from node3.lab.example.com

curl http://node4.lab.example.com/hello.php
# Hello PHP World from node4.lab.example.com
```

## 9. Criar e usar Volume Logico (lv.yml)

Crie um volume logico "data" no grupo de volume "research" com 1500 MiB (fallback para 800 MiB). Formate com ext4. Trate VG inexistente.

### Playbook: /home/greg/ansible/lv.yml

```
---
- name: Create Logical Volume
  hosts: all
  tasks:
    - block:
        - name: Create LV with 1500 MiB
          community.general.lvol:
            vg: research
            lv: data
            size: 1500

        - name: Format with ext4
          community.general.filesystem:
            fstype: ext4
            dev: /dev/research/data

      rescue:
        - name: Display size error
          ansible.builtin.debug:
            msg: Could not create logical volume of that size

        - name: Create LV with 800 MiB
          community.general.lvol:
            vg: research
            lv: data
            size: 800

        - name: Format with ext4
          community.general.filesystem:
            fstype: ext4
            dev: /dev/research/data

      when: ansible_lvm.vgs.research is defined

    - name: Display VG error
      ansible.builtin.debug:
        msg: Volume group does not exist
      when: ansible_lvm.vgs.research is not defined
```

### Executar

```
ansible-navigator run lv.yml -m stdout
```

## 10. Gerar arquivo hosts a partir de template (hosts.yml)

Baixe o template hosts.j2. Crie um playbook que gere /etc/myhosts no grupo dev com as informacoes de todos os hosts do inventario.

### Download template

```
wget http://content.example.com/materials/hosts.j2 -O /home/greg/ansible/hosts.j2
```

### Template: /home/greg/ansible/hosts.j2

```
127.0.0.1   materials.example.com workstation.lab.example.com exam.example.com localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

{% for host in groups['all'] %}
{{ hostvars[host]['ansible_facts']['default_ipv4']['address'] }} {{ hostvars[host]['ansible_facts']['fqdn'] }} {{ hostvars[host]['ansible_facts']['hostname'] }}
{% endfor %}
```

### Playbook: /home/greg/ansible/hosts.yml

```
---
- name: Gather facts from all hosts
  hosts: all

- name: Generate /etc/myhosts on dev group
  hosts: dev
  tasks:
    - name: Deploy hosts file from template
      template:
        src: /home/greg/ansible/hosts.j2
        dest: /etc/myhosts
```

### Executar

```
ansible-navigator run hosts.yml -m stdout
```

## 11. Substituir /etc/issue (issue.yml)

Substitua /etc/issue com "Development" em dev, "Test" em test e "Production" em prod.

### Playbook: /home/greg/ansible/issue.yml

```
---
- name: Modify /etc/issue
  hosts: all
  tasks:
    - name: Set content for dev
      ansible.builtin.copy:
        content: "Development"
        dest: /etc/issue
      when: inventory_hostname in groups.dev

    - name: Set content for test
      ansible.builtin.copy:
        content: "Test"
        dest: /etc/issue
      when: inventory_hostname in groups.test

    - name: Set content for prod
      ansible.builtin.copy:
        content: "Production"
        dest: /etc/issue
      when: inventory_hostname in groups.prod
```

### Executar

```
ansible-navigator run issue.yml -m stdout
```

## 12. Conteudo Web (webcontent.yml)

Crie o diretorio /webdev pertencente ao grupo webdev com set-gid, crie index.html com "Development" e crie symlink para /var/www/html/webdev.

### Playbook: /home/greg/ansible/webcontent.yml

```
---
- name: Create Web Content Directory
  hosts: dev
  tasks:
    - name: Create /webdev directory
      ansible.builtin.file:
        path: /webdev
        state: directory
        group: webdev
        mode: '2775'

    - name: Set SELinux context for /webdev
      community.general.sefcontext:
        target: '/webdev(/.*)?'
        setype: httpd_sys_content_t
        state: present

    - name: Apply SELinux context
      ansible.builtin.command: restorecon -Rv /webdev

    - name: Create index.html
      ansible.builtin.copy:
        content: "Development"
        dest: /webdev/index.html
        setype: httpd_sys_content_t

    - name: Create symbolic link
      ansible.builtin.file:
        src: /webdev
        dest: /var/www/html/webdev
        state: link
```

### Executar

```
ansible-navigator run webcontent.yml -m stdout
```

## 13. Relatorio de Hardware (hwreport.yml)

Baixe hwreport.empty, salve como /root/hwreport.txt e preencha HOST, MEMORY, BIOS, DISK_SIZE_VDA, DISK_SIZE_VDB. Mostre "NONE" se a informacao nao existir.

### Playbook: /home/greg/ansible/hwreport.yml

```
---
- name: Generate hardware report
  hosts: all
  tasks:
    - name: Download empty report template
      ansible.builtin.get_url:
        url: http://content.example.com/materials/hwreport.empty
        dest: /root/hwreport.txt

    - name: Set HOST
      ansible.builtin.lineinfile:
        path: /root/hwreport.txt
        regexp: '^HOST='
        line: "HOST={{ inventory_hostname }}"

    - name: Set MEMORY
      ansible.builtin.lineinfile:
        path: /root/hwreport.txt
        regexp: '^MEMORY='
        line: "MEMORY={{ ansible_memtotal_mb | default('NONE', true) }}"

    - name: Set BIOS
      ansible.builtin.lineinfile:
        path: /root/hwreport.txt
        regexp: '^BIOS='
        line: "BIOS={{ ansible_bios_version | default('NONE', true) }}"

    - name: Set DISK_SIZE_VDA
      ansible.builtin.lineinfile:
        path: /root/hwreport.txt
        regexp: '^DISK_SIZE_VDA='
        line: "DISK_SIZE_VDA={{ ansible_devices.vda.size | default('NONE', true) }}"

    - name: Set DISK_SIZE_VDB
      ansible.builtin.lineinfile:
        path: /root/hwreport.txt
        regexp: '^DISK_SIZE_VDB='
        line: "DISK_SIZE_VDB={{ ansible_devices.vdb.size | default('NONE', true) }}"
```

### Executar

```
ansible-navigator run hwreport.yml -m stdout
```

## 14. Criar Vault (locker.yml)

Crie um arquivo de variaveis criptografado locker.yml com pw_developer e pw_manager. Armazene a senha do vault em secret.txt.

### Armazenar a senha do vault

```
echo "whenyouwlshuponastar" > /home/greg/ansible/secret.txt
```

### Adicionar ao ansible.cfg

```
[defaults]
vault_password_file = /home/greg/ansible/secret.txt
```

### Criar o arquivo vault

```
ansible-vault create /home/greg/ansible/locker.yml
```

### Conteudo do locker.yml

```
---
pw_developer: Imadev
pw_manager: Imamgr
```

### Validar

```
ansible-vault view /home/greg/ansible/locker.yml
```

## 15. Criar contas de usuario (users.yml)

Baixe user_list.yml. Crie usuarios: developers no grupo devops em dev/test, managers no grupo opsmgr em prod. Senha SHA512, expiracao maxima de 30 dias.

### Baixar arquivo de variaveis

```
wget http://content.example.com/materials/user_list.yml -O /home/greg/ansible/user_list.yml
```

### Playbook: /home/greg/ansible/users.yml

```
---
- name: Create developer users
  hosts: dev,test
  vars_files:
    - /home/greg/ansible/locker.yml
    - /home/greg/ansible/user_list.yml
  tasks:
    - name: Create devops group
      group:
        name: devops
        state: present

    - name: Create developer users
      user:
        name: "{{ item.name }}"
        groups: devops
        password: "{{ pw_developer | password_hash('sha512') }}"
        password_expire_max: 30
      loop: "{{ users }}"
      when: item.job == 'developer'

- name: Create manager users
  hosts: prod
  vars_files:
    - /home/greg/ansible/locker.yml
    - /home/greg/ansible/user_list.yml
  tasks:
    - name: Create opsmgr group
      group:
        name: opsmgr
        state: present

    - name: Create manager users
      user:
        name: "{{ item.name }}"
        groups: opsmgr
        password: "{{ pw_manager | password_hash('sha512') }}"
        password_expire_max: 30
      loop: "{{ users }}"
      when: item.job == 'manager'
```

### Executar

```
ansible-navigator run users.yml -m stdout
```

## 16. Recriar chave do vault (salaries.yml)

Baixe salaries.yml e altere a chave com uma nova senha. O arquivo deve permanecer criptografado.

### Download and rekey

```
wget http://content.example.com/materials/salaries.yml -O /home/greg/ansible/salaries.yml

ansible-vault rekey --ask-vault-pass /home/greg/ansible/salaries.yml
# Old password: insecure4sure
# New password: bbe2de98389b
```

### Validar

```
ansible-vault view /home/greg/ansible/salaries.yml --ask-vault-pass
# Use the new password: bbe2de98389b
```

## 17. Criar Cron Job (cron.yml)

Crie um cron job para o usuario natasha nos nos do grupo dev. A cada 2 minutos execute: logger "EX294 in progress".

### Playbook: /home/greg/ansible/cron.yml

```
---
- name: Configure cron job
  hosts: dev
  tasks:
    - name: Create cron job for natasha
      cron:
        name: "EX294 logger"
        minute: "*/2"
        job: 'logger "EX294 in progress"'
        user: natasha
```

### Executar

```
ansible-navigator run cron.yml -m stdout
```
