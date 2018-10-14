#SCRIPT DE VALIDACAO DO MEXICO - CRIADO POR LUIS ANTONIO SOARES DA SILVA - SUPORTE WINDOWS BRADESCARD

#servidores de banco de dados
$servdb1 = "serv01"
$servdb2 = "serv02"
$servdb3 = "serv03"
$servdb4 = "serv04"
$servdb5 = "serv05"
#$servdb6 = "db"
#$servdb7 = "db"
#CASO NECESSARIO ADD NOVAS LINHAS no padrao acima
$serversdbs= Get-Variable -Name "servdb[0-9]" #NAO ALTERAR

#servidores de aplicacao tibco
$servtibco1 = "serv01"
#$servtibco2 = "server2"
#$servtibco3 = "server3"
#CASO NECESSARIO ADD NOVAS LINHAS no padrao acima
$serverstibco = Get-Variable -name "servtibco[1-9]" #NAO ALTERAR

#Servidores de aplicacao iProcess
$serviproc1 = "serv01"
#$serviproc2 = "serv2"
#$serviproc3 = "serv3"
#CASO NECESSARIO ADD NOVAS LINHAS no padrao acima
$serversiproc = Get-Variable -name "serviproc[1-9]" #NAO ALTERAR

#Servidores TIBCO ADMIN
$servtibcoadmin1 = "serv01"
#$servtibcoadmin2 = "server02"
#$servtibcoadmin3 = "server03"
$serverstibcoadmin = Get-Variable -Name "servtibcoadmin[1-9]" #NAO ALTERAR

#Servidores TIBCO HAWK
$servtibcohawk1 = "serv01"
$servtibcohawk2 = "serv02"
$servtibcohawk3 = "serv03"
$servtibcohawk4 = "serv04"
#$servtibcohawk5 = "serv"
#$servtibcohawk6 = "serv"
#$servtibcohawk7 = "serv"
$serverstibcohawk = Get-Variable -Name "servtibcohawk[1-9]" #NAO ALTERAR

#Servidores SUR300
$servsur3001 = "serv01"
$servsur3002 = "serv02"
#$servsur3003 = "serv"
#$servsur3004 = "serv"
$serversSUR300 = Get-Variable -Name "servsur300[1-9]" #NAO ALTERAR


$serversgeral = Get-Variable -ValueOnly -name serversdbs,serverstibco,serversiproc,serverstibcoadmin,serverstibcohawk,serversSUR300


<#
foreach ($teste in $serversgeral.value){
write-host "esse e o $teste"


}
#>

function valservdb {


#mod valida db

#PAG14
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "          VALIDANDO SERVICOS DE SQL           "
Write-host -ForegroundColor DarkYellow "=============================================="


ForEach ($server in $serversdbs.value)
{

write-host -Separator " "
write-host "SERVIDOR:" -ForegroundColor Green "$server"
$servdb = get-service -ComputerName $server |Where-Object  {$_.DisplayName -ilike "*SQL*" -and $_.Name -inotlike "*TSM*" -and $_.DisplayName -inotlike "*Helper*" -and $_.DisplayName -inotlike "*Reporting Services*" -and $_.DisplayName -inotlike "*Browser*" } -ErrorAction Continue 
$servdb
#Invoke-Command -ComputerName "MEXTIBCODB" -ScriptBlock {Get-Service}
write-host -Separator " "
write-host -Separator " "



$servoff = $servdb |Where-Object  {$_.DisplayName -ilike "*SQL*" -and $_.Name -inotlike "*TSM*" -and $_.Status -inotlike "*Run*" } -ErrorAction Continue 

if ($servoff -ieq $null) {
$logservoff = "nao existe serv off"
}
else
{

$servoffopt = Read-Host "Existem servicos offline, deseja iniciar:
(1) Sim - Default
(2) Nao
"

if ($servoffopt -ieq "2"){ 
write-host -ForegroundColor DarkRed  "Servicos OFF"
$servdb |Where-Object  {$_.DisplayName -ilike "*SQL*" -and $_.Name -inotlike "*TSM*" -and $_.Status -inotlike "*Run*" } -ErrorAction Continue 
}
else
{
$servoff | Start-Service 
$servdb |Where-Object  {$_.DisplayName -ilike "*SQL*" -and $_.Name -inotlike "*TSM*" -and $_.Status -inotlike "*Run*" } -ErrorAction Continue 
}


}



write-host -Separator " =============== "

#VALIDANDO SERVICOS CRITICOS DO SQL
write-host -Separator " =============== "
write-host -ForegroundColor DarkYellow "VALIDANDO SERVICOS CRITICOS DO SQL:"
$servcritico = $servdb |Where-Object  {$_.DisplayName -ilike "*SQL Full-text Filter Daemon Laun*" -or $_.DisplayName -ilike "*SQL Server (MSSQLSERVER)*" -or $_.DisplayName -ilike "*SQL Server Analysis Services (MS*" -or $_.DisplayName -ilike "*SQL Server Agent (MSSQLSERVER)*" -or $_.Name -ilike "*MsDtsServer100*"  -or $_.DisplayName -ilike "*SQL Server VSS Writer*" -and $_.Status -inotlike "*Run*" } -ErrorAction Continue 


if ($servcritico -eq $null)
           {
           
           write-host -f Green "Nao ha servicos criticos offline" 
           
           write-host -Separator " =============== "
           }
         
         else
         
         { 
         write-host -f Red "Os servicos abaixo estao offline, por favor iniciar"
         $servdb |Where-Object  {$_.DisplayName -ilike "*SQL Full-text Filter Daemon Laun*" -or $_.DisplayName -ilike "*SQL Server (MSSQLSERVER)*" -or $_.DisplayName -ilike "*SQL Server Analysis Services (MS*" -or $_.DisplayName -ilike "*SQL Server Agent (MSSQLSERVER)*" -or $_.Name -ilike "*MsDtsServer100*" -or $_.DisplayName -ilike "*SQL Server VSS Writer*" -and $_.Status -inotlike "*Run*" } -ErrorAction Continue 
         write-host -Separator " =============== "

         }






write-host "Pressione ENTER para iniciar a validacao do proximo servidor"



pause


#get-service -ComputerName $server
}




} #MODULO DE VALIDACAO DOS SERVIDORES E SERVICOS DE BANCO DE DADOS

function valtibco {

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "       VALIDANDO SERVIDORES DE APP TIBCO      "
Write-host -ForegroundColor DarkYellow "=============================================="

#PAG15

foreach ($server in $serverstibco.Value){

write-host "valida servidor $server"

Write-Host  "Validando servicos no servidor" $server

$servtibco = get-service -ComputerName $server |Where-Object  {$_.DisplayName -ilike "*tib-*" -or $_.DisplayName -ilike "*tibe*"} -ErrorAction Continue 
$servtibco

$servtibcooff = $servtibco | Where-Object {$_.Status -ilike "*Stop*"}

if ($servtibcooff)
{
    write-host -ForegroundColor Red "Existem servicos Offline"
    
    $servoff = $servtibco |Where-Object  {$_.Status -inotlike "*Run*" } -ErrorAction Continue 
    

    if ($servoff -ieq $null) {
    $logservoff = "nao existe servicos off"
    }
    else
    {

    $servoffopt = Read-Host "Existem servicos offline, deseja iniciar:
    (1) Sim - Default
    (2) Nao
    "

    if ($servoffopt -ieq "2"){ 
        write-host -ForegroundColor DarkRed  "Servicos OFF"
        $servtibco |Where-Object  {$_.Status -inotlike "*Run*" } -ErrorAction Continue 
    }
    else
    {
        $servoff | Start-Service 
        $servtibco |Where-Object  {$_.Status -inotlike "*Run*" } -ErrorAction Continue 
        $servtibco 

    }


    }


    write-host -Separator " =============== "


}

write-host "Pressione ENTER para iniciar a validacao do proximo servidor"

pause

}
           

}  #MODULO DE VALIDACAO DOS SERVIDORES DE APP DO TIBCO

function startiproc {

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "       INICIANDO SERVICOS DO IPROCESS         "
Write-host -ForegroundColor DarkYellow "=============================================="

foreach ($server in $serversiproc.Value){

$ServicoIproc = get-service -ComputerName $server -Name iproc*ProcessSentinels 

if ($ServicoIproc.Status -ieq "Running"){
write-host -ForegroundColor Green "Servicos IProcess Iniciados corretamente, verificar log."
}
else
{
get-service -ComputerName $server -Name iproc*ProcessSentinels |Start-Service
}


write-host "Pressione ENTER para iniciar a validacao do proximo servidor"

pause

}

}  #MODULO DE START DO IPROCESS

function validaiproc {
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "       VALIDANDO SERVIDORES DO IPROCESS       "
Write-host -ForegroundColor DarkYellow "=============================================="

write-host "Por favor inserir as credenciais para conexao com os servidores do IProcess (user:bradesco\swpro)" 
$crediproc = Get-Credential "bradesco\swpro"

foreach ($server in $serversiproc.Value){

write-host "Aguarde enquanto as verificacoes sao feitas, caso existam servicos (que ainda) nao estejam com status RUNNING, teste novamente em 120 segundos."

$statusiproc = Invoke-Command -ComputerName $server -Credential $crediproc -ScriptBlock {d:\TIBCO\iprocess\swserver\AteneaBPMProd\util\swsvrmgr.exe status -v}
$statusiproc
    }

}  #MODULO VALIDACAO DO IPROCESS

function startiprocTomcat {

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "        INICIANDO TOMCAT DO IPROCESS          "
Write-host -ForegroundColor DarkYellow "=============================================="

foreach ($server in $serversiproc.Value){

$ServicoIprocTomcat = get-service -ComputerName $server -Name *Tomcat7* 

if ($ServicoIprocTomcat.Status -ieq "Running"){
write-host -ForegroundColor Green "Servicos Tomcat ja estavam iniciados, por garantia sera reiniciado..."
get-service -ComputerName $server -Name *Tomcat7* |Restart-Service
write-host -ForegroundColor Green "Servico reiniciado"
get-service -ComputerName $server -Name *Tomcat7*

}
else
{
get-service -ComputerName $server -Name *Tomcat7* |Start-Service
}


write-host "Pressione ENTER para iniciar a validacao do proximo servidor"

pause

}


} #MODULO DE START DO IPROCESS

function valsecad {

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "      VALIDANDO SECURE CHANNEL COM O AD       "
Write-host -ForegroundColor DarkYellow "=============================================="

#foreach ($server in $serversgeral.value){

foreach ($serverad in $serversgeral.value){

Invoke-Command -ComputerName $serverad -ScriptBlock {$TestSecAD = Test-ComputerSecureChannel -Verbose
if ($testSecAD -ieq "true") {
    $TestSecAD
    }
    else
    {
    $credAD = Get-Credential -Message "Inserir credencial para revalidacao com o dominio"
    $repair1 = Reset-ComputerMachinePassword -Server "SRVAD01" -Credential $credAD -ErrorAction SilentlyContinue
    $repair2 = Test-ComputerSecureChannel -Repair -Credential $credAD  -ErrorAction SilentlyContinue
    Test-ComputerSecureChannel -Verbose
    }

} -ErrorAction SilentlyContinue

}
} #MODULO DE VALIDACAO DO SECURE CHANNEL DOS SERVIDORES COM O ACTIVE DIRECTORY

function automaticStart {
$auto = "true"


} #CRIAR AJUSTES PARA INICIO AUTOMATICO, SEM INTERVENCAO, NEM PAUSAS...

function iniciatibcoadm {

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "             INICIA O TIBCO ADMIN             "
Write-host -ForegroundColor DarkYellow "=============================================="


foreach ($servtibcoadmin in $serverstibcoadmin.value){

Write-Host "Iniciando os servicos do servidor $servtibcoadmin"
write-host "Aguarde enquanto os servicos sao iniciados (Procedimento pode demorar ate 30 Minutos)"

Get-Service -ComputerName $servtibcoadmin -Name "*TIBHawkAgent-IBI_ATENEA_PROD_59*" | Start-Service
Get-Service -ComputerName $servtibcoadmin -Name "*TIBCOAdmin-IBI_ATENEA_PROD_59*" | Start-Service


sleep 10

$statserv = Get-Service -ComputerName $servtibcoadmin -Name "*TIB*59*" | Where-Object {$_.Status -inotlike "*runn*"} |fl

if ($statserv -ine $null)
    {
    write-host "Os servicos estao online"
    Get-Service -ComputerName $servtibcoadmin -Name "*TIB*59*"
    }
else
    {
    write-host "Validar os servicos"
    Get-Service -ComputerName $servtibcoadmin -Name "*TIB*59*" | Where-Object {$_.Status -inotlike "*starte*"} 
    }

}

} #MODULO INICIA TIBCO ADMIN

function iniciatibcohawk {

#PAG20
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "      INICIA SERVICOS DO BUSINESS WORK        "
Write-host -ForegroundColor DarkYellow "=============================================="

#Write-Host "Iniciando os Servicos do Business Work"

ForEach ($servtibcohawk in $serverstibcohawk.value) {
write-host -Separator " ====================== "
Write-Host $servtibcohawk


write-host "iniciando o servico"
get-service -ComputerName $servtibcohawk -displayname "*tibc*59*" | Start-Service
sleep 5
write-host -Separator " ====================== "

get-service -ComputerName $servtibcohawk -displayname "*tibc*59*"
write-host -Separator " ====================== "


}




} #MODULO INICIA TIBCO HAWK

function iniciatibcohawktomcat {

#PAG20
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "          INICIA TOMCAT TIBCO HAWK            "
Write-host -ForegroundColor DarkYellow "=============================================="


$servtibcohawk3
Write-Host "Reiniciando os Servicos do TOMCAT do Servidor $servtibcohawk3"
Write-host "Stop em Andamento..."

Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7* |Stop-Service
sleep 5
Write-host "Start em Andamento..."
sleep 5
Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7* |Start-Service
$statserv = Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7* |Where-Object {$_.Status -ilike "*runn*"}
if ($statserv -ine $null)
    {
    write-host "Os servicos estao online"
    Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7* 
    }
else
    {
    write-host "Validar os servicos"
    Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7* |Where-Object {$_.Status -inotlike "*run*"}
    }



} #MODULO INICIA TIBCO HAWK TOMCAT

function iniciaSUR300 {

Write-Host "Validando os Servicos SUR300"


ForEach ($serverSUR300 in $serversSUR300.value){


write-host -Separator " ====================== "
Write-Host $serverSUR300

write-host "reiniciando o servico"
write-host "Stop em andamento..."
get-service -ComputerName $serverSUR300 -displayname "*jboss*" | Stop-Service

write-host -Separator " ====================== "

write-host "iniciando o servico"
get-service -ComputerName $serverSUR300 -displayname "*jboss*" | Start-Service
sleep 5
write-host -Separator " ====================== "

get-service -ComputerName $serverSUR300 -displayname "*jboss*"
write-host -Separator " ====================== "
$valildaSUR300 = Invoke-WebRequest http://"$serverSUR300":7002 |select StatusCode


if ($valildaSUR300 -ilike "*200*") {
Write-host -ForegroundColor Green "JBOSS do Servidor $serverSUR300 OK!"
}
else
{
Invoke-WebRequest http://$serverSUR300:7002 |select StatusCode,StatusDescription,Content |fl
write-host -ForegroundColor Red "Servidor $serverSUR300 apresentou erro, favor verificar"
}




    }

Write-Host -f Green "SERVICOS INICIADOS, FAVOR FAZER A VALIDACAO UTILIZANDO AS URLs: http://mp-vw-ap-018:7002 e http://mp-vw-ap-020:7002 "

}

function coletaevidencia {

#CREDENCIAL PARA VALIDAR IPROCESS
$crediproc = Get-Credential -Message "Insira as credenciais para validar o Iprocess (Bradesco\swpro)" -User "bradesco\swpro"

########################## INICIO EVIDENCIA SQLS ####################################

#PAG14
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "           COLETANDO EVIDENCIAS SQL           "
Write-host -ForegroundColor DarkYellow "=============================================="


ForEach ($server in $serversdbs.value){

write-host -Separator " "
write-host "SERVIDOR:" -ForegroundColor Green "$server"
$servdb = get-service -ComputerName $server |Where-Object  {$_.DisplayName -ilike "*SQL*" -and $_.Name -inotlike "*TSM*" -and $_.DisplayName -inotlike "*Helper*" -and $_.DisplayName -inotlike "*Reporting Services*" -and $_.DisplayName -inotlike "*Browser*" } -ErrorAction Continue 
$servdb
}



########################## FIM EVIDENCIA SQLS ####################################

########################## INICIO EVIDENCIA TIBCO CLUSTER EMS ####################################

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "     COLETANDO EVIDENCIAS CLUSTER EMS         "
Write-host -ForegroundColor DarkYellow "=============================================="


foreach ($server in $serverstibco.Value){

write-host "SERVIDOR:" -ForegroundColor Green "$server"

Write-Host  "Validando servicos no servidor" $server

$servtibco = get-service -ComputerName $server |Where-Object  {$_.DisplayName -ilike "*tib-*" -or $_.DisplayName -ilike "*tibe*"} -ErrorAction Continue 
$servtibco

}

########################## FIM EVIDENCIA TIBCO CLUSTER EMS ####################################

########################## INICIO EVIDENCIA IPROCESS ####################################

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "     COLETANDO EVIDENCIAS DO IPROCESS         "
Write-host -ForegroundColor DarkYellow "=============================================="


foreach ($server in $serversiproc.Value){


write-host "SERVIDOR:" -ForegroundColor Green "$server"

Write-Host  "Validando servicos no servidor" $server

$serviprocstat = get-service -ComputerName $server -Name iproc*ProcessSentinels
$serviproctomcatstat = get-service -ComputerName $server -Name *Tomcat7* 
$serviprocstat 
$serviproctomcatstat

write-host "========================="


write-host "Validando Status Servico"

$statusiproc = Invoke-Command -ComputerName $server -Credential $crediproc -ScriptBlock {d:\TIBCO\iprocess\swserver\AteneaBPMProd\util\swsvrmgr.exe status -v}
$statusiproc

########################## FIM EVIDENCIA IPROCESS ####################################

########################## INICIO EVIDENCIA TIBCO ADMIN ##############################

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "     COLETANDO EVIDENCIAS DO TIBCO ADMIN      "
Write-host -ForegroundColor DarkYellow "=============================================="



foreach ($servtibcoadmin in $serverstibcoadmin.value){
write-host "SERVIDOR:" -ForegroundColor Green "$servtibcoadmin"

Write-Host  "Validando servicos no servidor" $servtibcoadmin

Get-Service -ComputerName $servtibcoadmin -Name "*TIBHawkAgent-IBI_ATENEA_PROD_59*" 
Get-Service -ComputerName $servtibcoadmin -Name "*TIBCOAdmin-IBI_ATENEA_PROD_59*" 
}


########################## FIM EVIDENCIA TIBCO ADMIN ##############################

########################## INICIO EVIDENCIA TIBCO HAWK ##############################

Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "     COLETANDO EVIDENCIAS DO TIBCO HAWK       "
Write-host -ForegroundColor DarkYellow "=============================================="


ForEach ($servtibcohawk in $serverstibcohawk.value) {

write-host "SERVIDOR:" -ForegroundColor Green "$servtibcohawk"

Write-Host  "Validando servicos no servidor" $servtibcohawk


get-service -ComputerName $servtibcohawk -displayname "*tibc*59*"

}


write-host "SERVIDOR:" -ForegroundColor Green "$servtibcohawk3"

Write-Host  "Validando o TOMCAT no servidor" $servtibcohawk3

Get-Service -ComputerName $servtibcohawk3 -Name *Tomcat7*


########################## FIM EVIDENCIA TIBCO ADMIN ##############################

########################## INICIO EVIDENCIA SUR300 ##############################


Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "     COLETANDO EVIDENCIAS DO SUR300           "
Write-host -ForegroundColor DarkYellow "=============================================="


ForEach ($serverSUR300 in $serversSUR300.value){

write-host "SERVIDOR:" -ForegroundColor Green "$serverSUR300"

Write-Host  "Validando servicos no servidor" $serverSUR300

Write-Host $serverSUR300

get-service -ComputerName $serverSUR300 -displayname "*jboss*"

Write-host "ACESSO A PAGINA NO SERVIDOR $serverSUR300 :"
Invoke-WebRequest http://"$serverSUR300":7002 -UseBasicParsing | select StatusCode,StatusDescription |fl


}


}

}

#verifica as politicas de execucao de script
$polexec = Get-ExecutionPolicy 
if ($polexec -ieq "Unrestricted") {
$polexecval = "correct"
}
else
{
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
}



# MENU
Write-host -ForegroundColor DarkYellow "=============================================="
Write-host -ForegroundColor DarkYellow "    MENU DE VALIDACAO DO DRP BRASIL MEXICO    "
Write-host -ForegroundColor DarkYellow "=============================================="

do {
Write-host -ForegroundColor DarkCyan "O que deseja fazer?"

Write-host -ForegroundColor DarkCyan "
(1) Validar o start dos servidores e comunicacao segura com o AD;
(2) Validar os servidores de banco de dados;
(3) Validar os servidores do TIBCO;
(4) Inicia os servicos do IProcess;
(5) Valida os servicos do IProcess;
(6) Inicia TOMCAT servidor(es) do IProcess;
(7) Inicia TIBCO ADMIN;
(8) Inicia TIBCO HAWK;
(9) Inicia TOMCAT TIBCO HAWK;
(10) Inicia SUR300;
(11) Coletar Evidencia;
(S) Sair
Digite o numero correspondente a opcao e pressione enter:"
$opt= Read-host 

switch ($opt){
    

    1 {valsecad}
    2 {valservdb}
    3 {valtibco}
    4 {startiproc}
    5 {validaiproc}
    6 {startiprocTomcat}
    7 {iniciatibcoadm}
    8 {iniciatibcohawk}
    9 {iniciatibcohawktomcat}
    10 {iniciaSUR300}
    11 {coletaevidencia}
    #A {AutomaticStart}
    S {Write-host "SAIR"}
    Default {write-host -ForegroundColor Red "Opcao Invalida"}


    }


} until ($opt -imatch "s")

<#

REM PAG21
powershell.exe -file "C:\Suporte Windows\Scripts\powershell\FIM.ps1"



#>
