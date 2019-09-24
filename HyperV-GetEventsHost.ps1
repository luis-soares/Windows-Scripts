# Luis Antonio Soares da Silva (luissoares@outlook.com / lui_eu@msn.com )

$nodes = Get-ClusterNode

foreach ($node in $nodes){

Get-WinEvent -ComputerName $node -FilterHashTable @{LogName ="Microsoft-Windows-Hyper-V*"; StartTime = (Get-Date).AddDays(-2) } | Where-Object -Property Message -Match 'RDP01'

}
