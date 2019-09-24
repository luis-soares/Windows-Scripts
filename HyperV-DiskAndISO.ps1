#Hosts Hyper-v

#Recebendo informações do Cluster
$hosts = (get-clusternode).Name

#Se quiser especificar servidores (Hospedeiros) para verificar, Comentar a variavel de cima e descomentar a de baixo:
#$hosts = "node01","node02"

$hosts

# Scripts Localizacao dos arquivos VM
Write-Host "###################################################"
Write-host "Localizacao de arquivos da VM"
Write-Host "###################################################"
ForEach($item in $hosts){
Get-VM -ComputerName $item * |sort-object| fl Name,path,configurationlocation,snapshotfilelocation,@{L="Disks";E={$_.harddrives.path}} 
  }

# Script Verificar ISOs nas VMs
Write-Host "###################################################"
Write-host "VMS com ISO Montadas"
Write-Host "###################################################"
ForEach($item in $hosts){
get-VM -ComputerName $item | Get-VMDvdDrive | ? {$_.Path -ine $null}
}



# Script Desmontar ISOs nas VMs
Write-Host "###################################################"
Write-host "Desmontando ISOs"
Write-Host "###################################################"
ForEach ($item in $hosts){
get-VM -ComputerName $item | Get-VMDvdDrive | ? {$_.Path -ine $null} | Set-VMDvdDrive -Path $null
}


