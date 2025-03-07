param
(
    [Parameter(Mandatory = $true)]
    [string] $domainPassword
)

$secureDomainPassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force

New-ADUser -Name D_admin -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_admin_E -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name BVT_USER -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_power -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_power_E -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_guest -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_guest_E -AccountPassword $secureDomainPassword -Enabled $true

New-ADUser -Name "Domain Admins" -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_UIadmin -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_JobAdmin -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_JobAdmin1 -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_JobOptr -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_JobOptr1 -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_User -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name d_unicodepwd -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name d_email1 -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name d_email2 -AccountPassword $secureDomainPassword -Enabled $true
New-ADUser -Name D_127cPwd -AccountPassword $secureDomainPassword -Enabled $true
