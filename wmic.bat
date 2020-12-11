Host Enumeration:

--- OS Specifics ---
wmic os LIST Full (* To obtain the OS Name, use the "caption" property)

wmic computersystem LIST full

--- Anti-Virus ---

wmic /namespace:\\root\securitycenter2 path antivirusproduct

--- Peripherals ---
wmic path Win32_PnPdevice 

--- Installed Updates ---
wmic qfe list brief

--- Directory Listing and File Search ---

wmic DATAFILE where "path='\\Users\\test\\Documents\\'" GET Name,readable,size

wmic DATAFILE where "drive='C:' AND Name like '%password%'" GET Name,readable,size /VALUE

--- Local User Accounts ---

wmic USERACCOUNT Get Domain,Name,Sid

Domain Enumeration:

--- Domain and DC Info ---

wmic NTDOMAIN GET DomainControllerAddress,DomainName,Roles /VALUE

--- Domain User Info ---

wmic /NAMESPACE:\\root\directory\ldap PATH ds_user where "ds_samaccountname='testAccount'" GET 


--- List All Users ---

wmic /NAMESPACE:\\root\directory\ldap PATH ds_user GET ds_samaccountname

--- List All Groups ---

wmic /NAMESPACE:\\root\directory\ldap PATH ds_group GET ds_samaccountname

--- Members of A Group ---

wmic /NAMESPACE:\\root\directory\ldap PATH ds_group where "ds_samaccountname='Domain Admins'" Get ds_member /Value
wmic path win32_groupuser where (groupcomponent="win32_group.name="domain admins",domain="YOURDOMAINHERE"")

--- List All Computers ---

wmic /NAMESPACE:\\root\directory\ldap PATH ds_computer GET ds_samaccountname

OR

wmic /NAMESPACE:\\root\directory\ldap PATH ds_computer GET ds_dnshostname

Misc:

--- Execute Remote Command ---

wmic process call create "cmd.exe /c calc.exe"

--- Enable Remote Desktop ---

wmic rdtoggle where AllowTSConnections="0" call SetAllowTSConnections "1"

OR

wmic /node:remotehost path Win32_TerminalServiceSetting where AllowTSConnections="0" call SetAllowTSConnections "1"