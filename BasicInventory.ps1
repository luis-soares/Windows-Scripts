# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)
# Exit to file. In powershell/cmd exec: powershell -file BasicInventory.ps1 .\log.log > LogInvent.log

$computers = Get-ADComputer -SearchBase "Ou=Servers,DC=LUREN,DC=LAB" -filter * |select Name,DistinguishedName


function SERIALNUMBER {
if ($machine -imatch "Virtual"){
    $global:serialn = "Sem Serial Number (VirtualMachine)"
    }
        else
    {
        $global:serialn = Get-WmiObject -ComputerName $computer win32_bios |select SerialNumber
    }
} #VER SERIAL NUMBER

function MANUFACTURER {
$global:hwinfo = Get-WmiObject -ComputerName $computer win32_computersystem |select model
if ($global:hwinfo -imatch "Virtual"){
    $global:machine = "Virtual Machine"
}
 else
{
 $global:machine = $global:hwinfo.model
 }
} #VER VIRTUAL/FISICA

function IPINFO {
    if ($global:osinfo -imatch "2003" -or $global:osinfo -imatch "2008") {
    $global:ips =  Get-WmiObject -ComputerName $computer Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -notmatch "127.0.0.1" -and $_.IPAddress -ine $null -and $_.IPAddress -notmatch "::1" -and $_.IPAddress -notmatch "169.254"} | select IPaddress -ErrorAction SilentlyContinue
    $global:gw2003 =  Get-WmiObject -ComputerName $computer Win32_NetworkAdapterConfiguration |Where-Object {$_.DefaultIPGateway -ine $null} |select DefaultIPGateway -ErrorAction SilentlyContinue
    $global:gw = $global:gw2003.DefaultIPGateway
    }
    else
    {
    $global:ipsremoto = Invoke-Command -ComputerName $computer -scriptblock { Get-NetIPAddress |select IPAddress,PrefixLength | Where-Object {$_.IPAddress -notmatch "127.0.0.1" -and $_.IPAddress -notmatch "::1" -and $_.IPAddress -notmatch "169.254"} } -ErrorAction SilentlyContinue
    $global:gwremoto = Invoke-Command -ComputerName $computer -scriptblock {Get-NetRoute | ? {$_.DestinationPrefix -imatch "0.0.0.0"} | select Nexthop } -ErrorAction SilentlyContinue
    $global:ips = $global:ipsremoto |select  IPAddress,PrefixLength
    $global:gw = $global:gwremoto.Nexthop
    }        
    write-host "Endereço IP:" $global:ips.ipaddress
    write-host "Default Gateway:" $global:gw
    Write-host "************"
} #IP AND GW INFOs

function CPUINFO {
 #Media de Utilizacao CPUs
 $global:cpu = Get-WmiObject -computername $computer win32_processor | Measure-Object -property LoadPercentage -Average | Select Average
 #Nucleo de CPUs
 $global:vcpu = Get-WmiObject -computername $computer win32_processor |select SocketDesignation |Measure-Object | select Count
} #CPU INFOs

function MEMINFO {
 #Memoria Utilizacao
 $global:memoria = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryUsage (%)"; Expression = { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}
 #Memoria Fisica
 $global:memoriatotal = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryTotal(GB)"; Expression = { "{0:N0}" -f (($_.TotalVisibleMemorySize)/1024/1024) }}
} #MEMORY INFOs

function DISKINFO {
$discos = Get-WmiObject -ComputerName $computer -Class Win32_logicalDisk 
foreach ($global:disco in $discos){
    if ($global:disco.drivetype -ieq "3") { 
        $global:disco | % {$_.BlockSize=(($_.FreeSpace)/($_.Size))*100;$_.FreeSpace=($_.FreeSpace/1GB);$_.Size=($_.Size/1GB);$_} | Format-Table Name, @{n='FS';e={$_.FileSystem}},@{n='Free, Gb';e={'{0:N2}'-f$_.FreeSpace}}, @{n='Livre';e={'{0:N2}'-f $_.BlockSize}},@{n='Capacity ,Gb';e={'{0:N3}'-f $_.Size}}
        } #FIM FOREACH DISCOS
    } #FIM IF DISCOS
} #DISK INFOs

function VALSERVICES {
 Write-host "***************"
 Write-host "Servicos em execucao no servidor " $computer
 Write-host "***************"
 
 $global:services = Get-Service -ComputerName $computer |Where-Object {$_.Status -imatch "Run"}
 $global:services
} #SERVICES RUNN

function GETOS {

$global:osinfoall = Get-WmiObject -ComputerName $computer win32_operatingsystem
$global:osinfo = $global:osinfoall.Name.Split('|') -imatch "Microsoft"
#$global:osarch = $global:osinfoall.OSArchitecture
$arq = (Get-WmiObject -ComputerName $computer win32_processor).addresswidth 
    if ($arq -ilike "32"){
    $global:osarch = "32 Bits"} 
    else 
    {$global:osarch = "64 bits"}
} #VER OPERATION SYSTEM

function GETROLES {
 Write-host "***************"
 Write-host "Roles and Features instaladas no servidor " $computer
 Write-host "***************"

 if ($global:osinfo -imatch "2003" -or $global:osinfo -imatch "2008") {
 "Funcao de coleta nao disponivel para Windows server 2003 e Windows server 2008"}
 else
 {
 $global:roles = Get-WindowsFeature -ComputerName $computer |? {$_.installstate -imatch "install"}
 $global:roles |ft Name, InstallState
 }
} #VER ROLES AND FEATURES


foreach ($computer in $computers.name) {     
    #Criar Variavel

    #Hostname
    $hostname = $computer

    #TESTA Comunicacao RPC
    $testrpccom = Get-WmiObject -ComputerName $computer win32_processor -ErrorAction SilentlyContinue
        
    #Se tiver comunicação RPC, executa os testes.
    if ($testrpccom -ine $null){
       
    MANUFACTURER
    SERIALNUMBER
    GETOS

    Write-host "===================================================================================================="
    Write-host "Hostname: " $computer
    Write-host "Sistema Operacional: " $global:osinfo
    Write-Host "Arquitetura: " $global:osarch
    Write-host "Fabricante: " $global:machine
    Write-host "Serial: " $global:serialn.SerialNumber
    #Write-host "==================="



    #Configuracao de IP e Default Gateway 
    IPINFO

    # CPU 
    CPUINFO

    # MEM
    MEMINFO

    #CRIAR IF PARA ITENS MONITORADOS
    
        write-host "Nome:" $hostname ";"
        write-host "Nucleos CPU:" $vcpu ";"
        Write-host "Uso de CPU:" $cpu ";" 
        Write-host "Memoria Total (GB):" $memoriatotal ";"
        Write-host "Uso de Memoria:" $memoria ";"
        Write-host "Uso do disco: " 
    
    #Utilizacao dos Discos
    DISKINFO

    # Serviços em Execucao
    VALSERVICES

    # Roles And Features
    GETROLES     
    
    Clear-Variable serialn,hwinfo
        
    } # FIM "IF" CONEXAO WMI
    
    
    else

    {Write-host -ForegroundColor Red "Sem comunicação RPC com o servidor $computer"}
    Clear-Variable testrpccom

   Write-host "===================================================================================================="

}


    
