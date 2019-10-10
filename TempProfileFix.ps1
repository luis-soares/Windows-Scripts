# Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)
#Luis Antonio Soares da Silva
cd 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$regsbak = gci *.bak |select Name 
foreach ($reg in $regsbak){

  $newname = $reg.name.Replace('.bak','.bak_old')
  Rename-Item $reg.Name.Split('\')[6] -NewName $newname.Split('\')[6]

}
