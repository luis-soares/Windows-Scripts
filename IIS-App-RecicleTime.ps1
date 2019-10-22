#Folder IIS
cd "C:\windows\system32\inetsrv\"

#Find all application pool without names sistema and servicos
$apppools = .\appcmd.exe list app |findstr /i /v sistema |findstr /i /v servicos

#Foreach changing recycling 
foreach ($app in $apppools){
$apppoolName = $app.Split('"')[1]
$appPool = Get-Item "IIS:\AppPools\$appPoolName"

Set-ItemProperty -Path "IIS:\AppPools\$appPoolName" -Name recycling.periodicRestart.schedule -Value @{value="02:00"}
Write-Host $appPoolName

#pause
}



