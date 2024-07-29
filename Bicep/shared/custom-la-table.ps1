param(
  [string] $workSpaceResId
)

$ErrorActionPreference = 'Stop'

# NOTE: The column "TimeGenerated" is mandatory. Do not change the name and type.
$tableParams = @'
{
  "properties": {
    "schema": {
      "name": "HPCPack_CL",
      "columns": [
        {
          "name": "TimeGenerated",
          "type": "datetime",
          "description": "The time at which the log was generated"
        },
        {
          "name": "Computer",
          "type": "string",
          "description": "The computer that generated the log"
        },
        {
          "name": "Service",
          "type": "string",
          "description": "The service that generated the log"
        },
        {
          "name": "Process",
          "type": "int",
          "description": "The the process that generated the log"
        },
        {
          "name": "Level",
          "type": "string",
          "description": "Log level"
        },
        {
          "name": "Content",
          "type": "string",
          "description": "Log content"
        }
      ]
    }
  }
}
'@

# TODO: Fail the script on failed HTTP request!
Invoke-AzRestMethod -Path "$workSpaceResId/tables/HPCPack_CL?api-version=2022-10-01" -Method PUT -payload $tableParams