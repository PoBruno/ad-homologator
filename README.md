# AD Homolog Ator

Ferramenta para automatizar a criação e simulação de ambientes Active Directory para testes e homologação de desenvolvimentos.

### Sobre o Projeto

Este projeto nasceu da necessidade recorrente de criar ambientes Active Directory para testes e homologações. Durante o desenvolvimento de automações e scripts para AD, é crucial ter um ambiente que simule situações reais e casos diversos, como:

- Estruturas organizacionais complexas
- Histórico de logins distribuídos no tempo
- Dados de usuários com atributos preenchidos
- Grupos e permissionamentos realistas
- Simulação de atividades diárias

A criação manual destes ambientes é trabalhosa e consome tempo significativo do processo de desenvolvimento. Esta ferramenta automatiza todo esse processo, permitindo que desenvolvedores e administradores de sistemas:

- Criem rapidamente um ambiente AD completo
- Simulem atividades de usuários ao longo do tempo
- Testem scripts e automações em um ambiente próximo ao real
- Validem comportamentos em diferentes cenários
- Reduzam o tempo de preparação de ambientes de homologação


### Uso Rápido

1. Configure o TLS 1.2:
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

2. Execute o povoamento do AD:
```powershell
$Script = Invoke-WebRequest https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/ADObject_Populate.ps1 
Invoke-Expression "$($Script.Content)"
```

3. Execute a simulação de logons:
```powershell
$Script = Invoke-WebRequest https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/ADUser_lastLogon_simulation.ps1
Invoke-Expression "$($Script.Content)"
```

### Instalação do Active Directory

Para instalar a role de Active Directory em um Windows Server limpo, execute o seguinte comando no PowerShell. O script usará o hostname atual do servidor para criar o domínio (ex: se o hostname for `ADLAB`, o domínio será `ADLAB.lan`):

```powershell
$Script = Invoke-WebRequest -Uri https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/install_ad_role.ps1
Invoke-Expression "$($Script.Content)"
```

Por padrão, o script utiliza o sufixo de domínio `.lan`. Esse valor pode ser alterado ao passar o parâmetro `-DomainSuffix` para o script:

```powershell
.\install_ad_role.ps1 -DomainSuffix .local
```

### Descrição de Scripts

Este projeto contém scripts PowerShell para:

1. **ADObject_Populate.ps1**: Script de povoamento que:
   - Cria estrutura organizacional com múltiplas OUs
   - Gera usuários com dados realísticos
   - Organiza por departamentos e localidades
   - Define grupos de segurança
   - Configura atributos padrão (email, telefone, cargo, etc)
   - Senha padrão para todos usuários: Pa$$w0rd

2. **ADUser_lastLogon_simulation.ps1**: Script de simulação de logons que:
   - Simula acessos de usuários em datas aleatórias
   - Atualiza lastLogonTimestamp dos objetos
   - Permite definir período de simulação
   - Executa logons distribuídos temporalmente
   - Mantém histórico realístico de acessos

### Parâmetros da Simulação de Logons

O script de simulação aceita os seguintes parâmetros:

- **DataInicio**: Data inicial no formato dd/MM/yyyy (padrão: 1 ano atrás)
- **DataFim**: Data final no formato dd/MM/yyyy (padrão: hoje)
- **Runs**: Quantidade de datas aleatórias para simular (padrão: 30)

Exemplo com parâmetros:
```powershell
$Script = Invoke-WebRequest https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/ADUser_lastLogon_simulation.ps1
Invoke-Expression "$($Script.Content) -DataInicio 01/01/2024 -DataFim 31/12/2024 -Runs 50"
```

### Estrutura Gerada

O script de povoamento cria:
- OUs por cidade (Joinville, São Paulo, Curitiba, etc)
- Departamentos padronizados (TI, RH, Financeiro, etc)
- Subpastas Users e Computers
- Grupos de segurança por departamento
- Usuários com atributos preenchidos

### Objetivos Futuros

- [ ] Parametrização da senha padrão via linha de comando
- [ ] Simulação de logs de auditoria (login failures, password changes, etc)
- [ ] Geração de computadores com nomes realísticos e atributos
- [ ] Simulação de eventos de segurança (4624, 4625, 4634, etc)
- [ ] Criação de GPOs com configurações comuns
- [ ] Simulação de atividades de serviço (service accounts)
- [ ] Geração de logs do File Server (acessos a arquivos/pastas)
- [ ] Simulação de mudanças de senha periódicas
- [ ] Criação de Trust Relations entre domínios
- [ ] Geração de certificados e configuração de PKI
- [ ] Simulação de movimentação entre OUs
- [ ] Implementação de LAPS (Local Administrator Password Solution)
- [ ] Simulação de acesso remoto (VPN/RDP)
- [ ] Criação de sites e subnets para replicação
- [ ] Geração de backup history e system state backups

