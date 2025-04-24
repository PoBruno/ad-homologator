# Script para instalar a role de Active Directory em um Windows Server limpo

param(
    [string]$Hostname = "bionet",
    [string]$Domain = ".lan"
)

# Configurar o hostname
Rename-Computer -NewName $Hostname -Force -Restart:$false

# Instalar a role de Active Directory
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Importar o módulo de implantação do AD
Import-Module ADDSDeployment

# Configurar o domínio
Install-ADDSForest -DomainName "$Hostname$Domain" -Force -NoRebootOnCompletion

# Reiniciar o servidor para concluir a configuração
Restart-Computer -Force