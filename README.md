# ActiveDirectory
Tools and scripts for securing and auditing Active Directory

# Script ADAudit
Script is used to get a list of critical groups in active directory and the members.

Name of outputfile is defined in line 63

Just run the script via ./auditAD.ps1 and check the results

Overview of privileged groups and the attack vector

| **Group**                               | **Description**                                                      | **Attack Vector**                                                                                                                | **Link **                                                                                         | **** | **** | **** | **** | **** | **** |
|-----------------------------------------|----------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|------|------|------|------|------|------|
| **Enterprise Admins**                   | Full access to whole forest (all domains)                            | "Full God-Mode", can change everything within AD                                                                                 | -                                                                                                 |      |      |      |      |      |      |
| **Domain Admins**                       | Access to domain controllers and users in one domain                 | "God-Mode", can change everything within one domain and access to every system possible, cross domain escalation easily possible | -                                                                                                 |      |      |      |      |      |      |
| **Administrators**                      | Access to domain controllers in one domain                           | "little God-Mode", can change everything in Active Directory within one domain, cross domain escalation easily possible          | -                                                                                                 |      |      |      |      |      |      |
| **Schema Admins**                       | Change the AD schema                                                 | Adapt the schema to grant access to every new object                                                                             | https://cube0x0.github.io/Pocing-Beyond-DA/                                                       |      |      |      |      |      |      |
| **Account Operators / Sever Operators** | Manage user and computer objects                                     | Serveral vectors possible, e.g. change service (running with privileged user) on server to add user to domain admin group        | https://cube0x0.github.io/Pocing-Beyond-DA/                                                       |      |      |      |      |      |      |
| **Backup Operators**                    | Backup and restore any files (independent from file access settings) | Read registry from domain controller                                                                                             | https://securityonline.info/backupoperatortoda-from-backup-operator-to-domain-admin/              |      |      |      |      |      |      |
| **Print Operators**                     | Manage printers                                                      | Load und run malicious printer driver on domain controller                                                                       | https://www.tarlogic.com/blog/abusing-seloaddriverprivilege-for-privilege-escalation/             |      |      |      |      |      |      |
| **DNSadmins**                           | Configure DNS settings                                               | Inject malicious DLL into DNS service, to run arbitrary commands on the dc.                                                      | https://medium.com/@esnesenon/feature-not-bug-dnsadmin-to-dc-compromise-in-one-line-a0f779b8dc83  |      |      |      |      |      |      |
| **null**                                |                                                                      | Patched in October 2021                                                                                                          |                                                                                                   |      |      |      |      |      |      |

