#Feito por: Luis Antonio Soares da Silva (luissoares@outlook.com)
#VER https://gallery.technet.microsoft.com/scriptcenter/site/search?f%5B0%5D.Type=RootCategory&f%5B0%5D.Value=localaccount&f%5B0%5D.Text=Gerenciamento%20de%20contas%20locais&f%5B1%5D.Type=SubCategory&f%5B1%5D.Value=groups&f%5B1%5D.Text=Grupos

function mapserver {
$mapdrive = New-PSDrive -Name $server -PSProvider "FileSystem" -Root "\\$server\c$" -Credential $cred -ErrorAction SilentlyContinue
}

function  unmap {
Remove-PSDrive -Name $server -Force -ErrorAction SilentlyContinue
}

#Function https://gallery.technet.microsoft.com/scriptcenter/Get-LocalGroupMembers-b714517d #Feito por: Piotrek82 
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

#Function https://gallery.technet.microsoft.com/scriptcenter/Remove-AD-UserGroup-to-f6e9dbfb #Feito por: Jaap Brasser
function Resolve-SamAccount {
<#
.SYNOPSIS
    Helper function that resolves SAMAccount
#>
    param(
        [string]
            $SamAccount
    )
    
    process {
        try
        {
            $ADResolve = ([adsisearcher]"(samaccountname=$Trustee)").findone().properties['samaccountname']
        }
        catch
        {
            $ADResolve = $null
        }

        if (!$ADResolve) {
            Write-Warning "User `'$SamAccount`' not found in AD, please input correct SAM Account"
        }
        $ADResolve
    }
} 

#Function https://gallery.technet.microsoft.com/scriptcenter/Remove-AD-UserGroup-to-f6e9dbfb #Feito por: Jaap Brasser
function Remove-ADAccountasLocalAdministrator {
<#
.SYNOPSIS   
Script to remove an AD User or group from the Administrators group
    
.DESCRIPTION 
The script can use either a plaintext file or a computer name as input and will remove the trustee (user or group) from the Administrators group on the computer
	
.PARAMETER InputFile
A path that contains a plaintext file with computer names

.PARAMETER Computer
This parameter can be used instead of the InputFile parameter to specify a single computer or a series of computers using a comma-separated format
	
.PARAMETER Trustee
The SamAccount name of an AD User or AD Group that is to be removed from the Administrators group

.NOTES   
Name       : Remove-ADAccountasLocalAdministrator.ps1
Author     : Jaap Brasser
Version    : 1.0.0
DateCreated: 2016-08-02
DateUpdated: 2016-08-02

.LINK
http://www.jaapbrasser.com

.EXAMPLE
. .\Remove-ADAccountasLocalAdministrator.ps1

Description
-----------
This command dot sources the script to ensure the Remove-ADAccountasLocalAdministrator function is available in your current PowerShell session

.EXAMPLE   
Remove-ADAccountasLocalAdministrator -Computer Server01 -Trustee JaapBrasser

Description:
Will remove the the JaapBrasser account from the Administrators group on Server01

.EXAMPLE   
Remove-ADAccountasLocalAdministrator -Computer 'Server01','Server02' -Trustee Contoso\HRManagers

Description:
Will remove the HRManagers group in the contoso domain as a member of Administrators group on Server01 and Server02

.EXAMPLE   
Remove-ADAccountasLocalAdministrator -InputFile C:\ListofComputers.txt -Trustee User01

Description:
Will remove the User01 account to the Administrators group on all servers and computernames listed in the ListofComputers file
#>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName= 'InputFile',
                   Mandatory       = $true
        )]
        [string]
            $InputFile,
        [Parameter(ParameterSetName= 'Computer',
                   Mandatory       = $true
        )]
        [string[]]
            $Computer,
        [Parameter(Mandatory=$true)]
        [string]
            $Trustee
    )

    if ($Trustee -notmatch '\\') {
        $ADResolved = (Resolve-SamAccount -SamAccount $Trustee)
        $Trustee = 'WinNT://',"$env:userdomain",'/',$ADResolved -join ''
    } else {
        $ADResolved = ($Trustee -split '\\')[1]
        $DomainResolved = ($Trustee -split '\\')[0]
        $Trustee = 'WinNT://',$DomainResolved,'/',$ADResolved -join ''
    }

    if (!$InputFile) {
	    $Computer | ForEach-Object {
		    Write-Verbose "Removing '$ADResolved' from Administrators group on '$_'"
		    try {
			    ([adsi]"WinNT://$_/Administrators,group").psbase.remove($Trustee)
			    Write-Verbose "Successfully completed command for '$ADResolved' on '$_'"
		    } catch {
			    Write-Warning $_
		    }	
	    }
    } else {
	    if (!(Test-Path -Path $InputFile)) {
		    Write-Warning 'Input file not found, please enter correct path'
	    }
	    Get-Content -Path $InputFile | ForEach-Object {
		    Write-Verbose "Removing '$ADResolved' from Administrators group on '$_'"
		    try {
			    ([adsi]"WinNT://$_/Administrators,group").psbase.remove($Trustee)
			    Write-Verbose 'Successfully completed command'
		    } catch {
			    Write-Warning $_
		    }        
	    }
    }
}

function ADD-ADAccountLocalAdministrator {
<#
.SYNOPSIS   
Script to add an AD User or group to the Local Administrator group
    
.DESCRIPTION 
The script can use either a plaintext file or a computer name as input and will add the trustee (user or group) as an administrator to the computer
	
.PARAMETER InputFile
A path that contains a plaintext file with computer names

.PARAMETER Computer
This parameter can be used instead of the InputFile parameter to specify a single computer or a series of
computers using a comma-separated format
	
.PARAMETER Trustee
The SamAccount name of an AD User or AD Group that is to be added to the Local Administrators group

.NOTES   
Name: Set-ADAccountasLocalAdministrator.ps1
Author: Jaap Brasser
Version: 1.1.1
DateCreated: 2012-09-06
DateUpdated: 2015-11-12

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
.\Set-ADAccountasLocalAdministrator.ps1.ps1 -Computer Server01 -Trustee JaapBrasser

Description:
Will set the the JaapBrasser account as a Local Administrator on Server01

.EXAMPLE   
.\Set-ADAccountasLocalAdministrator.ps1.ps1 -Computer 'Server01,Server02' -Trustee Contoso\HRManagers

Description:
Will set the HRManagers group in the contoso domain as Local Administrators on Server01 and Server02

.EXAMPLE   
.\Set-ADAccountasLocalAdministrator.ps1 -InputFile C:\ListofComputers.txt -Trustee User01

Description:
Will set the User01 account as a Local Administrator on all servers and computernames listed in the ListofComputers file
#>
param(
    [Parameter(ParameterSetName='InputFile')]
    [string]
        $InputFile,
    [Parameter(ParameterSetName='Computer')]
    [string]
        $Computer,
    [string]
        $Trustee
)
<#
.SYNOPSIS
    Function that resolves SAMAccount and can exit script if resolution fails
#>


if (!$Trustee) {
    $Trustee = Read-Host "Please input trustee"
}

if ($Trustee -notmatch '\\') {
    $ADResolved = (Resolve-SamAccount -SamAccount $Trustee -Exit:$true)
    $Trustee = 'WinNT://',"$env:userdomain",'/',$ADResolved -join ''
} else {
    $ADResolved = ($Trustee -split '\\')[1]
    $DomainResolved = ($Trustee -split '\\')[0]
    $Trustee = 'WinNT://',$DomainResolved,'/',$ADResolved -join ''
}

if (!$InputFile) {
	if (!$Computer) {
		$Computer = Read-Host "Please input computer name"
	}
	[string[]]$Computer = $Computer.Split(',')
	$Computer | ForEach-Object {
		$_
		Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		try {
			([ADSI]"WinNT://$_/Administrators,group").add($Trustee)
			Write-Host -ForegroundColor Green "Successfully completed command for `'$ADResolved`' on `'$_`'"
		} catch {
			Write-Warning "$_"
		}	
	}
}
else {
	if (!(Test-Path -Path $InputFile)) {
		Write-Warning "Input file not found, please enter correct path"
		exit
	}
	Get-Content -Path $InputFile | ForEach-Object {
		Write-Host "Adding `'$ADResolved`' to Administrators group on `'$_`'"
		try {
			([ADSI]"WinNT://$_/Administrators,group").add($Trustee)
			Write-Host -ForegroundColor Green "Successfully completed command"
		} catch {
			Write-Warning "$_"
		}        
	}
}




}


function usergroup {


#Get User local groups before Windows Server 2016

#Load local groups to Variable
$LocalGroups = Get-WmiObject Win32_Group -Filter "LocalAccount=True" | foreach { $_.Name }

#Load user list to variable
$UserList = gc 'C:\suporte windows\lista\usuarios.txt'

# Validate every group to find users and write on screen
foreach ($group in $LocalGroups) {


$validate = net localgroup $group

foreach ($user in $UserList){

$exist = $validate |findstr -i $user 

if ($exist -ne $null) {
Write-host "User $user member of $group"
Clear-Variable $validate -ErrorAction SilentlyContinue
}



 }

 }

} #TALVEZ USAR

Function Listcomp {
foreach ($server in $servers){
#$grupos = Get-LocalGroup -Name @("administrators","administradores") -ErrorAction SilentlyContinue 

Write-host "Servidor $server " 
Write-host "Administradores:" 

foreach ($grupo in $grupos){

#MAPEAMENTO DE SERVIDOR DE OUTROS DOMINIOS PARA CONECTAR PELO GTW
mapserver

Get-LocalGroupMemberComputers -Group $grupo -Computername $server 

unmap
}

Write-host "============================================"  

}

} #FUNCIONANDO




Function RemoveGroup {
foreach ($server in $servers){
write-host "analisando $server... "
mapserver

$grupoatualcomparelist = Get-LocalGroupMemberComputers -Group "Administrators" -Computername $server|? {$_.name -or $_.account} -ErrorAction SilentlyContinue

foreach ($adm in $grupoatualcomparelist.account){


$valida = "$grupobaseline" -match "$adm"


if ($valida -ieq "true"){
    write-host -ForegroundColor green "O grupo $adm do servidor $server esta correto." 
    }
else
    {
     Write-Host -ForegroundColor Red "O grupo $adm do servidor $server esta errado e sera removido"
    #COMANDO DE REMOCAO
    $grouprm = [ADSI]"WinNT://$server/Administrators,group"
    $grouprm.Children(

    #$grouprm.add("winnt://$server/originalti\$adm,user")
    #$grouprm.Remove("WinNT://$server/originalti\$adm,user")
    #$grouprm | select -Property *
    }


    
   
   
unmap

 }

  }

}  #CRIANDO

Function CompareGroup {
#para cada servidor (Feito na funcao ou no switch, fara:)
#receber as informações do GET-LocalGroupMembers X Comparar com Baseline

foreach ($server in $servers){
write-host "analisando $server... "
mapserver

$grupoatualcomparelist = Get-LocalGroupMemberComputers -Group "Administrators" -Computername $server|? {$_.name -or $_.account} -ErrorAction SilentlyContinue
# $grupoatualcompare.account
<#TESTE
{
Get-LocalGroupMemberComputers -Group "Administrators" -Computername "docker01" |% {$_.name -or $_.account}
Write-host $grupoatualcompare
}
#FIM TESTE
#>
#PAREI AQUI... COMPARE INVERTIDO


#PARA CADA ADMIN QUE EXISTE, VOU PESQUISAR O BASELINE
#foreach ($adm in $grupoatualcompare.account){write-host "teste $adm"}
foreach ($adm in $grupoatualcomparelist.account){

<#
#foreach ($adm in "batata"){
#$compare = $grupoatualcompare |findstr $adm
#$basedefault
#$valida = Get-LocalGroupMemberComputers -Group "Administrators" -ValidMember @("$adm") -Computername $server -ErrorAction SilentlyContinue |? {$_.account -ilike @("$basedefault")}
#VERIFICAR MEMBRO NO BASELINE 
#$adm = "domain admin"
#>

#$adm = "domain admins"

$valida = "$grupobaseline" -match "$adm"


<#
write-host "teste valida"

write-host "baseline $grupobaseline"
write-host "usuario $adm"

$grupobaseline |findstr "$adm"

write-host "fim do teste valida"
#>

#Get-LocalGroupMemberComputers -Group "Administrators" -ValidMember @("$adm") -Computername $server

#write-host "$server"
#write-host "DEBUG - Procurando $adm dentro do baseline" 


#Get-LocalGroupMemberComputers -Group Administrators -Computername $server


if ($valida -ieq "true"){
    write-host -ForegroundColor green "O grupo $adm esta correto." 
    }
else
    {
     Write-Host -ForegroundColor Red "O grupo $adm esta errado"
    }
   
   
  # clear-variable valida 
#> 
  } #COMPARE ADM EM GRUPOS
unmap

 }
} #FUNCIONANDO

Function SpecialGroup {



} #CRIANDO

Function baselinegroup {


} #CRIANDO


#CARREGA BASELINE VAR
$baseapp = gc 'C:\Suporte Windows\Lista\baseline\aplicacao.txt'
$basedba = gc 'C:\Suporte Windows\Lista\baseline\dba.txt'
$baseprod = gc 'C:\Suporte Windows\Lista\baseline\producao.txt'
$basedefault = gc 'C:\Suporte Windows\Lista\baseline\default.txt'
$basepersosrv = gci 'C:\Suporte Windows\Lista\baseline\personalizado\' |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"


#TESTE DO BASELINE PERSONALIZADO
#foreach ($teste in $baseperso){write-host "servidor $teste"}


$serverbase

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
" #VERIFICA DOMINIO
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
        } #FIM VERIFICA DOMINIO


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
    switch ($baseline) {
    A {$grupobaseline = $basedefault ; CompareGroup}
    B {$grupobaseline = $basedba ; CompareGroup}
    C {$grupobaseline = $baseapp ; CompareGroup}
    D {$grupobaseline = $baseperso ; CompareGroup}
    Default {exit}
    }

  }

C {$funcao="altera"
    $grupos = $gruposadm
    $baseline = Read-Host "Qual baseline sera aplicado?
    (A) PADRAO
    (B) BANCO DE DADOS
    (C) APLICACOES
    (D) PERSONALIZADO
    "
    switch ($baseline) {
    A {$grupobaseline = $basedefault ; ChangeGroup}
    B {$grupobaseline = $basedba ; ChangeGroup}
    C {$grupobaseline = $baseapp ; ChangeGroup}
    D {$grupobaseline = $baseperso ; ChangeGroup}
    Default {exit}
    
    }


    
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
