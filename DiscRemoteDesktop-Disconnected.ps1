# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)

#SERVERS RDP<
 $server01 = "LUREN01"
 $server02 = "LUREN02"
 $server02 = "LUREN03"
#>


#ALL RDP SERVERS VAR
$servers = Get-Variable -name server0*,server1*

function mainsess {
    foreach ($global:computer in $global:optget){
    $global:sessions = query user /server:$global:computer
    $global:sessionsact = $sessions |findstr /c:Active /c:Ativo
    $global:sessiondisc = $sessions |findstr Disc

    switch ($global:optact){
    val {getsess}
    dis {discsess}
    Default {write-host -ForegroundColor Red "Falha, verificar Switch case mainsess"}
    }
  }
 } #Get Sess session ID


 #DISC MENU
 function discsessmenu{

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "          LOGOFF EM SESSOES INATIVAS          "
Write-host -ForegroundColor DarkYellow "=============================================="

do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Desconectar sessoes inativas de todos os servidores;
(2) Desconectar sessoes inativas de servidor especifico (Ex: RDP01); 
(S) Voltar ao menu anterior;
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    1 {$global:optget = $servers.value
        $global:optact = "dis"
        mainsess
      }
    2 {$global:optget = Read-Host "Informe o(s) nome(s) do(s) servidor(es) (ex: RDP01, RDP2 - >1 incluir , ): "
        $global:optact = "dis"
        mainsess
    }
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}
    }

} until ($opt -imatch "s")

} #MENU to Validate: Disconnected Remote Desktop Session


#DISC FUNC
function discsess {

foreach ($sessiondiscid in $global:sessiondisc) {
    $id = $sessiondiscid.Split(" ",[system.stringsplitoptions]::removeemptyentries)[1]
        write-host "Desconectando a Sessao" $id "do servidor" $global:computer "... aguarde 5 min e valide, pode ser necessario matar processos travados de usuarios"
    $sessiondiscid
    reset session /server:$global:computer $id
    }





} #Disconnected Remote Desktop Session


#GET MENU
function getsessmenu{

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "       VERIFICANDO OS STATUS DE CONEXÃO       "
Write-host -ForegroundColor DarkYellow "=============================================="

do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Validar todos os servidores;
(2) Validar servidor especifico (Ex: RDP01); 
(S) Voltar ao menu anterior;
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    1 {$global:optget = $servers.value
        $global:optact = "val"
        mainsess
      }
    2 {$global:optget = Read-Host "Informe o(s) nome(s) do(s) servidor(es) (ex: RDP01, RDP2 - >1 incluir , ): "
        $global:optact = "val"
        mainsess
    }
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}
    }

} until ($opt -imatch "s")

} #MENU to Validate: Get Session Remote Desktop Session


#GET FUNC
function getsess{
    Write-Host "========================================="
    Write-Host "        SERVIDOR: "$global:computer
    Write-Host "========================================="
    $global:sessions
    Write-Host "========================================="
    Write-host -ForegroundColor Green "Total de usuarios conectados no servidor $global:computer : " $global:sessionsact.count
    Write-host -ForegroundColor Red "Total de usuarios desconectados no servidor $global:computer : " $global:sessiondisc.count
    Write-Host "========================================="
} #Get Session Remote Desktop Session (Count)



do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Verifica Status de Usuarios Conectados e Desconectados;
(2) Desconecta usuarios;
(S) Sair
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    

    1 {getsessmenu}
    2 {discsessmenu}
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}

    }


} until ($opt -imatch "s")







Clear-Variable -Name *server*
