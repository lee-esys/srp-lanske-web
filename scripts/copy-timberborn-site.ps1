param(
    [string]$SourcePath,
    [string]$DestinationPath
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspaceRoot = Split-Path $repoRoot -Parent

if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = Join-Path $workspaceRoot 'timberborn-lab\site'
}

if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $DestinationPath = Join-Path $repoRoot 'build\web\timberborn'
}

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Timberborn site source was not found: $SourcePath"
}

$sourceIndex = Join-Path $SourcePath 'index.html'
if (-not (Test-Path -LiteralPath $sourceIndex -PathType Leaf)) {
    throw "Timberborn site source does not contain index.html: $sourceIndex"
}

$hostingRoot = Join-Path $repoRoot 'build\web'
if (-not (Test-Path -LiteralPath $hostingRoot -PathType Container)) {
    throw "Flutter web build output was not found: $hostingRoot. Run 'flutter build web' before this script."
}

$resolvedSourcePath = (Resolve-Path -LiteralPath $SourcePath).Path

$destinationParent = Split-Path $DestinationPath -Parent
if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
}

if (Test-Path -LiteralPath $DestinationPath) {
    Remove-Item -LiteralPath $DestinationPath -Recurse -Force
}

New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

Get-ChildItem -LiteralPath $resolvedSourcePath -Force |
    Copy-Item -Destination $DestinationPath -Recurse -Force

$destinationIndex = Join-Path $DestinationPath 'index.html'
if (-not (Test-Path -LiteralPath $destinationIndex -PathType Leaf)) {
    throw "Copy completed without index.html at destination: $destinationIndex"
}

$fileCount = (Get-ChildItem -LiteralPath $DestinationPath -Recurse -File -Force | Measure-Object).Count

Write-Host ''
Write-Host 'Timberborn site copy completed.'
Write-Host "  Source      : $resolvedSourcePath"
Write-Host "  Destination : $DestinationPath"
Write-Host "  Files       : $fileCount"
Write-Host '  Public path : /timberborn/'
