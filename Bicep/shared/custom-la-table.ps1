param(
  [string] $workSpaceResId
)

$ErrorActionPreference = 'Stop'

# NOTE: The column "TimeGenerated" is mandatory. Do not change the name and type.
$tableParams = @'
{
  "properties": {
    "schema": {
      "name": "TraceListener_CL",
      "columns": [
        {
          "name": "TimeGenerated",
          "type": "datetime",
          "description": "The time at which the log was generated"
        },
        {
          "name": "ComputerName",
          "type": "string",
          "description": "The name of the computer that generated the log"
        },
        {
          "name": "ProcessName",
          "type": "string",
          "description": "The name of the process that generated the log"
        },
        {
          "name": "ProcessId",
          "type": "int",
          "description": "The id of the process that generated the log"
        },
        {
          "name": "EventType",
          "type": "string",
          "description": "Log event type, such as error, info, etc."
        },
        {
          "name": "EventId",
          "type": "int",
          "description": "Log event id"
        },
        {
          "name": "Source",
          "type": "string",
          "description": "Log source"
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
Invoke-AzRestMethod -Path "$workSpaceResId/tables/TraceListener_CL?api-version=2022-10-01" -Method PUT -payload $tableParams