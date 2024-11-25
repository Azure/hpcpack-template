param(
	[Parameter(Mandatory)]
	[string] $targetDir,

	[string[]]$sourceDirs = @('ConfigDBPermissions', 'ConfigSQLServer', 'CreateADPDC', 'InstallHpcNode', 'InstallPrimaryHeadNode', 'JoinADDomain')
)

$ErrorActionPreference = 'Stop'

$basePath = $PSScriptRoot

foreach ($src in $sourceDirs)
{
	$srcPath = Join-Path -Path $basePath -ChildPath $src
	$targetName = $src + ".ps1.zip"
	$targetPath = Join-Path -Path $targetDir -ChildPath $targetName
	Compress-Archive -Path "$srcPath\*" -DestinationPath $targetPath -Force
}

