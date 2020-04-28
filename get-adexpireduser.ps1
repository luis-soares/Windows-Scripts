#Luis Antonio Soares da Silva (lui_eu@msn.com / luissoares@outlook.com)

Get-ADUser  -filter * -properties Name, PasswordExpired, PasswordLastSet, "msDS-UserPasswordExpiryTimeComputed" | where {$_.Enabled -eq "True"} | where {$_.passwordexpired -eq $true} |Select-Object -Property samAccountName,@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
