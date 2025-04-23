# Bruno Gomes - Active Directory Populator

# Forçar uso de TLS 1.2 para conexões HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Função para limpar strings (remove tudo que não seja A–Z, a–z ou 0–9)
function Clean-StringForSam {
    param([string]$InputString)
    return ($InputString -replace '[^A-Za-z0-9]', '')
}

# Obter domínio e paths base
$ADDomain    = Get-ADDomain
$Root        = $ADDomain.DistinguishedName 
$OUCompany   = "AD-" + $ADDomain.NetBIOSName
$OU          = "OU=$OUCompany,$Root"

# Criar OU principal, se necessário
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OUCompany'" -SearchBase $Root -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $OUCompany -Path $Root -ProtectedFromAccidentalDeletion $False
}

# Departamentos e cargos
$departments = @(
    [pscustomobject]@{ Name = "Contabilidade"; Positions = @("Gerente", "Contador", "Escrituração", "Gerente de Auditoria Interna", "Gerente de Contabilidade", "Auxiliar de Contabilidade", "Contador Gerencial", "Consultor Fiscal", "Assistente de Contabilidade") },
    [pscustomobject]@{ Name = "Consultoria"; Positions = @("Gerente", "Administrador", "Consultoria de Finanças", "Consultoria de Marketing", "Estruturação") },
    [pscustomobject]@{ Name = "Atendimento ao cliente"; Positions = @("Gestor de Atendimento ao Cliente", "Atendimento Pleno", "Atendimento Junior", "Assistente de Atendimento ao Cliente", "Treinador", "Call Center", "Representantes de suporte ao cliente") },
    [pscustomobject]@{ Name = "Engenharia"; Positions = @("Gerente", "Engenheiro Nível 1", "Engenheiro Nível 2", "Engenheiro Nível 3") },
    [pscustomobject]@{ Name = "Executivo"; Positions = @("Executivo", "Assistente Executivo","Auxiliar Executivo") },
    [pscustomobject]@{ Name = "Financeiro"; Positions = @("Gerente", "Assessor Financeiro", "Estagiário Financeiro", "Faturamento", "Cobranças", "Assistente de Faturamento", "Assistente de Cobranças", "Auxiliar Financeiro") },
    [pscustomobject]@{ Name = "Recursos Humanos"; Positions = @("Gerente", "Recrutamento e Seleção", "Departamento Pessoal", "Treinamento e Desenvolvimento", "Consultoria de Recursos Humanos", "Assistente Departamento Pessoal", "Auxiliar Departamento Pessoal") },
    [pscustomobject]@{ Name = "Fabricação"; Positions = @("Gerente", "Setor Primário", "Auxiliar Setor Primário", "Operador de Manufatura I", "Operador de Manufatura II", "Fabricação Nível 2", "Fabricação Nível 3") },
    [pscustomobject]@{ Name = "Marketing"; Positions = @("Gerente", "Especialista em Mídia Social", "Líder da Comunidade", "Marketing Digital", "Assistente de Marketing Digital", "Marketing Interno", "Assistente de Marketing Interno", "Marketing de Conteúdo", "Assistente Marketing de Conteúdo") },
    [pscustomobject]@{ Name = "Compras"; Positions = @("Gerente", "Assistente de Compras", "Analista de Compras", "Comprador Junior", "Comprador Pleno", "Comprador Sênior", "Pedido") },
    [pscustomobject]@{ Name = "Qualidade"; Positions = @("Gerente", "Analista de Controle de Qualidade", "Assistente de Controle de Qualidade", "Auxiliar de Controle de Qualidade", "Auditor de Controle de Qualidade", "Consultor de Qualidade", "Coordenador de Qualidade", "Gerente de Controle de Qualidade", "Supervisor de Controle de Qualidade") },
    [pscustomobject]@{ Name = "Vendas"; Positions = @("Gerente", "Representante de Vendas Regional", "Representante de Vendas Nacional", "Novo Negócio") }
)

# Paths fixos em cada OU de departamento
$DPaths    = @("Computers","Users")
# Cidades alvo
$Cidades   = @("Joinville","SaoPaulo","Curitiba","Itajai","Miami","Salvador")

# UPN baseado em DNSRoot (ex.: @contoso.com)
$UPNDomain      = "@" + $ADDomain.DNSRoot

# Senha padrão (convertida para SecureString)
$Password       = 'Pa$$w0rd'
$securePassword = ConvertTo-SecureString -AsPlainText $Password -Force

# Baixar CSVs de nomes
$FirstNames = (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/PoBruno/ad-homologator/main/data/FirstNames.csv").Content |
              ConvertFrom-Csv -Delimiter ',' -Header 'FirstName'
$LastNames  = (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/PoBruno/ad-homologator/main/data/LastNames.csv").Content |
              ConvertFrom-Csv -Delimiter ',' -Header 'LastName'

# Loop principal: Cidades → Departamentos → Paths
foreach ($Cidade in $Cidades) {
    $CityOUPath = "OU=$Cidade,$OU"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$Cidade'" -SearchBase $OU -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $Cidade -Path $OU
    }

    # Criar OU de Groups para a cidade
    $OUGroupsPath = "OU=Groups,$CityOUPath"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Groups'" -SearchBase $CityOUPath -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name "Groups" -Path $CityOUPath
    }

    foreach ($Department in $departments) {
        $DepOUPath = "OU=$($Department.Name),$CityOUPath"
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($Department.Name)'" -SearchBase $CityOUPath -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $Department.Name -Path $CityOUPath
        }

        foreach ($DPath in $DPaths) {
            $PathToCreate = "OU=$DPath,$DepOUPath"
            if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$DPath'" -SearchBase $DepOUPath -ErrorAction SilentlyContinue)) {
                New-ADOrganizationalUnit -Name $DPath -Path $DepOUPath
            }

            if ($DPath -eq "Users") {
                # Preparar nomes de OU e grupo
                $OUUser    = "OU=Users,$DepOUPath"
                $rawGroup  = "$Cidade.$($Department.Name)"
                $SamaGroup = (Clean-StringForSam $rawGroup).ToLower()
                $GroupName = "$Cidade - $($Department.Name)"

                # Criar grupo de segurança se não existir
                if (-not (Get-ADGroup -Filter "SamAccountName -eq '$SamaGroup'" -SearchBase $OUGroupsPath -ErrorAction SilentlyContinue)) {
                    New-ADGroup `
                        -Name           $GroupName `
                        -SamAccountName $SamaGroup `
                        -GroupCategory  Security `
                        -GroupScope     Global `
                        -DisplayName    $GroupName `
                        -Path           $OUGroupsPath
                }

                # Gerar usuários
                $UserCount = 0
                $MaxUsers  = Get-Random -Minimum 5 -Maximum 20

                while ($UserCount -lt $MaxUsers) {
                    # Pega nomes aleatórios
                    $First = (Get-Random -InputObject $FirstNames).FirstName
                    $Last  = (Get-Random -InputObject $LastNames).LastName
                    $Fname = (Get-Culture).TextInfo.ToTitleCase($First)
                    $Lname = (Get-Culture).TextInfo.ToTitleCase($Last)

                    # Limpa sobrenome para sAMAccountName
                    $CleanLast = Clean-StringForSam $Lname

                    # Monta sAMAccountName: inicial + sobrenome + número aleatório
                    $sAMAccountName = ($Fname.Substring(0,1) + $CleanLast).ToLower() + (Get-Random -Minimum 10 -Maximum 99)

                    # Só tenta criar se não existir ainda
                    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sAMAccountName'" -ErrorAction SilentlyContinue)) {
                        $displayName = "$Fname $Lname"
                        $title       = $Department.Positions | Get-Random
                        $Office      = "$($ADDomain.NetBIOSName) - $Cidade"
                        $areaCodes   = 47, 11, 21, 49, 53, 13
                        $areaCode    = $areaCodes | Get-Random
                        $phone       = "($areaCode) $(Get-Random -Minimum 8000 -Maximum 9999)-$(Get-Random -Minimum 1000 -Maximum 9999)"

                        # --- Criação com try/catch ---
                        $userCreated = $false
                        try {
                            New-ADUser `
                                -Name               $displayName `
                                -GivenName          $Fname `
                                -Surname            $Lname `
                                -DisplayName        $displayName `
                                -SamAccountName     $sAMAccountName `
                                -UserPrincipalName  "$sAMAccountName$UPNDomain" `
                                -AccountPassword    $securePassword `
                                -Enabled            $true `
                                -Path               $OUUser `
                                -Company            $Office `
                                -Department         $Department.Name `
                                -Title              $title `
                                -OfficePhone        $phone `
                                -EmailAddress       "$sAMAccountName$UPNDomain" `
                                -ErrorAction Stop

                            $userCreated = $true
                        }
                        catch {
                            Write-Warning ("Usuário {0} não pôde ser criado: {1}" -f $sAMAccountName, $_.Exception.Message)
                        }

                        # Se criou, adiciona proxy e grupo
                        if ($userCreated) {
                            try {
                                Set-ADUser -Identity $sAMAccountName `
                                           -Add @{ proxyAddresses = "SMTP:$sAMAccountName$UPNDomain" } `
                                           -ErrorAction Stop
                            }
                            catch {
                                Write-Warning ("Não foi possível setar proxyAddresses para {0}: {1}" -f $sAMAccountName, $_.Exception.Message)
                            }

                            try {
                                Add-ADGroupMember -Identity $SamaGroup `
                                                  -Members  $sAMAccountName `
                                                  -ErrorAction Stop
                            }
                            catch {
                                Write-Warning ("Não foi possível adicionar {0} ao grupo {1}: {2}" -f $sAMAccountName, $SamaGroup, $_.Exception.Message)
                            }

                            $UserCount++
                        }
                        else {
                            Write-Verbose "Ignorando usuário duplicado ou inválido: $sAMAccountName"
                        }
                    }
                }
            }
        }
    }
}
