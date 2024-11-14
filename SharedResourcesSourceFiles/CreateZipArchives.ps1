# Zip all *.ps1 folders to *.ps1.zip files for PowerShell VM Extension consumption
$scriptPath = $PSScriptRoot
$zipFolders = Get-ChildItem -Path $scriptPath -Directory -Filter "*.ps1"
foreach ($folder in $zipFolders) {
    $zipFileName = $folder.FullName + ".zip"
    $targetFileName = Split-Path -Path $zipFileName -Leaf
    Compress-Archive -Path "$($folder.FullName)\*" -DestinationPath $scriptPath\..\SharedResources\$targetFileName -Force
}