# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)

$computers = Get-ADComputer -SearchBase "Ou=Servers,DC=Luren,DC=LAB" -filter * |select Name,DistinguishedName

foreach ($computer in $computers.name) {     
    #Criar Variavel

    #Hostname
    $hostname = $computer
    
    #TESTA Comunicacao RPC
    $testrpccom = Get-WmiObject -ComputerName $computer win32_processor -ErrorAction SilentlyContinue
    
    #Se tiver comunicação RPC, executa os testes.
    if ($testrpccom -ine $null){

    Write-host "Hostname: " $computer
    
    #Configuracao de IP e Default Gateway 
    $ips = Get-NetIPAddress |select IPAddress,PrefixLength | Where-Object {$_.IPAddress -notmatch "127.0.0.1" -and $_.IPAddress -notmatch "::1"}
    $gw = Get-NetRoute | ? {$_.DestinationPrefix -imatch "0.0.0.0"} | select Nexthop
    write-host "Endereço IP:" $ips
    write-host "Default Gateway:" $gw 


        # CPU 
        #Media de Utilizacao CPUs
        $cpu = Get-WmiObject -computername $computer win32_processor | Measure-Object -property LoadPercentage -Average | Select Average
        #Nucleo de CPUs
        $vcpu = Get-WmiObject -computername $computer win32_processor |select SocketDesignation |Measure-Object | select Count

        #Memoria
        $memoria = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryUsage (%)"; Expression = { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}
        $memoriatotal = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryTotal(GB)"; Expression = { "{0:N0}" -f (($_.TotalVisibleMemorySize)/1024/1024) }}

        write-host "Nome:" $hostname ";" "Nucleos CPU:" $vcpu ";"  "Uso de CPU:" $cpu ";" ";" "Memoria Total (GB):" $memoriatotal ";"  "Uso de Memoria:" $memoria ";" "Uso do disco " 
    
    $discos = Get-WmiObject -ComputerName $computer -Class Win32_logicalDisk 
        foreach ($disco in $discos){
           if ($disco.drivetype -ieq "3") { 
            $disco | % {$_.BlockSize=(($_.FreeSpace)/($_.Size))*100;$_.FreeSpace=($_.FreeSpace/1GB);$_.Size=($_.Size/1GB);$_} | Format-Table Name, @{n='FS';e={$_.FileSystem}},@{n='Free, Gb';e={'{0:N2}'-f$_.FreeSpace}}, @{n='Livre';e={'{0:N2}'-f $_.BlockSize}},@{n='Capacity ,Gb';e={'{0:N3}'-f $_.Size}}
            }
        }
        
   
        
    } # FIM SE
    
    
    else

    {Write-host -ForegroundColor Red "Sem comunicação RPC com o servidor $computer"}
    Clear-Variable testrpccom



}
