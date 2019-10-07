# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)

#SERVERS RDP
<# $server01 = "rdp01"
$server02 = "rdp2"
#>


#ALL RDP SERVERS VAR
$servers = Get-Variable -name server0*,server1*

function loadsess {
    foreach ($computer in $global:optget){
    $sessions = query user /server:$computer
    $global:sessionsact = $sessions |findstr Active
    $global:sessiondisc = $sessions |findstr Disc
    }
} #Get Sess session ID

function discsess {
foreach ($sessiondiscid in $global:sessiondisc) {
    $sessiondiscid.Split(" ",[system.stringsplitoptions]::removeemptyentries)[1]
    write-host "Desconectando a Sessao :" $sessiondiscid
    }
} #Disconnected Remote Desktop Session

function getsess{

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "       VERIFICANDO OS STATUS DE CONEXÃO       "
Write-host -ForegroundColor DarkYellow "=============================================="

do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Validar todos os servidores;
(2) Digitar o nome do servidor (Ex: RDP01); 
(S) Voltar ao menu anterior;
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    1 {$global:optget = $servers.value
        loadsess
        $act = $global:sessionsact | Measure-Object
        $disc =  $global:sessiondisc |Measure-Object

    }
    2 {$global:optget = Read-Host "Informe o(s) nome(s) do(s) servidor(es) (ex: RDP01, RDP2 - >1 incluir , ): "
        loadsess
        $act = $global:sessionsact | Measure-Object
        $disc =  $global:sessiondisc |Measure-Object
    }
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}
    }

} until ($opt -imatch "s")

}

function getsess {
if ($optget -ieq "getallserv"){
   
    }
else 
    {$computers = Read-Host "Informe o(s) nome(s) do(s) servidor(es) (ex: RDP01, RDP2 - >1 incluir , ): "}


}




foreach ($server in $servers.value) {
   write-host "host " $server
}



do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Verifica Status de Usuarios Conectados e Desconectados;
(2) Desconecta usuarios;
(S) Sair
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    

    1 {versess}
    2 {discsess}
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}

    }


} until ($opt -imatch "s")







Clear-Variable -Name *server*
