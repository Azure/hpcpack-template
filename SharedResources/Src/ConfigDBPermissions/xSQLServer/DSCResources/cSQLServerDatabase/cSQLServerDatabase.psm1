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
        [System.String]
        $Database,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [System.String]
        $Location = "",

        [System.Int32]
        $DataFileSizeInMB = 1024,

        [System.Int32]
        $DataFileGrowthPercent = 50,

        [System.Int32]
        $LogFileSizeInMB = 128,

        [System.Int32]
        $LogFileGrowthPercent = 10
    )
    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        # Check database exists
        $SQLDatabase = $sql.Databases.Contains($Database)
        $Present = $SQLDatabase
    }
    
    $returnValue = @{
        Database = $Database
        Ensure = $Present
        SQLServer = $SQLServer
        SQLInstanceName = $SQLInstanceName
        Location = $Location
        DataFileSizeInMB = $DataFileSizeInMB
        DataFileGrowthPercent = $DataFileGrowthPercent
        LogFileSizeInMB = $LogFileSizeInMB
        LogFileGrowthPercent = $LogFileGrowthPercent
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Database,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [System.String]
        $Location = "",

        [System.Int32]
        $DataFileSizeInMB = 1024,

        [System.Int32]
        $DataFileGrowthPercent = 50,

        [System.Int32]
        $LogFileSizeInMB = 128,

        [System.Int32]
        $LogFileGrowthPercent = 10
    )

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        if($Ensure -eq "Present")
        {
            if([string]::IsNullOrEmpty($Location))
            {
                $LogLocation = $SQL.Settings.DefaultLog
                $FileLocation = $SQL.Settings.DefaultFile
            }
            else
            {
                $LogLocation = $Location
                $FileLocation = $Location               
            }

            $MyDB = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $SQL,$Database
            $MyPrimaryDBFG = New-Object -TypeName Microsoft.SqlServer.Management.Smo.FileGroup -ArgumentList $MyDB, 'PRIMARY'
            $MyDB.FileGroups.Add($MyPrimaryDBFG)
            $DBDataFileLogicName = $Database + '_data'
            $MyDBDataFile = New-Object -TypeName Microsoft.SqlServer.Management.Smo.DataFile -ArgumentList $MyPrimaryDBFG, $DBDataFileLogicName
            $MyPrimaryDBFG.Files.Add($MyDBDataFile)
            $MyDBDataFile.FileName = [IO.Path]::Combine($FileLocation, $Database + ".mdf")
            $MyDBDataFile.Size = [double] ($DataFileSizeInMB * 1024.0)
            $MyDBDataFile.GrowthType = "Percent"
            $MyDBDataFile.Growth = [double] $DataFileGrowthPercent

            $DBLogFileLogicName = $Database + '_log'
            $MyDBLogFile = New-Object -TypeName Microsoft.SqlServer.Management.Smo.LogFile -ArgumentList $MyDB, $DBLogFileLogicName
            $MyDB.LogFiles.Add($MyDBLogFile)
            $MyDBLogFile.FileName = [IO.Path]::Combine($LogLocation, $DBLogFileLogicName + ".ldf")
            $MyDBLogFile.Size = [double] ($LogFileSizeInMB * 1024.0)
            $MyDBLogFile.GrowthType = "Percent"
            $MyDBLogFile.Growth = [double] $LogFileGrowthPercent

            $MyDB.Create()
            New-VerboseMessage -Message "Created Database $Database"
        }
        else
        {
            $sql.Databases[$Database].Drop()
            New-VerboseMessage -Message "Dropped Database $Database"
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
        [System.String]
        $Database,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SQLServer = $env:COMPUTERNAME,

        [System.String]
        $SQLInstanceName = "MSSQLSERVER",

        [System.String]
        $Location = "",

        [System.Int32]
        $DataFileSizeInMB = 1024,

        [System.Int32]
        $DataFileGrowthPercent = 50,

        [System.Int32]
        $LogFileSizeInMB = 128,

        [System.Int32]
        $LogFileGrowthPercent = 10
    )
    

    if(!$SQL)
    {
        $SQL = Connect-SQL -SQLServer $SQLServer -SQLInstanceName $SQLInstanceName
    }

    if($SQL)
    {
        # Check database exists
        $SQLDatabase = $sql.Databases.Contains($Database)
        $Present = $SQLDatabase
    }
    if($ensure -eq "Present")
    {$result =  $Present}
    if($ensure -eq "Absent")
    {$result = !$present}

    $result
}


Export-ModuleMember -Function *-TargetResource

