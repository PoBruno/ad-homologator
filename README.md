
# AD Homolog Ator

Implanting Windows Server AD populating for Lab

## Prerequisites
- Run Powershell as Administrator on terminal that run the automations scripts.

    `[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`

- Populate AD

    ```PowerShell
    $Script = Invoke-WebRequest https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/ADObject_Populate.ps1 
    Invoke-Expression "$($Script.Content)"
    ```

- Simulation lastLogon

    ```PowerShell
    $Script = Invoke-WebRequest https://raw.githubusercontent.com/pobruno/ad-homologator/main/scripts/ADUser_lastLogon_simulation.ps1
    Invoke-Expression "$($Script.Content)"
    ```
