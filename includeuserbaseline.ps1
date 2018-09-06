# Luis Antonio Soares da Silva (lui_eu@msn.com)
# Create 

$file = gci -recurse "C:\suporte windows\Lista\baseline\domain01"
$user = '
user_baseline'



foreach ($fname in $file.fullname){
write-host "Changing file $fname"

$usrtsm = gc $fname |findstr "user_baseline"

if ($usrtsm -ilike "user_baseline"){
write-host "User exists on file"
gc $fname
}
else
{


write-host "User not exists on file, adding..."
$user |Out-File $fname -Append -Encoding utf8
gc $fname


}
write-host "====================================="

}

        
