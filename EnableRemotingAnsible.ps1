#Requires -Version 3.0

# Configure a Windows host for remote management with Ansible
# -----------------------------------------------------------
#
# This script checks the current WinRM (PS Remoting) configuration and makes
# the necessary changes to allow Ansible to connect, authenticate and
# execute PowerShell commands.
#
# All events are logged to the Windows EventLog, useful for unattended runs.
#
# Use option -Verbose in order to see the verbose output messages.
#
# Use option -EnableCredSSP to enable CredSSP as an authentication option.
#
# Use option -DisableBasicAuth to disable basic authentication.
#
# Use option -CreateNewLocalAdminUser to create new admin local user, 
# setting username password on the variable

# Rewritten by Essa Jiwa Permana <permana@mentorin.id>
# from https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
#
# Version 1.0 - 2018-02-24

# Support -Verbose option
[CmdletBinding()]

Param (
    [switch]$EnableCredSSP,
    [switch]$CreateNewLocalAdminUser = $true
)

Function Write-Log
{
    $Message = $args[0]
    Write-EventLog -LogName Application -Source $EventSource -EntryType Information -EventId 1 -Message $Message
}

Function Write-VerboseLog
{
    $Message = $args[0]
    Write-Verbose $Message
    Write-Log $Message
}

Function Write-HostLog
{
    $Message = $args[0]
    Write-Output $Message
    Write-Log $Message
}

# Setup error handling.
Trap
{
    $_
    Exit 1
}
$ErrorActionPreference = "Stop"

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if (-Not $myWindowsPrincipal.IsInRole($adminRole))
{
    Write-Output "ERROR: You need elevated Administrator privileges in order to run this script."
    Write-Output "       Start Windows PowerShell by using the Run as Administrator option."
    Exit 2
}

$EventSource = $MyInvocation.MyCommand.Name
If (-Not $EventSource)
{
    $EventSource = "Powershell CLI"
}

If ([System.Diagnostics.EventLog]::Exists('Application') -eq $False -or [System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False)
{
    New-EventLog -LogName Application -Source $EventSource
}

# Detect PowerShell version.
If ($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Log "PowerShell version 3 or higher is required."
    Throw "PowerShell version 3 or higher is required."
}

# Find and start the WinRM service.
Write-Verbose "Verifying WinRM service."
If (!(Get-Service "WinRM"))
{
    Write-Log "Unable to find the WinRM service."
    Throw "Unable to find the WinRM service."
}
ElseIf ((Get-Service "WinRM").Status -ne "Running")
{
    Write-Verbose "Setting WinRM service to start automatically on boot."
    Set-Service -Name "WinRM" -StartupType Automatic
    Write-Log "Set WinRM service to start automatically on boot."
    Write-Verbose "Starting WinRM service."
    Start-Service -Name "WinRM" -ErrorAction Stop
    Write-Log "Started WinRM service."

}

# WinRM should be running; check that we have a PS session config.
If (!(Get-PSSessionConfiguration -Verbose:$false) -or (!(Get-ChildItem WSMan:\localhost\Listener)))
{
  If ($SkipNetworkProfileCheck) {
    Write-Verbose "Enabling PS Remoting without checking Network profile."
    Enable-PSRemoting -SkipNetworkProfileCheck -Force -ErrorAction Stop
    Write-Log "Enabled PS Remoting without checking Network profile."
  }
  Else {
    Write-Verbose "Enabling PS Remoting."
    Enable-PSRemoting -Force -ErrorAction Stop
    Write-Log "Enabled PS Remoting."
  }
}
Else
{
    Write-Verbose "PS Remoting is already enabled."
}

# Check for basic authentication.
$basicAuthSetting = Get-ChildItem WSMan:\localhost\Service\Auth | Where-Object {$_.Name -eq "Basic"}

If (($basicAuthSetting.Value) -eq $false)
{
    Write-Verbose "Enabling basic auth support."
    Set-Item -Path "WSMan:\localhost\Service\Auth\Basic" -Value $true
    Write-Log "Enabled basic auth support."
}
Else
{
    Write-Verbose "Basic auth is already enabled."
}

# Check for allow unencrypted connection.
$unencryptedConnSetting = Get-ChildItem WSMan:\localhost\Service | Where-Object {$_.Name -eq "AllowUnencrypted"}

If (($unencryptedConnSetting.Value) -eq $false)
{
    Write-Verbose "Enabling basic auth support."
    Set-Item -Path "WSMan:\localhost\Service\AllowUnencrypted" -Value $true
    Write-Log "Allow unencrypted connection."
}
Else
{
    Write-Verbose "Unencrypted conn is already allowed."
}

# Only allow specified subnet range to connect to
$Subnet = "please specify or delete this block if you want access from anywehre"
Write-Verbose "Set IPv4Filter settings."
Set-Item -Path "WSMan:\localhost\Service\IPv4Filter" -Value $Subnet
Write-Log "Set IPv4Filter."


# If EnableCredSSP if set to true
If ($EnableCredSSP)
{
    # Check for CredSSP authentication
    $credsspAuthSetting = Get-ChildItem WSMan:\localhost\Service\Auth | Where {$_.Name -eq "CredSSP"}
    If (($credsspAuthSetting.Value) -eq $false)
    {
        Write-Verbose "Enabling CredSSP auth support."
        Enable-WSManCredSSP -role server -Force
        Write-Log "Enabled CredSSP auth support."
    }
}

# Setup new local admin user
$Username = "change this to desired username"
$Password = "change this to desired password"

$group = "Administrators"
If ($CreateNewLocalAdminUser)
{
    $adsi = [ADSI]"WinNT://$env:COMPUTERNAME"
    $existing = $adsi.Children | where {$_.SchemaClassName -eq 'user' -and $_.Name -eq $Username }
    if ($existing -eq $null) {

        Write-VerboseLog "Creating new local user $Username."
        & NET USER $Username $Password /add /y /expires:never
        
        Write-VerboseLog "Adding local user $Username to $group."
        & NET LOCALGROUP $group $Username /add

    }
    else {
        Write-VerboseLog "Setting password for existing local user $Username."
        $existing.SetPassword($Password)
    }

    Write-Verbose "Ensuring password for $Username never expires."
    & WMIC USERACCOUNT WHERE "Name='$Username'" SET PasswordExpires=FALSE
}
Write-VerboseLog "PS Remoting and new user has been successfully configured for Ansible."
