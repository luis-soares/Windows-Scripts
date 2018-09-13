#Feito por: Luis Antonio Soares da Silva (luissoares@outlook.com)


# SINAL DE CERTO [char]8730
# SINAL DE ERRO  [char]215

#parametros para ativar o menu -help etc
param ( 
[Parameter()] [ValidateSet('BancoIBI','BradescoCartoes','D9803D01','AmexDC')] [string[]] $loadcred,
[Switch] $loadlist = $false,
[Switch] $help = $false
) 

#Variables there are located Powershell Scripts, Admin Baselines, Admin Groups, Other Groups
$folderPS = "C:\suporte windows\Scripts" #Powershell scripts base
$folderbaseline = "C:\suporte windows\Lista\baseline" #Root folder of Baselines
$AdminGroups = "administrators" #Lista de nomes (Administrators, Administradores)
$OtherGroup = $null
$specialgrpbkp = "power users","remote desktop users","backup operators"
$specialgrpcoti = "power users","remote desktop users"



#Valida se foi solicitado o HELP antes de carregar o MENU
if ($help -ieq $true){
Write-host "ValidateBaseline.ps1
-loadcred (Load credentials to connect on server list | Ex: ValidateBaseline.ps1 -loadcred domain1)
-loadlist (Load list of all servers, used to verify status with baseline definitions | Ex: ValidateBaseline.ps1 -loadlist)
-help (Show this help)

"
exit
}


# HEAD
Write-host -ForegroundColor Yellow " ==============================================================================="
Write-host -ForegroundColor Yellow " ============= BASELINE: LIST | VALIDATE | CHANGE | SPECIAL GROUPS ============="
Write-host -ForegroundColor Yellow " ==============================================================================="


#Verifica se o Parametro de credenciais foi selecionado e solicita as credenciais do dominio
switch ($loadcred) {
    Bancoibi {$credIBI = Get-Credential -Message "Entrar com as credenciais do BANCOIBI"}
    BradescoCartoes {$credbca = Get-Credential -Message "Entrar com as credenciais do BRADESCOCARTOES"}
    D9803D01 {$credd98 = Get-Credential -Message "Entrar com as credenciais do D9803D01"}
    AmexDC {$credamx = Get-Credential -Message "Entrar com as credenciais do AMEXDC"}
    Default {$creddefault = $null}         
}


#Verifica se foi solicitado carregar a lista de baseline dos servidores (Vai carregar a lista inteira, pois nao e demorado)
if ($loadlist -ieq $true){
$serveribi = gci "$folderbaseline\BANCOIBI" -Recurse -Filter "*.txt"
$serverd98 = gci "$folderbaseline\D9803D01" -Recurse -Filter "*.txt"
$serverbca = gci "$folderbaseline\BRADESCOCARTOES" -Recurse -Filter "*.txt"
$serveramx = gci "$folderbaseline\AMEXDC" -Recurse -Filter "*.txt"

$serveribiSname = gci "$folderbaseline\BANCOIBI" -Recurse -Filter "*.txt"  |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"
$serverd98Sname = gci "$folderbaseline\D9803D01" -Recurse -Filter "*.txt" |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"
$serverbcaSname = gci "$folderbaseline\BRADESCOCARTOES" -Recurse -Filter "*.txt" |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"
$serveramxSname = gci "$folderbaseline\AMEXDC" -Recurse -Filter "*.txt" |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"
}


#Verifica se o modulo esta na pasta
$moduloGroupMembers = gci "$folderPS\Modules\GroupMembers" -ErrorAction SilentlyContinue
if ($moduloGroupMembers) {
    Import-Module -Name "$folderPS\Modules\GroupMembers"}
 else
    {write-host "Modulo GroupMembers não existe na pasta $folderPS\modules"
     write-host "Baixar o Modulo GroupMembers e inserir na pasta $folderPS\modules"
    exit
    }




#FUNCTIONS

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

function Set-ADAccountasLocalAdministrator {
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

Function Listcomp {

$list = read-host "Do you want verify in:
- (L)ist of Computers
- (D)omain List (Loaded)
- (S)ingle computer

"

switch ($list){
L {Write-host "insert computer list in file $folderbaseline\personal\list.txt"


}




foreach ($server in $servers){
#$grupos = Get-LocalGroup -Name @("administrators","administradores") -ErrorAction SilentlyContinue 

Write-host "Servidor $server " 
Write-host "Administradores:" 

foreach ($grupo in $grupos){

#MAPEAMENTO DE SERVIDOR DE OUTROS DOMINIOS PARA CONECTAR PELO GTW
mapserver

Get-LocalGroupMemberComputers -Group $group -Computername $server 

unmap
}

Write-host "============================================"  

}

} #FUNCIONANDO

Function AdduserGroup {


#para cada servidor (Feito na funcao ou no switch, fara:)
#receber as informações do GET-LocalGroupMembers X Comparar com Baseline

foreach ($server in $servers){

 if($server -ieq "APP" -or $server -ieq "DBA" -or $server -ieq "DEFAULT") {"server invalido"}
 else
 {

write-host "analisando $server... "
mapserver

$grupoatualcomparelist = Get-LocalGroupMemberComputers -Group "Administrators" -Computername $server|? {$_.name -or $_.account} -ErrorAction SilentlyContinue
# $grupoatualcompare.account

$validapersonalizado = $grupobaseline -match "$server"

#EXIBE O NOME DO ARQUIVO BASE
write-host "Arquivo baseline: $validapersonalizado " 

$validabaseline = gc $validapersonalizado 


foreach ($adm in $validabaseline){


write-host "Sera incluido o usuario $adm no servidor $server"

([ADSI]"WinNT://$server/Administrators,group").add($adm)

<#

if ($valida -ieq "true"){
    write-host -ForegroundColor green "O grupo $adm esta correto." 
    }
else
    {
     Write-Host -ForegroundColor Red "O grupo $adm esta errado"
    }
 #>  #IF DESATIVADO
   
  # clear-variable valida 
#> 
  } #COMPARE ADM EM GRUPOS
unmap

 }

}

}

<#
Function RemoveGroup {
foreach ($server in $servers){
write-host "Removendo Administradores do Servidor $server... "
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
    
   Remove-ADAccountasLocalAdministrator -Computer $server -Trustee $adm
   
unmap

 }

  }

} 
}
 #> #CRIANDO

Function RemoveGroup {



}

Function CompareGroup { #FUNCAO COMPARE PERSONALIZADO REMOVER APOS SCRIPT01
#para cada servidor (Feito na funcao ou no switch, fara:)
#receber as informações do GET-LocalGroupMembers X Comparar com Baseline
if($server -ieq "APP" -or $server -ieq "DBA" -or $server -ieq "DEFAULT") {"server invalido"}
 else
 {


foreach ($server in $servers){

write-host " ============================= $server ======================= "
write-host "analisando $server... "
mapserver

$grupoatualcomparelist = Get-LocalGroupMemberComputers -Group "Administrators" -Computername $server|? {$_.name -or $_.account} -ErrorAction SilentlyContinue
# $grupoatualcompare.account

$validapersonalizado = $grupobaseline -imatch "$server.txt"



$validabaseline = $validapersonalizado 
#EXIBE O NOME DO ARQUIVO BASE
write-host "Arquivo baseline: $validapersonalizado " 
#gc $validapersonalizado

#ADD SERV_BACKUP - CORRIGIR NO BASELINE
#write-host "ADD SERV_BACKUPTSM A ADMINS"
#        C:\users\i315767x900\Desktop\Set-ADAccountasLocalAdministrator.ps1 -Computer $server -Trustee "serv_backuptsm"
#        Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User "serv_backuptsm" -Domain "bancoibi"  


#write-host " ============================= $server ======================= "
#write-host " ============================= ADMINS EXISTENTES ======================= "
# Get-GroupMembers -Name $server -RemoteGroups "Administrators","Backup Operators","Power Users"

#write-host " ============================= $server ======================= "
Write-host "ADMINS ESPERADOS:"

gc $validapersonalizado

$validabaseline = gc $validapersonalizado 



write-host "====================================="



#foreach ($adduser in $validabaseline){.\PsExec.exe \\$server -h net localgroup administrators /add "$adduser" }


#ESSE ADICIONA
#foreach ($adduser in $validabaseline){C:\users\i315767x900\Desktop\Set-ADAccountasLocalAdministrator.ps1 -Computer $server -Trustee "$adduser" -domain "." }
#foreach ($adduser in $validabaseline){Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User $adduser -Domain "bancoibi"  }
#foreach ($adduser in $validabaseline){Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User $adduser  -domain "$server" }

#ADD USUARIOS BACKUP
#Add-groupmember -ComputerName $server -RemoteGroup "Backup Operators" -User "GG_TI_BACKUP" -Domain "bancoibi"  
#Add-groupmember -ComputerName $server -RemoteGroup "Power Users" -User "GG_TI_BACKUP" -Domain "bancoibi"  
#Add-groupmember -ComputerName $server -RemoteGroup "Remote Desktop Users" -User "GG_TI_BACKUP" -Domain "bancoibi"  
#COTI
#Add-groupmember -ComputerName $server -RemoteGroup "Remote Desktop Users" -User "GG_TI_COTI" -Domain "bancoibi"
#Add-groupmember -ComputerName $server -RemoteGroup "Power Users" -User "GG_TI_COTI" -Domain "bancoibi"

#Get-GroupMembers -Name $server -RemoteGroups "Administrators","Backup Operators","Power Users"

#PARA CADA ADMIN QUE EXISTE, VOU PESQUISAR O BASELINE
#foreach ($adm in $grupoatualcompare.account){write-host "teste $adm"}
foreach ($adm in $grupoatualcomparelist.account){

$valida = "$validabaseline" -imatch "$adm"



#Invoke-Command -scriptblock {(net localgroup administrators /add $adm)} -ComputerName $server 


if ($valida -ieq "true"){
    write-host -ForegroundColor green "O grupo $adm esta correto no $server." 
    }
else
    {
     Write-Host -ForegroundColor Red "O grupo $adm esta errado no $server ."

     
     #$remadmin = Read-host "O usuario $adm sera removido do grupo administrators, confirme para continuar (S)"
     
     
     #$remadmin = "s"
     #if ($remadmin -ieq "s") {write-host "Remover usuario $adm";
     #Remove-ADAccountasLocalAdministrator -Computer $server -Trustee $adm
     #Remove-groupmember -ComputerName $server -RemoteGroup "administrators" -User $adm -Domain "bancoibi"


    }

   
  # clear-variable valida 
#> 
  } #COMPARE ADM EM GRUPOS

 
foreach ($adm2 in $validabaseline){


$admval = $adm2 -replace 'bancoibi','' -replace 'd9803d01','' -replace 'bradescocartoes','' -replace '(\\)',''



#SE O USUARIO FIZER PARTE DO BASELINE E NAO TIVER NA MAQUINA, ADICIONAR
$validabase = $grupoatualcomparelist.account -imatch $admval



   
if ($validabase -icontains "$admval"){
    #write-host -ForegroundColor green "O grupo $adm esta correto no $server." 
    $val="usuario ja esta admin"
    }
else
    {
     Write-Host -ForegroundColor Cyan "Usuario $admval esta no baseline, mas nao no $server. Adicionar."




#        C:\users\i315767x900\Desktop\Set-ADAccountasLocalAdministrator.ps1 -Computer $server -Trustee "$admval"
#        Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User $admval -Domain "bancoibi"
#        Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User $admval  -domain "$server"
    
#        C:\users\i315767x900\Desktop\Set-ADAccountasLocalAdministrator.ps1 -Computer $server -Trustee "serv_backuptsm"
#        Add-groupmember -ComputerName $server -RemoteGroup "administrators" -User "serv_backuptsm" -Domain "bancoibi"  
        

    }


}




unmap

 }
 }
 }


Function SpecialGroup {



} #CRIANDO

Function baselinegroup {


} #CRIANDO




<#
#CARREGA BASELINE VARIAVEL
$baseapp = gc 'C:\Suporte Windows\Lista\baseline\aplicacao.txt'
$basedba = gc 'C:\Suporte Windows\Lista\baseline\dba.txt'
$baseprod = gc 'C:\Suporte Windows\Lista\baseline\producao.txt'
$basedefault = gc 'C:\Suporte Windows\Lista\baseline\default.txt'
$basepersosrv = gci 'C:\Suporte Windows\Lista\baseline\personalizado\' |% {$_.name} |% {$_.split(".txt")} |findstr /R "[^0-9]"
#>



#MENU
$activity = Read-Host "What do you want to do:
(A) List Groups
(B) Validate Groups - Based on Baseline
(C) Change/Correct Groups - Based on Baseline
(D) Special Group
(X) Exit
"
Switch ($activity){

A {$activity="List"
  }

 
B {$activity="validate"
  }

C {$activity="change"
  }


D {$activity="special"
  }

X {write-host "Exit!" -ForegroundColor Red
    exit
  }

Default {write-host "Not valid" -ForegroundColor Red}

}










<# CRIA ARQUIVOS SERVIDORES - REMOVER COMENTARIO APOS SCRIPT 01
Write-Host $null >> $serveribi
Write-Host $null >> $serverd98
Write-Host $null >> $serverbca
Write-Host $null >> $serveramx
#> # CRIA ARQUIVOS SERVIDORES (EM BRANCO SE NAO EXISTIR) - REMOVER COMENTARIO APOS SCRIPT 01

<# ORIGINAL - VOLTAR APOS SCRIPT 01
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
#> #VERIFICA DOMINIO ORIGINAL - VOLTAR APOS CONCLUIR SCRIPT 01

<# DEFINE TODAS AS CREDENCIAIS PARA SCRIPT INICIAL (PARTE DE SCRIPT01)
$credIBI = Get-Credential -Message "Entrar com as credenciais do BANCOIBI"
$credd98 = Get-Credential -Message "Entrar com as credenciais do D9803D01"
$credbca = Get-Credential -Message "Entrar com as credenciais do BRADESCOCARTOES"
$credamx = Get-Credential -Message "Entrar com as credenciais do AMEXDC"

#> #FIM DEFINE CRED INICIAIS (PARTE DE SCRIPT01)


<#FUNCOES ORIGINAIS - REMOVER COMENTARIO APOS SCRIPT 01 


$funcao = Read-Host "O que deseja fazer:
(A) Listar Grupos
(B) Validar de acordo com a baseline
(C) Alterar/Corrigir Grupos
(D) Grupos especiais Backup/Coti"
switch ($funcao){

A {$funcao="lista";listcomp
    $grupos = $AdminGroups
 }

 
B {$funcao="valida" 
    $grupos = $AdminGroups
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
    $grupos = $AdminGroups
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
    
    
    $grupos = $group
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

#> #FUNCOES ORIGINAIS - REMOVER COMENTARIO APOS SCRIPT 01 


<#
write-host "HELP - carregados:
- credenciais de todos os dominios; (Nao sera carregado novamente - credIBI,credd98,credbca,credamx)
- lista de servidores recursivos pegando o nome do arquivo; (Sera usado para definir os servidores, baselines e arquivos de origem)
(CARREGA Somente o nome dos servidores na variavel exemplo:serveramxSname e na variavel exemplo:serveramx carrega as informacoes do arquivo)
Usar o caminho C:\suporte windows\Lista\baseline 
- Variavel validadomains, passando a credencial do dominio e a lista de servidores

" #INSTRUCOES SCRIPT01
#>

<#COMECO VALIDADOMAINS - SCRIPT 01 - REMOVER APOS CONCLUSAO #>

function validatodosdom {

#$validadomains = "amex","ibi","bradescocartoes","d9803"
$validadomains = "ibi"
foreach ($domain in $validadomains){
   switch ($domain){
    amex {
    write-host "Verificando $domain"
    $servers = $serveramxSname
    $cred = $credamx
          
                switch ($funcao){

                A {$funcaoteste="lista";listcomp
                    $grupos = $AdminGroups
                 }

 
                B {$funcaoteste="valida" 
                    $grupos = $AdminGroups
                    $baseline = "D"
                    write-host "SCRIPT 01 APENAS PERSONALIZADO"
                    write-host "(D) PERSONALIZADO"
    

    
                    switch ($baseline) {
                    D {$grupobaseline = $serveramx.fullname -ilike "*.txt" ; CompareGroup}
                    Default {exit}
                    }

                  }

                C {$funcaoteste="altera"
                    $grupos = $AdminGroups
                    $baseline = Read-Host "Qual baseline sera aplicado?
                    (A) PADRAO
                    (B) BANCO DE DADOS
                    (C) APLICACOES
                    (D) PERSONALIZADO
                    "
                    switch ($baseline) {

                    D {$grupobaseline = $serveramx.fullname ; ChangeGroup}
                    Default {exit}
    
                    }


    
                   }

                D {$funcaoteste="especial"
    
    
                    $grupos = $group
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

          }
    ibi {
    "Verificando $domain"
    $servers = $serveribiSname
         $cred = $credIBI
        
        switch ($funcao){

                A {$funcaoteste="lista";listcomp
                    $grupos = $AdminGroups
                 }

 
                B {$funcaoteste="valida" 
                    $grupos = $AdminGroups
                    $baseline = "BASED"
                    write-host "SCRIPT 01 APENAS PERSONALIZADO"
                    write-host "(D) PERSONALIZADO"
    



     
                    switch ($baseline) {
                   BASED {$grupobaseline = $serveribi.fullname -ilike "*.txt" ; CompareGroup}
                    Default {exit}
                    }


                    #$serveribi |fl

                  }

                C {$funcaoteste="altera"
                    $grupos = $AdminGroups
                    $baseline = "BASED"
                   
                    switch ($baseline) {
                   BASED {$grupobaseline = $serveribi.fullname -ilike "*.txt" ; ChangeGroup}
           
                    Default {exit}
    
                    }


    
                   }

                D {$funcaoteste="especial"
    
    
                    $grupos = $group
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
        
        
        }
    bradescocartoes {
    "Verificando $domain"
    $servers = $serverbcaSname
         $cred = $credbca
       
       switch ($funcao){

                A {$funcaoteste="lista";listcomp
                    $grupos = $AdminGroups
                 }

 
                B {$funcaoteste="valida" 
                    $grupos = $AdminGroups
                    $baseline = "D"
                    write-host "SCRIPT 01 APENAS PERSONALIZADO"
                    write-host "(D) PERSONALIZADO"
    




    
                    switch ($baseline) {
                    C {$grupobaseline = $serverbca.fullname ; CompareGroup}
                    D {$grupobaseline = $baseperso ; CompareGroup}
                    Default {exit}
                    }

                  }

                C {$funcaoteste="altera"
                    $grupos = $AdminGroups
                    $baseline = Read-Host "Qual baseline sera aplicado?
                    (A) PADRAO
                    (B) BANCO DE DADOS
                    (C) APLICACOES
                    (D) PERSONALIZADO
                    "
                    switch ($baseline) {
                    BASED {$grupobaseline = $serverd98.fullname  -ilike "*.txt" ; CompareGroup}
                    Default {exit}
    
                    }


    
                   }

                D {$funcaoteste="especial"
    
    
                    $grupos = $group
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
       
       
        }
    d9803 {
    "Verificando $domain"
    $servers = $serverd98Sname
    $cred = $credd98
        
        switch ($funcao){

                A {$funcaoteste="lista";listcomp
                    $grupos = $AdminGroups
                 }

 
                B {$funcaoteste="valida" 
                    $grupos = $AdminGroups
                    $baseline = "BASED"
                    write-host "SCRIPT 01 APENAS PERSONALIZADO"
                    write-host "(D) PERSONALIZADO"
    
                    switch ($baseline) {
                    
                    BASED {$grupobaseline = $serverd98.fullname  -ilike "*.txt" ; CompareGroup}
                    Default {exit}
                    }

                  }

                C {$funcaoteste="altera"
                    $grupos = $AdminGroups
                    $baseline = Read-Host "Qual baseline sera aplicado?
                    (A) PADRAO
                    (B) BANCO DE DADOS
                    (C) APLICACOES
                    (D) PERSONALIZADO
                    "
                    switch ($baseline) {

                    BASED {$grupobaseline =  $serverd98.fullname  -ilike "*.txt" ; ChangeGroup}
                    Default {exit}
    
                    }


    
                   }

                D {$funcaoteste="especial"
    
    
                    $grupos = $group
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
        
        
        }
    default {"Invalido"}

   
   
   }

  }
}

<#FIM VALIDADOMAINS - SCRIPT 01 - REMOVER APOS CONCLUSAO #>
