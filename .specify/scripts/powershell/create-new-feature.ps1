#!/usr/bin/env pwsh
# Create a new feature
$ErrorActionPreference = 'Stop'

$flags = @{
    'Json' = $false
}

$descriptionParts = @()
foreach ($arg in $args) {
    if ($null -ne $arg -and $arg.ToString().ToLowerInvariant() -eq '-json') {
        $flags['Json'] = $true
    } else {
        $descriptionParts += $arg
    }
}

if (-not $descriptionParts -or $descriptionParts.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] <feature description>"
    exit 1
}
$featureDesc = ($descriptionParts -join ' ').Trim()

# Resolve repository root. Prefer git information when available, but fall back
# to searching for repository markers so the workflow still functions in repositories that
# were initialised with --no-git.
function Find-RepositoryRoot {
    param(
        [string]$StartDir,
        [string[]]$Markers = @('.git', '.specify')
    )
    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            if (Test-Path (Join-Path $current $marker)) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            # Reached filesystem root without finding markers
            return $null
        }
        $current = $parent
    }
}
$fallbackRoot = (Find-RepositoryRoot -StartDir $PSScriptRoot)
if (-not $fallbackRoot) {
    Write-Error "Error: Could not determine repository root. Please run this script from within the repository."
    exit 1
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGit = $true
    } else {
        throw "Git not available"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

$highest = 0
if (Test-Path $specsDir) {
    Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
        if ($_.Name -match '^(\d{3})') {
            $num = [int]$matches[1]
            if ($num -gt $highest) { $highest = $num }
        }
    }
}
$next = $highest + 1
$featureNum = ('{0:000}' -f $next)

$branchName = $featureDesc.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
$words = ($branchName -split '-') | Where-Object { $_ } | Select-Object -First 3
$branchName = "$featureNum-$([string]::Join('-', $words))"

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $branchName"
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot '.specify/templates/spec-template.md'
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) {
    Copy-Item $template $specFile -Force
} else {
    New-Item -ItemType File -Path $specFile | Out-Null
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

function Escape-JsonString {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $escaped = $Value -replace '\\','\\\\'
    return ($escaped -replace '"','\\"')
}

if ($flags['Json']) {
    $json = '{'
    $json += '"BRANCH_NAME":"{0}",' -f (Escape-JsonString $branchName)
    $json += '"SPEC_FILE":"{0}",' -f (Escape-JsonString $specFile)
    $json += '"FEATURE_NUM":"{0}",' -f (Escape-JsonString $featureNum)
    $hasGitLiteral = if ($hasGit) { 'true' } else { 'false' }
    $json += '"HAS_GIT":{0}' -f $hasGitLiteral
    $json += '}'
    Write-Output $json
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "HAS_GIT: $hasGit"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}
