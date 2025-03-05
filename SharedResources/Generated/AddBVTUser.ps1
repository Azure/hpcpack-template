param
(
    [Parameter(Mandatory = $true)]
    [string] $domainPassword
)

$secureDomainPassword = ConvertTo-SecureString $domainPassword -AsPlainText -Force
New-ADUser -Name D_power -AccountPassword $secureDomainPassword -Enabled $true
