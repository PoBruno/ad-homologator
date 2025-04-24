# Script para instalar a role de Active Directory em um Windows Server limpo

param(
    [string]$DomainSuffix = ".lan",
    [ValidateSet('Win2008','Win2008R2','Win2012','Win2012R2','Win2016','Win2019','WinThreshold')] 
    [string]$ForestMode = 'Win2016',
    [ValidateSet('Win2008','Win2008R2','Win2012','Win2012R2','Win2016','Win2019','WinThreshold')] 
    [string]$DomainMode = 'Win2016',
    [securestring]$SafeModeAdministratorPassword = (Read-Host -Prompt "Digite a senha do DSRM (modo de segurança de restauração de serviços de diretório)" -AsSecureString),
    [switch]$InstallDNS = $true,
    [switch]$CreateDnsDelegation = $false,
    [string]$DatabasePath = "C:\\Windows\\NTDS",
    [string]$LogPath = "C:\\Windows\\NTDS",
    [string]$SysvolPath = "C:\\Windows\\SYSVOL",
    [string]$SiteName = $env:COMPUTERNAME
)

# Obter o hostname atual do servidor
$FQDN = "$($env:COMPUTERNAME).$($DomainSuffix)"

# Instalar a role de Active Directory
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Importar o módulo de implantação do AD
Import-Module ADDSDeployment

# Parâmetros da floresta e domínio
$FullDomainName = "$($env:COMPUTERNAME)$($DomainSuffix)"
Write-Host "Configurando domínio: $FullDomainName"

# Instalação e promoção
Install-ADDSForest \
    -DomainName $FullDomainName \
    -ForestMode $ForestMode \
    -DomainMode $DomainMode \
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword \
    -InstallDNS:$InstallDNS \
    -CreateDnsDelegation:$CreateDnsDelegation \
    -DatabasePath $DatabasePath \
    -LogPath $LogPath \
    -SysvolPath $SysvolPath \
    -SiteName $SiteName \
    -Force \
    -NoRebootOnCompletion

# Reiniciar o servidor para concluir a configuração
Restart-Computer -Force