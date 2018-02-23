# This script will run the EnableRemotingAnsible.ps1 script remotely 
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