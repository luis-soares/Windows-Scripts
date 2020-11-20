# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)
# Configure DNS and add to domain. 

# netsh interface ipv4 set dnsservers name="Local Area Connection 3" static 10.10.10.10 primary 

# PS C:\windows\system32> add-computer -domainname luren.domain -Credential $cred


# Final Range
$ips = (31..35)

# Local and domain credential
$cred = Get-Credential -Message "Local user" -UserName "administrator"
$credad = Get-Credential -Message "Domain User and Password" -UserName "luren\lurenadmin"


foreach ($ip in $ips) {


# Definindo IP para conexao
# $serv="10.10.20.$ip"
$serv="10.10.20.$ip"

write-host "Servidor $serv"
# Mapeamento de drivers
#Write-Host "mapeando drivers $serv"
#New-PSDrive -Name "teste" -psprovider FileSystem -Root \\$serv\c$ -Credential $cred

#Configurando DNS Server, apontando pro AD
Write-Host "configure DNS $serv"
C:\Luren-Suporte\PsExec.exe -h -n 4 \\$serv -u administrator -p PasswordValue netsh interface ipv4 set dnsservers name="Local Area Connection 3" static 10.10.10.10 primary


#Add maquina no dominio e restartando
Write-Host "add to domain $serv"
add-computer -computername $serv -domainname luren.domain –credential $credad -LocalCredential $cred -restart –force

write-host "==========================================================================================="


#Remove-PSDrive -Name "teste"
}
