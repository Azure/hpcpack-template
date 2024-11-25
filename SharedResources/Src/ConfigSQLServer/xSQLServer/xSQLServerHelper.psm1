# Set Global Module Verbose
$VerbosePreference = 'Continue' 

# Load Localization Data 
Import-LocalizedData LocalizedData -filename xSQLServer.strings.psd1 -ErrorAction SilentlyContinue 
Import-LocalizedData USLocalizedData -filename xSQLServer.strings.psd1 -UICulture en-US -ErrorAction SilentlyContinue

function Connect-SQL
{
[CmdletBinding()]
    param
    (   [ValidateNotNull()] 
        [System.String]
        $SQLServer = $env:COMPUTERNAME,
        
        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )
    
    $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
    
    if($SQLInstanceName -eq "MSSQLSERVER")
    {
        $ConnectSQL = $SQLServer
    }
    else
    {
        $ConnectSQL = "$SQLServer\$SQLInstanceName"
    }
    if ($SetupCredential)
    {
        $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server
        $SQL.ConnectionContext.ConnectAsUser = $true
        $SQL.ConnectionContext.ConnectAsUserPassword = $SetupCredential.GetNetworkCredential().Password
        $SQL.ConnectionContext.ConnectAsUserName = $SetupCredential.GetNetworkCredential().UserName 
        $SQL.ConnectionContext.ServerInstance = $ConnectSQL
        $SQL.ConnectionContext.connect()
    }
    else
    {
        $SQL = New-Object Microsoft.SqlServer.Management.Smo.Server $ConnectSQL
    }
    if($SQL)
    {
        New-VerboseMessage -Message "Connected to SQL $ConnectSQL"
        $SQL
    }
    else
    {
        Throw -Message "Failed connecting to SQL $ConnectSQL"
        Exit
    }
}

function New-TerminatingError 
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ErrorType,

        [parameter(Mandatory = $false)]
        [String[]]
        $FormatArgs,

        [parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory = [System.Management.Automation.ErrorCategory]::OperationStopped,

        [parameter(Mandatory = $false)]
        [Object]
        $TargetObject = $null
    )

    $errorMessage = $LocalizedData.$ErrorType
    
    if(!$errorMessage)
    {
        $errorMessage = ($LocalizedData.NoKeyFound -f $ErrorType)

        if(!$errorMessage)
        {
            $errorMessage = ("No Localization key found for key: {0}" -f $ErrorType)
        }
    }

    $errorMessage = ($errorMessage -f $FormatArgs)

    $callStack = Get-PSCallStack 

    # Get Name of calling script
    if($callStack[1] -and $callStack[1].ScriptName)
    {
        $scriptPath = $callStack[1].ScriptName

        $callingScriptName = $scriptPath.Split('\')[-1].Split('.')[0]
    
        $errorId = "$callingScriptName.$ErrorType"
    }
    else
    {
        $errorId = $ErrorType
    }


    Write-Verbose -Message "$($USLocalizedData.$ErrorType -f $FormatArgs) | ErrorType: $errorId"

    $exception = New-Object System.Exception $errorMessage;
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $ErrorCategory, $TargetObject

    return $errorRecord
}


function New-VerboseMessage
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true)]
        $Message
    )
    Write-Verbose -Message ((Get-Date -format yyyy-MM-dd_HH-mm-ss) + ": $Message");

}

function Grant-ServerPerms
{
[CmdletBinding()]
    param
    (
        [ValidateNotNull()]         
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName= "MSSQLSERVER",

        [ValidateNotNullOrEmpty()]  
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential,

        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory = $true)]
        [System.String]
        $AuthorizedUser
    )
    
    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    }
    Try{
        $sps = New-Object Microsoft.SqlServer.Management.Smo.ServerPermissionSet([Microsoft.SqlServer.Management.Smo.ServerPermission]::AlterAnyAvailabilityGroup)
        $sps.Add([Microsoft.SqlServer.Management.Smo.ServerPermission]::ViewServerState)
        $SQL.Grant($sps,$AuthorizedUser)
        New-VerboseMessage -Message "Granted Permissions to $AuthorizedUser"
        }
    Catch{
        Write-Error "Failed to grant Permissions to $AuthorizedUser."
        }
}

function Grant-CNOPerms
{
[CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupNameListener,
        
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory = $true)]
        [System.String]
        $CNO
    )

    #Verify Active Directory Tools are installed, if they are load if not Throw Error
    If (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"})){
        Throw "Active Directory Module is not installed and is Required."
        Exit
    }
    else{Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false}
    Try{
        $AG = Get-ADComputer $AvailabilityGroupNameListener
        
        $comp = $AG.DistinguishedName  # input AD computer distinguishedname
        $acl = Get-Acl "AD:\$comp" 
        $u = Get-ADComputer $CNO                        # get the AD user object given full control to computer
        $SID = [System.Security.Principal.SecurityIdentifier] $u.SID
        
        $identity = [System.Security.Principal.IdentityReference] $SID
        $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
        $type = [System.Security.AccessControl.AccessControlType] "Allow"
        $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
        
        $acl.AddAccessRule($ace) 
        Set-Acl -AclObject $acl "AD:\$comp"
        New-VerboseMessage -Message "Granted privileges on $comp to $CNO"
        }
    Catch{
        Throw "Failed to grant Permissions on $comp."
        Exit
        } 
}

function New-ListenerADObject
{
[CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory = $true)]
        [System.String]
        $AvailabilityGroupNameListener,
        
        [ValidateNotNull()] 
        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [ValidateNotNull()] 
        [System.String]
        $SQLInstanceName = "MSSQLSERVER",
    
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $SetupCredential
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName -SetupCredential $SetupCredential
    }

    $CNO= $SQL.ClusterName
        
    #Verify Active Directory Tools are installed, if they are load if not Throw Error
    If (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"})){
        Throw "Active Directory Module is not installed and is Required."
        Exit
    }
    else{Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false}
    try{
        $CNO_OU = Get-ADComputer $CNO
        #Accounts for the comma and CN= at the start of Distinguished Name
        #We want to remove these plus the ClusterName to get the actual OU Path.
        $AdditionalChars = 4
        $Trim = $CNO.Length+$AdditionalChars
        $CNOlgth = $CNO_OU.DistinguishedName.Length - $trim
        $OUPath = $CNO_OU.ToString().Substring($Trim,$CNOlgth)
        }
    catch{
        Throw ": Failed to find Computer in AD"
        exit
    }
    
    
    $m = Get-ADComputer -Filter {Name -eq $AvailabilityGroupNameListener} -Server $env:USERDOMAIN | Select-Object -Property * | Measure-Object
    
    If ($m.Count -eq 0)
    {
        Try{
            #Create Computer Object for the AgListenerName
            New-ADComputer -Name $AvailabilityGroupNameListener -SamAccountName $AvailabilityGroupNameListener -Path $OUPath -Enabled $false -Credential $SetupCredential
            New-VerboseMessage -Message "Created Computer Object $AvailabilityGroupNameListener"
            }
        Catch{
               Throw "Failed to Create $AvailabilityGroupNameListener in $OUPath"
            Exit
            }
            
            $SucccessChk =0
    
        #Check for AD Object Validate at least three successful attempts 
        $i=1
        While ($i -le 5) {
            Try{
                $ListChk = Get-ADComputer -filter {Name -like $AvailabilityGroupNameListener}
                If ($ListChk){$SuccessChk++}
                Start-Sleep -Seconds 10  
                If($SuccesChk -eq 3){break}
               }
            Catch{
                 Throw "Failed Validate $AvailabilityGroupNameListener was created in $OUPath"
                 Exit
            }
            $i++
        }            
    }
    Try{
        Grant-CNOPerms -AvailabilityGroupNameListener $AvailabilityGroupNameListener -CNO $CNO
        }
    Catch{
          Throw "Failed Validate grant permissions on $AvailabilityGroupNameListener in location $OUPAth to $CNO"
          Exit
        }

}
