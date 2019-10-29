# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)
#VERIFICA BOOT 
$boot = systeminfo |findstr /c:"Boot Time" 
$hoje = get-date -Format dd/MM/yyyy
$valida = $boot |findstr $hoje
#Status 0 = BOOT OK / Status 1 = Não bootado
if ($valida -ine $null) {$status = "0"} else {$status = "1"}
$status 
