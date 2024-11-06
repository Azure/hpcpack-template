function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [String]$ComputerName,

        [UInt32]$RetryIntervalSec = 20,

        [UInt32]$RetryCount = 90
    )

  
    $computerName = Get-ADComputer -Filter {Name -eq $ComputerName} | %{$_.Name}
         
   
    $returnValue = @{
        ComputerName = $computerName
        RetryIntervalSec = $RetryIntervalSec
        RetryCount = $RetryCount
    }
    
    $returnValue
}


function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [String]$ComputerName,

        [UInt32]$RetryIntervalSec = 20,

        [UInt32]$RetryCount = 90
    )

    $count = 0
    while($true)
    {
        $computer = Get-ADComputer -Filter {Name -eq $ComputerName}
         
        if($computer)
        {
            break;
        }
        else
        {
            if($count++ -ge $RetryCount)
            {
                throw "Computer $ComputerName not found after $RetryCount retries"
            }
            else
            {
                Write-Verbose -Message "Computer $ComputerName not found. Will retry again after $RetryIntervalSec sec"
                Start-Sleep -Seconds $RetryIntervalSec
                Clear-DnsClientCache
            }
        }
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [String]$ComputerName,

        [UInt32]$RetryIntervalSec = 20,

        [UInt32]$RetryCount = 90
    )
    
    $computer = Get-ADComputer -Filter {Name -eq $ComputerName}
   
    if($computer)
    {
        $true
    }
    else 
    {
        $false
    }    
}
