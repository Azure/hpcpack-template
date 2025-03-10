param
(
    [Parameter(Mandatory = $true)]
    [string] $domainPassword
)

write-host "add domain users part1"
net user D_admin $domainPassword /add /domain
net user D_admin_E $domainPassword /add /domain
net user BVT_USER $domainPassword /add /domain
net user D_power $domainPassword /add /domain
net user D_power_E $domainPassword /add /domain
net user D_guest $domainPassword /add /domain
net user D_guest_E $domainPassword /add /domain

write-host "add domain users part2"
net user "Domain Admins" $domainPassword /add /domain
net user D_UIadmin $domainPassword /add /domain
net user D_JobAdmin $domainPassword /add /domain
net user D_JobAdmin1 $domainPassword /add /domain
net user D_JobOptr $domainPassword /add /domain
net user D_JobOptr1 $domainPassword /add /domain
net user D_User $domainPassword /add /domain
net user D_unicodepwd $domainPassword /add /domain
net user D_email1 $domainPassword /add /domain
net user D_email2 $domainPassword /add /domain
net user D_127cPwd $domainPassword /add /domain
write-host "finish adding domain users"
