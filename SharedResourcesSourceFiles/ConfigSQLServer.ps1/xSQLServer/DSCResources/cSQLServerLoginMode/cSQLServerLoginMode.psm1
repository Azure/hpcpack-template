$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Integrated", "Mixed")]
        [System.String] $LoginMode
    )
    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $env:COMPUTERNAME -SQLInstanceName $SQLInstanceName
    }

    $LoginMode = "Unkown"
    if($SQL)
    {
        # Check current mode
        $LoginMode = $SQL.Settings.LoginMode.ToString()
    }
    
    $returnValue = @{
        SQLInstanceName = $SQLInstanceName
        LoginMode = $LoginMode
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Integrated", "Mixed")]
        [System.String] $LoginMode
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $env:COMPUTERNAME -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        $orgMode = $SQL.Settings.LoginMode
        if($orgMode -ne $LoginMode)
        {
            $SQL.Settings.LoginMode = $LoginMode
            $SQL.Settings.Alter()
            New-VerboseMessage -Message "Changed the LoginMode from $orgMode to $LoginMode"
            Write-Verbose "SQL Service will be restarted ..."
            if($SQLInstanceName -eq "MSSQLSERVER")
            {
                $dbServiceName = "MSSQLSERVER"
            }
            else
            {
                $dbServiceName = "MSSQL`$$InstanceName"
            }

            Restart-Service -Name $dbServiceName -Force
        }
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String] $SQLInstanceName,

        [parameter(Mandatory = $true)]
        [ValidateSet("Integrated", "Mixed")]
        [System.String] $LoginMode
    )
    

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $env:COMPUTERNAME -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        return ($SQL.Settings.LoginMode -eq $LoginMode)
    }

    return $false
}


Export-ModuleMember -Function *-TargetResource

