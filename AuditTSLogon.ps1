# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)
# Get logon and reconnect events and print: "time | username" .

$log = get-winevent -LogName 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational' |? {$_.id -eq "21" -or $_.id -eq "25"} | ? {$_.TimeCreated -gt "11/09/2019"} 
foreach ($l in $log) {
$log02 = $l.message |findstr User
write-host $l.timecreated "|" $log02
#$log.message
}
