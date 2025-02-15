<#
  This script will create a report of users that are members of the following
  privileged groups:
  - Enterprise Admins
  - Schema Admins
  - Domain Admins
  - Cert Publishers
  - Administrators
  - Account Operators
  - Server Operators
  - Backup Operators
  - Print Operators

  A summary report is output to the console, whilst a full report is exported
  to a CSV file.

  The original script was written by Doug Symalla from Microsoft:
  - http://blogs.technet.com/b/askpfeplat/archive/2013/04/08/audit-membership-in-privileged-active-directory-groups-a-second-look.aspx
  - http://gallery.technet.microsoft.com/scriptcenter/List-Membership-In-bff89703

  The script was okay, but needed some updates to be more accurate and
  bug free. As Doug had not updated it since 26th April 2013, I though
  that I would. The changes I made are:

  1. Addressed a bug with the member count in the main section.
     Changed...
       $numberofUnique = $uniqueMembers.count
     To...
       $numberofUnique = ($uniqueMembers | measure-object).count
  2. Addressed a bug with the $colOfMembersExpanded variable in the
     getMemberExpanded function 
     Added...
       $colOfMembersExpanded=@()
  3. Enhanced the main section
  4. Enhanced the getForestPrivGroups function
  5. Enhanced the getUserAccountAttribs function
  6. Added script variables
  7. Added the accountExpires and info attributes
  8. Enhanced description of object members (AKA csv headers) so that
     it's easier to read.
  9. GRJ: Added 'whenCreated' property, and fixed bug in script

  Script Name: Get-PrivilegedUsersReport.ps1
  Release 1.3
  Originally Modified by Jeremy@jhouseconsulting.com 13/06/2014
  Subsequently modified by Geoff.Jones@cyberis.co.uk 17/02/2014
  Subsequently modified by info@phlowsec.com 2022-06-22
    Added DNS Admins, Cryptographic Operators and Protected Users in the report

#>
#-------------------------------------------------------------
# Set this to maximum number of unique members threshold
$MaxUniqueMembers = 99

# Set this to maximum password age threshold
$MaxPasswordAge = 365

# Set this to true to privide a detailed output to the console
$DetailedConsoleOutput = $True
#-------------------------------------------------------------
# Get the script path
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$ReferenceFile = $(&$ScriptPath) + "\PrivilegedUsers.csv"

##################   Function to Expand Group Membership ################
function getMemberExpanded
{
        param ($dn)

        $colOfMembersExpanded=@()
        $adobject = [adsi]"LDAP://$dn"
        $colMembers = $adobject.properties.item("member")
        Foreach ($objMember in $colMembers)
        {
                $objMembermod = $objMember.replace("/","\/")
                $objAD = [adsi]"LDAP://$objmembermod"
                $attObjClass = $objAD.properties.item("objectClass")
                if ($attObjClass -eq "group")
                {
                       getmemberexpanded $objMember           
                }   
                else
                {
                     $colOfMembersExpanded += $objMember
              }
        }    
$colOfMembersExpanded 
}    

########################### Function to Calculate Password Age ##############
Function getUserAccountAttribs
{
                param($objADUser,$parentGroup)
              $objADUser = $objADUser.replace("/","\/")
                $adsientry=new-object directoryservices.directoryentry("LDAP://$objADUser")
                $adsisearcher=new-object directoryservices.directorysearcher($adsientry)
                $adsisearcher.pagesize=1000
                $adsisearcher.searchscope="base"
                $colUsers=$adsisearcher.findall()
                foreach($objuser in $colUsers)
                {
                     $dn = $objuser.properties.item("distinguishedname")
                       $sam = $objuser.properties.item("samaccountname")
                      $attObjClass = $objuser.properties.item("objectClass")
                     If ($attObjClass -eq "user")
                     {

                           #GRJ: Added 'whenCreated column"
                           $createdDate = $objuser.properties.item("whenCreated") 
                           ##

                           $displayName = $objuser.properties.item("DisplayName")[0]

                           $description = $objuser.properties.item("description")[0]
                           $notes = $objuser.properties.item("info")[0]
                           $notes = $notes -replace "`r`n", "|"
                           If (($objuser.properties.item("lastlogontimestamp") | Measure-Object).Count -gt 0) {
                             $lastlogontimestamp = $objuser.properties.item("lastlogontimestamp")[0]
                             $lastLogon = [System.DateTime]::FromFileTime($lastlogontimestamp)
                             $lastLogonInDays = ((Get-Date) - $lastLogon).Days
                             if ($lastLogon -match "1/01/1601") {
                                    $lastLogon = "Never logged on before"
                               $lastLogonInDays = "N/A"
                                  }
                           } else {
                             $lastLogon = "Never logged on before"
                             $lastLogonInDays = "N/A"
                           }
                           $accountexpiration = $objuser.properties.item("accountexpires")[0]
                           If (($accountexpiration -eq 0) -OR ($accountexpiration -gt [DateTime]::MaxValue.Ticks)) {
                             $accountexpires = "<Never>"
                           } else {
                             $accountexpires = [datetime]::fromfiletime([int64]::parse($accountexpiration))
                           }

                            $pwdLastSet=$objuser.properties.item("pwdLastSet")
                           if ($pwdLastSet -gt 0)
                           {
                                  $pwdLastSet = [datetime]::fromfiletime([int64]::parse($pwdLastSet))
                                  $PasswordAge = ((get-date) - $pwdLastSet).days
                           }
                           Else {$PasswordAge = "<Not Set>"}                                                                        
                           $uac = $objuser.properties.item("useraccountcontrol")
                           $uac = $uac.item(0)
                           if (($uac -bor 0x0002) -eq $uac) {$disabled="TRUE"}
                           else {$disabled = "FALSE"}
                           if (($uac -bor 0x10000) -eq $uac) {$passwordneverexpires="TRUE"}
                           else {$passwordNeverExpires = "FALSE"}
                           if (($uac -bor 0x100000) -eq $uac) {$AccountNotDelegated="TRUE"}
                           else {$AccountNotDelegated = "FALSE"}
                        }      
                        
                        $groupnm = [string]$parentGroup.split(",")[0].split("=")[1]
                        $temp = [string]$parentGroup -split ',DC='
                        $domainn = $temp[1]
                                                                          
                        $record = "" | select-object SamAccountName,DistinguishedName,DisplayName,MemberOf,Group,Domain,CreatedDate,PasswordAge,LastLogon,LastLogonInDays,uac,Disabled,AccountNotDelegated,PasswordNeverExpires,AccountExpires,Description,Notes
                        $record.SamAccountName = [string]$sam
                        $record.DistinguishedName = [string]$dn
                        $record.displayName = $DisplayName
                        $record.MemberOf = [string]$parentGroup
                        $record.Group = $groupnm
                        $record.Domain = $domainn
                        $record.CreatedDate = [string]$createdDate
                        $record.PasswordAge = $PasswordAge
                        $record.LastLogon = $lastLogon
                        $record.LastLogonInDays = $lastLogonInDays
                        $record.uac = $uac
                        $record.Disabled = $disabled
                        $record.AccountNotDelegated  = $AccountNotDelegated 
                        $record.PasswordNeverExpires = $passwordNeverExpires
                        $record.AccountExpires = $accountexpires
                        $record.Description = $description
                        $record.Notes = $notes
                } 
$record
}
####### Function to find all Privileged Groups in the Forest ##########
Function getForestPrivGroups
{
  # Privileged Group Membership for the following groups:
  # - Enterprise Admins - SID: S-1-5-21root domain-519
  # - Schema Admins - SID: S-1-5-21root domain-518
  # - Domain Admins - SID: S-1-5-21domain-512
  # - Cert Publishers - SID: S-1-5-21domain-517
  # - Administrators - SID: S-1-5-32-544
  # - Account Operators - SID: S-1-5-32-548
  # - Server Operators - SID: S-1-5-32-549
  # - Backup Operators - SID: S-1-5-32-551
  # - Print Operators - SID: S-1-5-32-550
  # Reference: http://support.microsoft.com/kb/243330
  # - DNS Admins
  # Cryptographic Operators - S-1-5-32-569
  # ProtectedSID: S-1-5-21domain-525


                $colOfDNs = @()
                $Forest = [System.DirectoryServices.ActiveDirectory.forest]::getcurrentforest()
              $RootDomain = [string]($forest.rootdomain.name)
              $forestDomains = $forest.domains
              $colDomainNames = @()
              ForEach ($domain in $forestDomains)
              {
                     $domainname = [string]($domain.name)
                     $colDomainNames += $domainname
              }
              
                $ForestRootDN = FQDN2DN $RootDomain
              $colDomainDNs = @()
              ForEach ($domainname in $colDomainNames)
              {
                     $domainDN = FQDN2DN $domainname
                     $colDomainDNs += $domainDN 
              }

              $GC = $forest.FindGlobalCatalog()
                $adobject = [adsi]"GC://$ForestRootDN"
              $RootDomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0)
              $RootDomainSid = $RootDomainSid.toString()
              $colDASids = @()
              ForEach ($domainDN in $colDomainDNs)
              {
                     $adobject = [adsi]"GC://$domainDN"
                     $DomainSid = New-Object System.Security.Principal.SecurityIdentifier($AdObject.objectSid[0], 0)
                     $DomainSid = $DomainSid.toString()
                     $daSid = "$DomainSID-512"
                     $colDASids += $daSid
                     $cpSid = "$DomainSID-517"
                     $colDASids += $cpSid
                     $puSid = "$DomainSID-525"
                     $colDASids += $puSid
                     $dnsAdmObj = [adsi]"LDAP://CN=DnsAdmins,CN=Users,$domainDN"
                     $dnsAdm = New-Object System.Security.Principal.SecurityIdentifier($dnsAdmObj.objectSID[0], 0)
                     $dnsADm = $dnsAdm.ToString()
                     $colDASids += $dnsAdm
              }
             
              $colPrivGroups = @("S-1-5-32-569";"S-1-5-32-544";"S-1-5-32-548";"S-1-5-32-549";"S-1-5-32-551";"S-1-5-32-550";"$rootDomainSid-519";"$rootDomainSid-518")
              $colPrivGroups += $colDASids
              $searcher = $gc.GetDirectorySearcher()
              ForEach($privGroup in $colPrivGroups)
                {
                                $searcher.filter = "(objectSID=$privGroup)"
                                $Results = $Searcher.FindAll()
                                ForEach ($result in $Results)
                                {
                                                $dn = $result.properties.distinguishedname
                                                $colOfDNs += $dn
                                }
                }
$colofDNs
}

########################## Function to Generate Domain DN from FQDN ########
Function FQDN2DN
{
       Param ($domainFQDN)
       $colSplit = $domainFQDN.Split(".")
       $FQDNdepth = $colSplit.length
       $DomainDN = ""
       For ($i=0;$i -lt ($FQDNdepth);$i++)
       {
              If ($i -eq ($FQDNdepth - 1)) {$Separator=""}
              else {$Separator=","}
              [string]$DomainDN += "DC=" + $colSplit[$i] + $Separator
       }
       $DomainDN
}

########################## MAIN ###########################

$forestPrivGroups = GetForestPrivGroups
$colAllPrivUsers = @()

$rootdse=new-object directoryservices.directoryentry("LDAP://rootdse")

Foreach ($privGroup in $forestPrivGroups)
{
                Write-Host ""
              Write-Host "Enumerating $privGroup.." -foregroundColor yellow
                $uniqueMembers = @()
                $colOfMembersExpanded = @()
              $colofUniqueMembers = @()
                $members = getmemberexpanded $privGroup
                
                If ($members)
                {
                                $uniqueMembers = $members | sort-object -unique
                           $numberofUnique = ($uniqueMembers | measure-object).count
                           Foreach ($uniqueMember in $uniqueMembers)
                           {
                                  $objAttribs = getUserAccountAttribs $uniqueMember $privGroup
                                         $colOfuniqueMembers += $objAttribs      
                           }
                                $colAllPrivUsers += $colOfUniqueMembers
                }
                Else {$numberofUnique = 0}
                
                If ($numberofUnique -gt $MaxUniqueMembers)
                {
                                Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor Red
                }
              Else { Write-host "...$privGroup has $numberofUnique unique members" -foregroundColor White }

                $pwdneverExpiresCount = 0
                $pwdAgeCount = 0

                ForEach($user in $colOfuniquemembers)
                {
                                $i = 0
                                $userpwdAge = $user.PasswordAge
                                $userpwdneverExpires = $user.PasswordNeverExpires
                                $userSAM = $user.SamAccountName
                                IF ($userpwdneverExpires -eq $True)
                                {
                                  $pwdneverExpiresCount ++
                                  $i ++
                                  If ($DetailedConsoleOutput) {Write-host "......$userSAM has a password age of $userpwdage and the password is set to never expire" -foregroundColor Green}
                                }
                                If ($userpwdAge -gt $MaxPasswordAge)
                                {
                                  $pwdAgeCount ++
                                  If ($i -gt 0)
                                  {
                                    If ($DetailedConsoleOutput) {Write-host "......$userSAM has a password age of $userpwdage days" -foregroundColor Green}
                                  }
                                }
                }

                If ($numberofUnique -gt 0)
                {
                                Write-host "......There are $pwdneverExpiresCount accounts that have the password is set to never expire." -foregroundColor Green
                                Write-host "......There are $pwdAgeCount accounts that have a password age greater than $MaxPasswordAge days." -foregroundColor Green
                }
}

write-host "`nComments:" -foregroundColor Yellow
write-host " - If a privileged group contains more than $MaxUniqueMembers unique members, it's highlighted in red." -foregroundColor Yellow
If ($DetailedConsoleOutput) {
  write-host " - The privileged user is listed if their password is set to never expire." -foregroundColor Yellow
  write-host " - The privileged user is listed if their password age is greater than $MaxPasswordAge days." -foregroundColor Yellow
  write-host " - Service accounts should not be privileged users in the domain." -foregroundColor Yellow
}

$colAllPrivUsers | Export-CSV -notype -path "$ReferenceFile" -Delimiter ';'

# Remove the quotes
(get-content "$ReferenceFile") |% {$_ -replace '"',""} | out-file "$ReferenceFile" -Fo -En ascii 