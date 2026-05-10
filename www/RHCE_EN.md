# Questions

## 1. Install and Configure Ansible on the control node as follows:
* Install the required packages on control.lab.example.com.
* Create a static inventory file called /home/greg/ansible/inventory as follows:
    -- node1 is a member of the dev host group
    -- node2 is a member of the test host group
    -- node3 and node4 are members of the prod host group
    -- node5 is a member of the balancers host group
    -- The prod group is a member of the webservers host group
* Create a configuration file called /home/greg/ansible/ansible.cfg as follows:
    -- The host inventory file /home/greg/ansible/inventory is defined
    -- The location of roles used in playbooks is defined as /home/greg/ansible/roles
    -- The install Ansible Content Collection location /home/greg/ansible/mycollection

## 2. Create yum_repo.yml for configuring repository in all nodes.
i) Name = EX294_BASE
   Description = EX294 base software
   URL = http://content.example.com/rhel9/BaseOS
   GPG is disabled (in the exam it is enabled).
   Repository is enabled.
ii) Name = EX294_STREAM
    Description = EX294 stream software
    URL = http://content.example.com/rhel9/AppStream
    GPG is disabled (in the exam it is enabled).
    Repository is enabled.

## 3. Install packages in multiple groups.
i) Install php and mariadb packages in dev, test and prod groups.
ii) Install "RPM Development Tools" group package in dev group.
iii) Update all packages to latest in dev group.
iv) Use separate play for each task and playbook name should be packages.yml.

## 4. Installing Ansible Content Collections
    Install the collection in the local collections directory /home/greg/ansible/mycollection.
    Download the tar.gz files from the given URLs:
    collections:
    http://content.example.com/materials/redhat-insights-1.0.7.tar.gz
    http://content.example.com/materials/community-general-5.5.0.tar.gz
    http://content.example.com/materials/redhat-rhel_system_roles-1.19.3.tar.gz

## 5. Install roles using Ansible Galaxy.
    Create a directory 'roles' under /home/greg/ansible.
    i) Create a playbook called requirements.yml under the roles directory and download the given roles under the 'roles' directory using galaxy command.
    ii) Role name should be balancer and download using this url http://content.example.com/materials/balancer.tgz
    iii) Role name phpinfo and download using this url http://content.example.com/materials/phpinfo.tgz

## 6. Use RHEL SELinux system role.
    Create a playbook called /home/greg/ansible/selinux.yml that:
    - Runs on all managed nodes
    - Uses the selinux role
    - Configures the role to use policy: targeted
    - Configures the role to set state: enforcing

## 7. Create offline role named apache under roles directory.
    i) Install httpd package, the service should be started and enabled on boot.
    ii) Enable the firewalld service with HTTP rule.
    iii) Host the web page using the template index.html.j2
    iv) The index.html.j2 should contain
        Welcome to HOSTNAME on IPADDRESS
        Where HOSTNAME is the fully qualified domain name.
    v) Create a playbook named /home/greg/ansible/apache.yml and run the role on the webservers group.

## 8. Create a playbook called roles.yml and it should run balancer and phpinfo roles.
    Use roles from Ansible Galaxy
    Create a playbook called /home/greg/ansible/roles.yml
    * The playbook contains a play that runs on hosts in the balancers host group and uses the balancer role.
    - This role configures a service to load balance web server requests between hosts in the webservers host group.
    - Browsing to host in the balancers host group (for example http://node5.lab.example.com) produces the following output:
    Welcome to node3.lab.example.com on 172.25.250.12
    - Reloading the browser produces output from the alternate web server:
    Welcome to node4.lab.example.com on 172.25.250.13
    * The playbook contains a play that runs on hosts in the webservers host group and uses the phpinfo role.
    - Browsing to host in the webservers host group with the URL /hello.php produces the following output:
    Hello PHP World from FQDN
    - For example, browsing to http://node3.lab.example.com/hello.php produces the following output:
    Hello PHP World from node3.lab.example.com
    along with various details of the PHP configuration including the version of PHP that is installed.
    - Similarly, browsing to http://node4.lab.example.com/hello.php produces the following output:
    Hello PHP World from node4.lab.example.com
    along with various details of the PHP configuration including the version of PHP that is installed.

## 9. Create and use a Logical Volume.
    Create a playbook called /home/greg/ansible/lv.yml that runs on all managed nodes and does the following:
    * Creates a logical volume with these requirements:
    - The Logical Volume is created in the research volume group
    - The logical volume name is data
    - The logical volume size is 1500 MiB
    * Format the logical volume with the ext4 file system
    * If the requested logical volume size cannot be created, the error message
    "Could not create logical volume of that size"
    should be displayed and size 800 MiB should be used instead.
    * If the volume group research does not exist, the error message
    "Volume group does not exist"
    should be displayed
    * Does NOT mount the logical volume in any way.

## 10. Generate hosts file from template.
    i) Download the template http://content.example.com/materials/hosts.j2.
    ii) The file should collect all node information like ipaddress, fqdn, hostname
      and it should be the same as in the /etc/hosts file,
      if the playbook runs on all managed nodes, it should be stored in /etc/myhosts.

    Finally, the /etc/myhosts file should contain:

    127.0.0.1   materials.example.com workstation.lab.example.com exam.example.com localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

    <ip_address> node1.lab.example.com node1
    <ip_address> node2.lab.example.com node2
    <ip_address> node3.lab.example.com node3
    <ip_address> node4.lab.example.com node4
    <ip_address> node5.lab.example.com node5

    v) Playbook name hosts.yml and run on dev group.

## 11. Replace the file /etc/issue on all managed nodes.
    i) In dev group, /etc/issue should have the content "Development".
    ii) In test group, /etc/issue should have the content "Test".
    iii) In prod group, /etc/issue should have the content "Production".
    iv) Playbook name issue.yml and run on all managed nodes.

## 12. Create a playbook webcontent.yml and it should run on dev group.
    i) Create a directory /webdev and it should be owned by the webdev group.
    ii) /webdev directory should have context type as "httpd".
    iii) Assign the permission for user=rwx, group=rwx, others=rx and group special permission (set-gid) should be applied to /webdev.
    iv) Create an index.html file under /webdev directory and the file should have the content "Development".
    v) Link the /webdev directory to /var/www/html/webdev (symlink).

## 13. Collect hardware report using playbook on all nodes.
    i) Download hwreport.empty from the url http://content.example.com/materials/hwreport.empty and save it as /root/hwreport.txt.
    ii) Modify the file with the following key=value pairs:
        - HOST = inventory hostname
        - MEMORY = total memory in MB
        - BIOS = BIOS version
        - DISK_SIZE_VDA = disk vda size
        - DISK_SIZE_VDB = disk vdb size
    iii) If there is no information, it should show "NONE".
    iv) Playbook name should be hwreport.yml.

## 14. Create a variable file vault (locker.yml) and that file should contain the variable and its value.
    pw_developer is value Imadev
    pw_manager is value Imamgr
    i) locker.yml file should be encrypted using the password "whenyouwlshuponastar".
    ii) Store the password in /home/greg/ansible/secret.txt file which is used to encrypt the variable file.

## 15. Create user accounts from variable file.
    Download the variable file http://content.example.com/materials/user_list.yml.
    Playbook name users.yml and run on all nodes using two variable files user_list.yml and locker.yml.
    i) * Create a group devops
       * Create user from users variable whose job is equal to developer and need to be in devops group
       * Assign a password using SHA512 format and run the playbook on dev and test.
       * User password is {{ pw_developer }}
       * Password expire maximum days: 30
    ii) * Create a group opsmgr
        * Create user from users variable whose job is equal to manager and need to be in opsmgr group
        * Assign a password using SHA512 format and run the playbook on prod.
        * User password is {{ pw_manager }}
        * Password expire maximum days: 30
    iii) * Use when condition for each play.

## 16. Rekey the variable file from http://content.example.com/materials/salaries.yml.
    i) Old password: insecure4sure
    ii) New password: bbe2de98389b
    iii) The file should remain encrypted.

## 17. Create a cronjob for user natasha on all nodes in dev group, the playbook name is cron.yml and the job details are below:
    i) Every 2 minutes the job will execute logger "EX294 in progress".
