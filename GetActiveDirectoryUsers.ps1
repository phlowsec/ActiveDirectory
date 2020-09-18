Import-Module ActiveDirectory

Get-ADUser -Filter * | Ft Name, UserPrincipalName, Enabled
Get-ADServiceAccount -Filter * | Ft Name, UserPrincipalName, Enabled


