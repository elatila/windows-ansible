# This script taken from https://4sysops.com/archives/use-powershell-invoke-command-to-run-scripts-on-remote-computers/
# it will run the EnableRemotingAnsible.ps1 script remotely 
# on all computer listed on $RemoteComputers variable
# please adjust -FilePath parameter to path where your script reside on local PC
$RemoteComputers = @("PC1","PC2")

ForEach ($Computer in $RemoteComputers)
{
     Try
         {
             Invoke-Command -ComputerName $Computer -FilePath D:\EnableRemotingAnsible.ps1 -ErrorAction Stop
         }
     Catch
         {
             Add-Content Unavailable-Computers.txt $Computer
         }
}
