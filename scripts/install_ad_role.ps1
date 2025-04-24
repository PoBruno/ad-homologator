# Script para instalar a role de Active Directory em um Windows Server limpo

param(
    [string]$DomainSuffix = "lan" # Sufixo do domínio, ex: .lan, .local
    [string]$NetBio = $env:COMPUTERNAME # Nome NetBIOS do domínio
    
)

# Obter o hostname atual do servidor
$FQDN = "$($env:COMPUTERNAME).$($DomainSuffix)"

# Instalar a role de Active Directory
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Importar o módulo de implantação do AD
Import-Module ADDSDeployment

# Configurar o domínio usando o hostname atual
Write-Host "Configurando o domínio como: $FQDN"
Install-ADDSForest -DomainName $FQDN -Force -NoRebootOnCompletion

# Reiniciar o servidor para concluir a configuração
Restart-Computer -Force