# Managing Windows Server Using Ansible
Simple script and example for managing windows server using [Ansible](http://docs.ansible.com/ansible/latest/index.html). Here is the list of module that can be running by ansible on windows machine  http://docs.ansible.com/ansible/latest/list_of_windows_modules.html

The Powershell script will configure the WinRM to accept only specified subnet to connect to, please take a look for variable `$Subnet` on the `EnableRemotingAnsible.ps1` script

**Note :** 
To make it simple, ansible server no need to be joined to a domain contoller (AD), instead it will need local user to manage the server, so we have to create / use existing local admin user, the powershell script has the ability to create one, so please take a look and modify as you need.

