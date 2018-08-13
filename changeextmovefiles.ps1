# Luis Antonio Soares da Silva (luissoares@outlook.com)
#lab (this lab is to my brother Lucas) 
# get files TXT from specific folder, change your extension to LOG and move to another folder.
# Has an if command only to take a rollback easily.
$folder = "D:\Teste_Luis"
$arqsida= gci "$folder\*.txt" 
$arqsvolta= gci "$folder\move\*.log" 



$val= Read-Host "ida (0), volta (1)"

if ($val -eq "0"){
#ida
$arqs= $arqsida



$arqs | Rename-Item -NewName { $_.Name -replace '\.txt','.log' }
Move-Item -Path "$folder\*.log" -Destination "$folder\move"


}
else
{
#volta
$arqs= $arqsvolta

$arqs | Rename-Item -NewName { $_.Name -replace '\.log','.txt' }
Move-Item -Path "$folder\move\*.txt" -Destination "$folder"

}
