param
(
    [Parameter(Mandatory = $true)]
    [string] $domainPassword
)

# $ErrorActionPreference = 'Stop'
$time = (Get-Date).ToUniversalTime().ToString("yyyy_MM_dd_HH_mm_ss")
$logLocation = "c:\BVT_log\$time"
mkdir $logLocation >$null

"add domain users part1" | Out-File -FilePath $logLocation\AddBVTUser.log -Append
net user D_admin $domainPassword /add /domain 2>&1 | Out-File -FilePath $logLocation\AddBVTUser.log -Append
net user D_admin_E $domainPassword /add /domain 2>&1 | Out-File -FilePath $logLocation\AddBVTUser.log -Append
net user BVT_USER $domainPassword /add /domain 2>&1 | Out-File -FilePath $logLocation\AddBVTUser.log -Append
# net user D_power $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_power_E $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_guest $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_guest_E $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1

# "add domain users part2" >> $logLocation\AddBVTUser.log 2>&1
# net user "Domain Admins" $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_UIadmin $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_JobAdmin $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_JobAdmin1 $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_JobOptr $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_JobOptr1 $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_User $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_unicodepwd $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_email1 $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_email2 $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# net user D_127cPwd $domainPassword /add /domain > $logLocation\AddBVTUser.log 2>&1
# "finish adding domain users" >> $logLocation\AddBVTUser.log 2>&1
