Import-Module ActiveDirectory

Get-ADUser -Filter * | Ft Name, UserPrincipalName, Enabled

