<#
.SYNOPSIS
 Simula logons para **todos** os usuários em N datas diferentes,
 ajustando o relógio do DC de homologação para forçar atualização
 de lastLogonTimestamp.

.PARAMETER DataInicio
 Data inicial (dd/MM/yyyy). Padrão: 1 ano atrás.

.PARAMETER DataFim
 Data final (dd/MM/yyyy). Padrão: hoje.

.PARAMETER Runs
 Quantas datas aleatórias gerar. Padrão: 30.

.EXAMPLE
 .\Simula-LastLogon.ps1
 .\Simula-LastLogon.ps1 -DataInicio 01/02/2024 -DataFim 20/04/2025 -Runs 5
#>

[CmdletBinding()]
param(
    [string]$DataInicio = (Get-Date).AddYears(-1).ToString('dd/MM/yyyy'),
    [string]$DataFim    = (Get-Date).ToString('dd/MM/yyyy'),
    [int]   $Runs       = 30
)

# --- Helpers ---
function Get-RandomDates {
    param([DateTime]$Start, [DateTime]$End, [int]$Count)
    1..$Count | ForEach-Object {
        $t = Get-Random -Minimum $Start.Ticks -Maximum $End.Ticks
        [DateTime]::new($t)
    } | Sort-Object
}

function Simulate-LogonAll {
    param(
        [array] $Users,
        [string] $LdapPath,
        [string] $Password
    )
    # embaralha ordem antes de cada rodada
    $shuf = $Users | Get-Random -Count $Users.Count
    foreach ($u in $shuf) {
        try {
            $entry = New-Object System.DirectoryServices.DirectoryEntry(
                $LdapPath, $u.UserPrincipalName, $Password
            )
            $null = $entry.NativeObject
            Write-Host "  [OK]   $($u.SamAccountName)"
        }
        catch {
            Write-Warning "  [FAIL] $($u.SamAccountName): $($_.Exception.Message)"
        }
    }
}

# cultura pt-BR para parse
$culture = [Globalization.CultureInfo]::GetCultureInfo('pt-BR')

# validação de datas
try {
    $startDate = [DateTime]::ParseExact($DataInicio, 'dd/MM/yyyy', $culture)
    $endDate   = [DateTime]::ParseExact($DataFim,    'dd/MM/yyyy', $culture)
}
catch {
    Write-Error "Formato inválido. Use dd/MM/yyyy."
    exit 1
}
if ($startDate -gt $endDate) {
    Write-Error "DataInício não pode ser maior que DataFim."
    exit 1
}

# preserva data original
$orig = Get-Date

# gera as datas
$dates = Get-RandomDates -Start $startDate -End $endDate -Count $Runs

# carrega AD e obtém todos os usuários habilitados
Import-Module ActiveDirectory -ErrorAction Stop
$allUsers = Get-ADUser -Filter 'Enabled -eq $true' -Properties UserPrincipalName,SamAccountName
if (-not $allUsers) {
    Write-Warning "Nenhum usuário habilitado encontrado."
    exit 0
}

# prepara LDAP e senha fixa
$root     = [ADSI]"LDAP://RootDSE"
$ldapPath = "LDAP://$($root.defaultNamingContext)"
$fixedPwd = 'Pa$$w0rd'

# loop principal: para cada data, ajusta e faz bind de todos
foreach ($dt in $dates) {
    Write-Host "`n==> Ajustando data para $($dt.ToString('dd/MM/yyyy HH:mm:ss'))"
    try {
        Set-Date -Date $dt -ErrorAction Stop
    }
    catch {
        Write-Warning "Falha em Set-Date: $($_.Exception.Message)"
        continue
    }

    Write-Host "Simulando logon para $($allUsers.Count) usuários..."
    Simulate-LogonAll -Users $allUsers -LdapPath $ldapPath -Password $fixedPwd
}

# restaura data original
Write-Host "`nRestaurando data original: $($orig.ToString('dd/MM/yyyy HH:mm:ss'))"
Set-Date -Date $orig

Write-Host "`nProcesso concluído."
