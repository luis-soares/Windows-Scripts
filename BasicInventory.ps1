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

        # CPU
        $cpu = Get-WmiObject -computername $computer win32_processor | Measure-Object -property LoadPercentage -Average | Select Average

        #Memoria
        $memoria = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryUsage (%)"; Expression = { "{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}
        $memoriatotal = Get-WmiObject -computername $computer win32_operatingsystem | Select-Object @{Name = "MemoryTotal(GB)"; Expression = { "{0:N0}" -f (($_.TotalVisibleMemorySize)/1024/1024) }}

        write-host "Nome:" $hostname ";" "Uso de CPU:" $cpu ";" ";" "Memoria Total (GB):" $memoriatotal ";"  "Uso de Memoria:" $memoria ";" "Uso do disco " 
    
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


    
