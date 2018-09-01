# KB USERS AD - https://technet.microsoft.com/pt-br/library/cc700835.aspx

#Start-Transcript 'C:\Suporte Windows\saida.txt'
Function Get-LocalGroupMemberComputers {
    [cmdletbinding()]
    #region Parameters
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias("Computer","__Server","IPAddress","CN","dnshostname")]
        [string[]]$Computername = $env:COMPUTERNAME,
        [parameter()]
        [string]$Group = 'Administrators',
        [parameter()]
        [string[]]$ValidMember,
        [parameter()]
        [Alias("MaxJobs")]
        [int]$Throttle = 10
    )
    #endregion Parameters
    Begin {
        #region Functions
        #Function to perform runspace job cleanup
        Function Get-RunspaceData {
            [cmdletbinding()]
            param(
                [switch]$Wait
            )
            Do {
                $more = $false         
                Foreach($runspace in $runspaces) {
                    If ($runspace.Runspace.isCompleted) {
                        $runspace.powershell.EndInvoke($runspace.Runspace)
                        $runspace.powershell.dispose()
                        $runspace.Runspace = $null
                        $runspace.powershell = $null                 
                    } ElseIf ($runspace.Runspace -ne $null) {
                        $more = $true
                    }
                }
                If ($more -AND $PSBoundParameters['Wait']) {
                    Start-Sleep -Milliseconds 100
                }   
                #Clean out unused runspace jobs
                $temphash = $runspaces.clone()
                $temphash | Where {
                    $_.runspace -eq $Null
                } | ForEach {
                    Write-Verbose ("Removing {0}" -f $_.computer)
                    $Runspaces.remove($_)
                }             
            } while ($more -AND $PSBoundParameters['Wait'])
        }
        #endregion Functions
    
        #region Splat Tables
        #Define hash table for Get-RunspaceData function
        $runspacehash = @{}

        $testConnectionHash = @{
            Count = 1
            Quiet = $True
        }

        #endregion Splat Tables

        #region ScriptBlock
        $scriptBlock = {
            Param ($Computer,$Group,$ValidMember,$testConnectionHash)
            Write-Verbose ("{0}: Testing if online" -f $Computer)
            $testConnectionHash.Computername = $Computer
            If (Test-Connection @testConnectionHash) {
		        $adsicomputer = [ADSI]("WinNT://$Computer,computer")
    	        $localgroup = $adsicomputer.children.find($Group)
                If ($localGroup) {
    	            $localgroup.psbase.invoke("members") | ForEach {
                        Try {
                            $member = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                            If ($ValidMember -notcontains $member) {
                                New-Object PSObject -Property @{
                                    Computername = $Computer
                                    Group = $Group
                                    Account = $member
                                    IsValid = $FALSE
                                }
                            } Else {
                                New-Object PSObject -Property @{
                                    Computername = $Computer
                                    Group = $Group
                                    Account = $member
                                    IsValid = $TRUE
                                }
                            }
                        } Catch {
                            Write-Warning ("{0}: {1}" -f $Computer,$_.exception.message)
                        }
                    }
                } Else {
                    Write-Warning ("{0} does not exist on {1}!" -f $Group,$Computer)
                }
            } Else {
                Write-Warning ("{0}: Unable to connect!" -f $Computer)
            }           
        }
        #endregion ScriptBlock

        #region Runspace Creation
        Write-Verbose ("Creating runspace pool and session states")
        $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
        $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
        $runspacepool.Open()  
        
        Write-Verbose ("Creating empty collection to hold runspace jobs")
        $Script:runspaces = New-Object System.Collections.ArrayList        
        #endregion Runspace Creation
    }
    Process {
        ForEach ($Computer in $Computername) {
            #Create the powershell instance and supply the scriptblock with the other parameters 
            $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($computer).AddArgument($Group).AddArgument($ValidMember).AddArgument($testConnectionHash)
           
            #Add the runspace into the powershell instance
            $powershell.RunspacePool = $runspacepool
           
            #Create a temporary collection for each runspace
            $temp = "" | Select-Object PowerShell,Runspace,Computer
            $Temp.Computer = $Computer
            $temp.PowerShell = $powershell
           
            #Save the handle output when calling BeginInvoke() that will be used later to end the runspace
            $temp.Runspace = $powershell.BeginInvoke()
            Write-Verbose ("Adding {0} collection" -f $temp.Computer)
            $runspaces.Add($temp) | Out-Null
           
            Write-Verbose ("Checking status of runspace jobs")
            Get-RunspaceData @runspacehash        
        }
    }
    End {
        Write-Verbose ("Finish processing the remaining runspace jobs: {0}" -f (@(($runspaces | Where {$_.Runspace -ne $Null}).Count)))
        $runspacehash.Wait = $true
        Get-RunspaceData @runspacehash
    
        #region Cleanup Runspace
        Write-Verbose ("Closing the runspace pool")
        $runspacepool.close()  
        $runspacepool.Dispose() 
        #endregion Cleanup Runspace
    } 

 }  #FUNCIONANDO

Function Listcomp {
foreach ($server in $servers){
#$grupos = Get-LocalGroup -Name @("administrators","administradores") -ErrorAction SilentlyContinue 

Write-host "Servidor $server " 
Write-host "Administradores:" 

foreach ($grupo in $grupos){

#MAPEAMENTO DE SERVIDOR DE OUTROS DOMINIOS PARA CONECTAR PELO GTW
$mapdrive = New-PSDrive -Name $server -PSProvider "FileSystem" -Root "\\$server\c$" -Credential $cred -ErrorAction SilentlyContinue

Get-LocalGroupMemberComputers -Group $grupo -Computername $server 

Remove-PSDrive -Name $server -ErrorAction SilentlyContinue
}

Write-host "============================================"  

}

} #FUNCIONANDO

Function ChangeGroup {

foreach ($server in $servers){

Write-host "Servidor $server " 
Write-host "Alteracao do grupo Administrators em andamento..." 

foreach ($grupo in $grupos){

#MAPEAMENTO DE SERVIDOR DE OUTROS DOMINIOS PARA CONECTAR PELO GTW
$mapdrive = New-PSDrive -Name $server -PSProvider "FileSystem" -Root "\\$server\c$" -Credential $cred -ErrorAction SilentlyContinue

$group = [ADSI]"WinNT://$server/$grupo,group"

Remove-PSDrive -Name $server -ErrorAction SilentlyContinue
}

Write-host "============================================"  











$group = [ADSI]"WinNT://$server/$appgrupo,group"

$group.Add("WinNT://$server/$usuario,user")

}

}  #CRIANDO

Function CompareComp {



} #CRIANDO

Function SpecialGroup {



} #CRIANDO

$gruposadm = "administradores","administrators"
$specialgrpbkp = "power users","remote desktop users","backup operators"
$specialgrpcoti = "power users","remote desktop users"

$serveribi = "C:\Suporte Windows\Lista\serveribi.txt"
$serverd98 = "C:\Suporte Windows\Lista\serverd98.txt"
$serverbca = "C:\Suporte Windows\Lista\servercartoes.txt"
$serveramx = "C:\Suporte Windows\Lista\serveramx.txt"


Write-Host $null >> $serveribi
Write-Host $null >> $serverd98
Write-Host $null >> $serverbca
Write-Host $null >> $serveramx


$domain = Read-Host "Qual dominio vai verificar?
(A) BANCOIBI
(B) D9803D01
(C) BRADESCOCARTOES
(D) AMEXDC
(E) GERAL
"

switch ($domain){
    A { $cred = Get-Credential -Message "Entrar com as credenciais do BANCOIBI"
       read-host "Insira os nomes dos servidores no arquivo $serveribi (1 nome por linha), pressione <ENTER> para abrir o arquivo"
      notepad $serveribi 
      pause
        $servers = gc $serveribi
        $domain = "BANCOIBI"
      }

    B { $cred = Get-Credential -Message "Entrar com as credenciais do D9803D01"
       read-host "Insira os nomes dos servidores no arquivo $serverd98 (1 nome por linha), pressione <ENTER> para abrir o arquivo"
      notepad $serverd98
      pause
       $servers = gc $serverd98
       $domain = "D9803D01"
      }

    C { $cred = Get-Credential -Message "Entrar com as credenciais do BRADESCOCARTOES"
        read-host "Insira os nomes dos servidores no arquivo $serverbca (1 nome por linha), pressione <ENTER> para abrir o arquivo"
        notepad $serverbca
        pause
        $servers = gc $serverbca
        $domain = "BRADESCOCARTOES"
      }

    D { $cred = Get-Credential -Message "Entrar com as credenciais do AMEXDC"
        read-host "Insira os nomes dos servidores no arquivo $serveramx (1 nome por linha), pressione <ENTER> para abrir o arquivo"
        notepad $serveramx
        pause
        $servers = gc $serveramx
        $domain = "AMEXDC"
      }
    
    Default {Write-host "Invalido"; exit}
        }

$funcao = Read-Host "O que deseja fazer:
(A) Listar Grupos
(B) Validar de acordo com a baseline
(C) Alterar/Corrigir Grupos
(D) Grupos especiais Backup/Coti"

switch ($funcao){

A {$funcao="lista";listcomp
    $grupos = $gruposadm
 }

 
B {$funcao="valida" 
    $grupos = $gruposadm
    $baseline = Read-Host "Qual baseline para comparacao?
    (A) PADRAO
    (B) BANCO DE DADOS
    (C) APLICACOES
    (D) PERSONALIZADO
    "
    CompareComp
    }


C {$funcao="altera"
    $grupos = $gruposadm
    $baseline = Read-Host "Qual baseline sera aplicado?
    (A) PADRAO
    (B) BANCO DE DADOS
    (C) APLICACOES
    (D) PERSONALIZADO
    "
    ChangeGroup
   }

D {$funcao="especial"
    
    
    $grupos = $grupo
    $baseline = Read-Host "Serao aplicadas permissoes para os grupos COTI e BACKUP
    nos grupos locais:
    (A) PADRAO
    (B) BANCO DE DADOS
    (C) APLICACOES
    (D) PERSONALIZADO
    " 
    SpecialGroup
    }


}



<#

#$servers = gc "C:\Users\lui_e\Desktop\servers.txt"

#$servers="wks01mp"
foreach ($server in $servers){
#$grupos = Get-LocalGroup -Name @("administrators","administradores") -ErrorAction SilentlyContinue 

Write-host "Servidor $server " 


Write-host "Administradores:" 

foreach ($grupo in $grupos){

#MAPEAMENTO DE SERVIDOR DE OUTROS DOMINIOS PARA CONECTAR PELO GTW
$mapdrive = New-PSDrive -Name $server -PSProvider "FileSystem" -Root "\\$server\c$" -Credential $cred -ErrorAction SilentlyContinue

Get-LocalGroupMemberComputers -Group $grupo -Computername $server 

Remove-PSDrive -Name $server -ErrorAction SilentlyContinue
}

Write-host "============================================"  

}

#>


#Clear-Variable 
#Stop-Transcript
