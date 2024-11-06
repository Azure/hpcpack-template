# Zip all *.ps1 folders to *.ps1.zip files for PowerShell VM Extension consumption
$scriptPath = $PSScriptRoot
$zipFolders = Get-ChildItem -Path $scriptPath -Directory -Filter "*.ps1"
foreach ($folder in $zipFolders) {
    $zipFileName = $folder.FullName + ".zip"
    if (Test-Path -Path $zipFileName) {
        Remove-Item -Path $zipFileName -Force
    }
    Compress-Archive -Path "$($folder.FullName)\*" -DestinationPath $zipFileName
}