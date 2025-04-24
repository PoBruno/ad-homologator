# Script para instalar a role de Active Directory em um Windows Server limpinho
param(
  [Parameter(Mandatory=$false)]
  [string]$DomainNetbiosName         = $env:COMPUTERNAME,
  [string]      $DomainSuffix        = ".lan",
  [string]      $DomainName          = "$($DomainNetbiosName)$($DomainSuffix)",
  [string]      $DatabasePath        = "C:\Windows\NTDS",
  [string]      $SysvolPath          = "C:\Windows\SYSVOL",
  [string]      $LogPath             = "C:\Windows\NTDS",
  [string]      $SafeModeAdministratorPassword = "P@ssw0rd!"
)

Import-Module ServerManager
Install-WindowsFeature AD-Domain-Services -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature DNS -IncludeAllSubFeature -IncludeManagementTools
Import-Module ADDSDeployment
Import-Module DnsServer

Install-ADDSForest `
  -DomainName $DomainName `
  -DomainNetbiosName $DomainNetbiosName `
  -DatabasePath $DatabasePath `
  -SysvolPath $SysvolPath `
  -LogPath $LogPath `
  -SafeModeAdministratorPassword (ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force)

# Reiniciar o servidor para concluir a configuração
Write-Host "Reboot..."
pause
Restart-Computer -Force

