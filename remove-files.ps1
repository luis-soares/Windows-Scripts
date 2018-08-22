#remove files accessed before July 20th, 2017
# Luis Antonio Soares da Silva (luissoares@outlook.com)
Get-ChildItem -recurse |Where-Object {$_.LastAccessTime -cle "07/20/2017"} |Remove-Item -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
