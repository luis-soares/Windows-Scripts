# Luis Antonio Soares da Silva - lui_eu@msn.com / luissoares@outlook.com

$SrcOU = "OU=Test,DC=Luis,DC=Domain"
$reportfile = "C:\temp\ad-report.csv"



function ExportUsers {
    $users = Get-ADUser -Filter * -SearchBase $SrcOU

    $results = @()

    foreach ($user in $users) {
        $groups = Get-ADUser $user | Get-ADPrincipalGroupMembership |select name
        $userObject = New-Object -TypeName PSObject
        $userObject | Add-Member -MemberType NoteProperty -Name "login" -Value $user.SamAccountName
        $userObject | Add-Member -MemberType NoteProperty -Name "GivenName" -Value $user.GivenName
        $userObject | Add-Member -MemberType NoteProperty -Name "Surname" -Value $user.SurName
        $userObject | Add-Member -MemberType NoteProperty -Name "Grupos" -Value ($groups.Name -join ", ")

        # Adicionar o objeto personalizado ao array de resultados
        $results += $userObject
    }

    # Exportar os resultados para o arquivo CSV
    $results | Export-Csv -Path $reportfile -NoTypeInformation
    Write-host "Export concluido, caminho: $reportfile"
}


function ImportUsers {
 write-host "NAo Criado ainda"
}

function ValidateGroups {
 write-host "NAo Criado ainda"
}


function ValidateUsers {
 write-host "NAo Criado ainda"
}


function Menu {
    # MENU
    Write-host -ForegroundColor DarkYellow "=============================================="
    Write-host -ForegroundColor DarkYellow "    MENU DE IMPORT/EXPORT DE USUARIOS         "
    Write-host -ForegroundColor DarkYellow "=============================================="

    do {
    Write-host -ForegroundColor DarkCyan "Definindo instrucoes:"

    Write-host -ForegroundColor DarkCyan "
    (1) Exportar os usuarios;
    (2) Importar usuarios;
    (3) Validar grupos;
    (4) Validar usuarios;
    (S) Sair
    Digite o numero correspondente a opcao e pressione enter:"
    $opt= Read-host 

    switch ($opt){
    

        1 {ExportUsers}
        2 {ImportUsers}
        3 {ValidateGroups}
        4 {ValidateUsers}
        S {Write-host "SAIR"}
        Default {write-host -ForegroundColor Red "Opcao Invalida"}


        }


    } until ($opt -imatch "s")



}

menu
