#Luis Antonio Soares da Silva (luissoares@outlook.com)
#Get User local groups before Windows Server 2016

#Load local groups to Variable
$LocalGroups = Get-WmiObject Win32_Group -Filter "LocalAccount=True" | foreach { $_.Name }

#Load user list to variable
$UserList = gc 'C:\suporte windows\lista\usuarios.txt'

# Validate every group to find users and write on screen
foreach ($group in $LocalGroups) {


$validate = net localgroup $group

foreach ($user in $UserList){

$exist = $validate |findstr -i $user 

if ($exist -ne $null) {
Write-host "User $user member of $group"
Clear-Variable $validate -ErrorAction SilentlyContinue
}



 }

 }
