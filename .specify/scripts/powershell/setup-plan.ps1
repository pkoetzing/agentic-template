#!/usr/bin/env pwsh
# Setup implementation plan for a feature

$ErrorActionPreference = 'Stop'

$flags = @{
    'Json' = $false
    'Help' = $false
}

foreach ($arg in $args) {
    if ($null -eq $arg) { continue }
    $normalized = $arg.ToString().ToLowerInvariant()
    switch ($normalized) {
        '-json' { $flags['Json'] = $true; continue }
        '-help' { $flags['Help'] = $true; continue }
        '-h'    { $flags['Help'] = $true; continue }
        default {
            Write-Error "Unknown argument: $arg"
            exit 1
        }
    }
}

function Escape-JsonValue {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $escaped = $Value -replace '\\','\\\\'
    return ($escaped -replace '"','\\"')
}

# Show help if requested
if ($flags['Help']) {
    Write-Output "Usage: ./setup-plan.ps1 [-Json] [-Help]"
    Write-Output "  -Json     Output results in JSON format"
    Write-Output "  -Help     Show this help message"
    exit 0
}

# Load common functions
. "$PSScriptRoot/common.ps1"

# Get all paths and variables from common functions
$paths = Get-FeaturePathsEnv

# Check if we're on a proper feature branch (only for git repos)
if (-not (Test-FeatureBranch -Branch $paths['CURRENT_BRANCH'] -HasGit $paths['HAS_GIT'])) {
    exit 1
}

# Ensure the feature directory exists
New-Item -ItemType Directory -Path $paths['FEATURE_DIR'] -Force | Out-Null

# Copy plan template if it exists, otherwise note it or create empty file
$template = Join-Path $paths['REPO_ROOT'] '.specify/templates/plan-template.md'
if (Test-Path $template) {
    Copy-Item $template $paths['IMPL_PLAN'] -Force
    Write-Output "Copied plan template to $($paths['IMPL_PLAN'])"
} else {
    Write-Warning "Plan template not found at $template"
    # Create a basic plan file if template doesn't exist
    New-Item -ItemType File -Path $paths['IMPL_PLAN'] -Force | Out-Null
}

# Output results
if ($flags['Json']) {
    $json = '{'
    $json += '"FEATURE_SPEC":"{0}",' -f (Escape-JsonValue $paths['FEATURE_SPEC'])
    $json += '"IMPL_PLAN":"{0}",' -f (Escape-JsonValue $paths['IMPL_PLAN'])
    $json += '"SPECS_DIR":"{0}",' -f (Escape-JsonValue $paths['FEATURE_DIR'])
    $branchValue = Escape-JsonValue $paths['CURRENT_BRANCH']
    $json += '"BRANCH":"{0}",' -f $branchValue
    $hasGitLiteral = if ($paths['HAS_GIT']) { 'true' } else { 'false' }
    $json += '"HAS_GIT":{0}' -f $hasGitLiteral
    $json += '}'
    Write-Output $json
} else {
    Write-Output "FEATURE_SPEC: $($paths['FEATURE_SPEC'])"
    Write-Output "IMPL_PLAN: $($paths['IMPL_PLAN'])"
    Write-Output "SPECS_DIR: $($paths['FEATURE_DIR'])"
    Write-Output "BRANCH: $($paths['CURRENT_BRANCH'])"
    Write-Output "HAS_GIT: $($paths['HAS_GIT'])"
}
