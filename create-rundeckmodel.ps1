# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)


<# CRIAR ARQUIVO MODELO (Salvar o conteúdo comentado abaixo no desktop arquivo com o nome modelo.txt; Inicio do conteúdo em < e termino /> )

<node name="alt-nodemodel" description="Servidor alt-model" tags="RDP Server"
hostname="ip-model"
osArch="amd64"
osFamily="windows"
osName="Windows Server 2016"
node-executor="WinRMPython" />

#>



$modelo = gc "$home\Desktop\modelo.txt" 
$servers= "serv01", "serv02", "serv03"

foreach ($serv in $servers){
$GetIPAddr = Test-Connection $serv -Count 1 |select IPV4Address
$IPaddr = $GetIPAddr.IPV4Address.IPAddressToString
$arqcont = $modelo.Replace('alt-nodemodel',"$serv")
$arqcont = $arqcont.Replace('alt-model',"$serv")
$arqcont = $arqcont.Replace('ip-model',"$IPaddr")
$arqcont
} 



