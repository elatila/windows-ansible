# Managing Windows Server Using Ansible
Simple script and example for managing windows server using [Ansible](http://docs.ansible.com/ansible/latest/index.html). Here is the list of module that can be running by ansible on windows machine  http://docs.ansible.com/ansible/latest/list_of_windows_modules.html

The PowerShell script will configure the WinRM to accept only specified subnet to connect to, please take a look for variable `$Subnet` on the `EnableRemotingAnsible.ps1` script.

`RemoteExecutePowerShellScript.ps1` is a helper script if you want to execute `EnableRemotingAnsible.ps1` script on so many server, it's easier when you can do remote executing.

**Note :** 
To make it simple, Ansible control host no need to be joined to a domain contoller (AD), instead it will need local user to manage the server, so we have to create / use existing local admin user, the PowerShell script has the ability to create one, so please take a look and modify as you need. But if you prefer to use domain user, you can follow this documents http://docs.ansible.com/ansible/latest/intro_windows.html#authentication-options
