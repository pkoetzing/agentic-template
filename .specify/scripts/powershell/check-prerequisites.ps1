#!/usr/bin/env pwsh

# Consolidated prerequisite checking script (PowerShell)
#
# This script provides unified prerequisite checking for Spec-Driven Development workflow.
# It replaces the functionality previously spread across multiple scripts.
#
# Usage: ./check-prerequisites.ps1 [OPTIONS]
#
# OPTIONS:
#   -Json               Output in JSON format
#   -RequireTasks       Require tasks.md to exist (for implementation phase)
#   -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
#   -PathsOnly          Only output path variables (no validation)
#   -Help, -h           Show help message

$ErrorActionPreference = 'Stop'

$flags = @{
    'Json' = $false
    'RequireTasks' = $false
    'IncludeTasks' = $false
    'PathsOnly' = $false
    'Help' = $false
}

foreach ($arg in $args) {
    $raw = ''
    if ($null -ne $arg) { $raw = $arg.ToString() }
    $normalized = $raw.ToLowerInvariant()
    switch ($normalized) {
        '-json'          { $flags['Json'] = $true; continue }
        '-requiretasks'  { $flags['RequireTasks'] = $true; continue }
        '-includetasks'  { $flags['IncludeTasks'] = $true; continue }
        '-pathsonly'     { $flags['PathsOnly'] = $true; continue }
        '-help'          { $flags['Help'] = $true; continue }
        '-h'             { $flags['Help'] = $true; continue }
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

function New-JsonObject {
    param([hashtable]$Map)
    $parts = @()
    foreach ($key in $Map.Keys) {
        $value = $Map[$key]
        if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
            $elements = @()
            foreach ($item in $value) {
                $elements += '"{0}"' -f (Escape-JsonValue $item)
            }
            $parts += '"{0}":[{1}]' -f $key, ($elements -join ',')
        } else {
            $parts += '"{0}":"{1}"' -f $key, (Escape-JsonValue ($value -as [string]))
        }
    }
    return '{' + ($parts -join ',') + '}'
}

# Show help if requested
if ($flags['Help']) {
    Write-Output @"
Usage: check-prerequisites.ps1 [OPTIONS]

Consolidated prerequisite checking for Spec-Driven Development workflow.

OPTIONS:
  -Json               Output in JSON format
  -RequireTasks       Require tasks.md to exist (for implementation phase)
  -IncludeTasks       Include tasks.md in AVAILABLE_DOCS list
  -PathsOnly          Only output path variables (no prerequisite validation)
  -Help, -h           Show this help message

EXAMPLES:
  # Check task prerequisites (plan.md required)
  .\check-prerequisites.ps1 -Json

  # Check implementation prerequisites (plan.md + tasks.md required)
  .\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks

  # Get feature paths only (no validation)
  .\check-prerequisites.ps1 -PathsOnly

"@
    exit 0
}

# Source common functions
. "$PSScriptRoot/common.ps1"

# Get feature paths and validate branch
$paths = Get-FeaturePathsEnv

function Get-PathValue {
    param([string]$Key)
    return $paths[$Key]
}

if (-not (Test-FeatureBranch -Branch (Get-PathValue 'CURRENT_BRANCH') -HasGit (Get-PathValue 'HAS_GIT'))) {
    exit 1
}

# If paths-only mode, output paths and exit (support combined -Json -PathsOnly)
if ($flags['PathsOnly']) {
    if ($flags['Json']) {
        $map = @{
            'REPO_ROOT'    = (Get-PathValue 'REPO_ROOT')
            'BRANCH'       = (Get-PathValue 'CURRENT_BRANCH')
            'FEATURE_DIR'  = (Get-PathValue 'FEATURE_DIR')
            'FEATURE_SPEC' = (Get-PathValue 'FEATURE_SPEC')
            'IMPL_PLAN'    = (Get-PathValue 'IMPL_PLAN')
            'TASKS'        = (Get-PathValue 'TASKS')
        }
        Write-Output (New-JsonObject -Map $map)
    } else {
        Write-Output "REPO_ROOT: $(Get-PathValue 'REPO_ROOT')"
        Write-Output "BRANCH: $(Get-PathValue 'CURRENT_BRANCH')"
        Write-Output "FEATURE_DIR: $(Get-PathValue 'FEATURE_DIR')"
        Write-Output "FEATURE_SPEC: $(Get-PathValue 'FEATURE_SPEC')"
        Write-Output "IMPL_PLAN: $(Get-PathValue 'IMPL_PLAN')"
        Write-Output "TASKS: $(Get-PathValue 'TASKS')"
    }
    exit 0
}

# Validate required directories and files
if (-not (Test-Path (Get-PathValue 'FEATURE_DIR') -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $(Get-PathValue 'FEATURE_DIR')"
    Write-Output "Run /speckit.specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path (Get-PathValue 'IMPL_PLAN') -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found in $(Get-PathValue 'FEATURE_DIR')"
    Write-Output "Run /speckit.plan first to create the implementation plan."
    exit 1
}

# Check for tasks.md if required
if ($flags['RequireTasks'] -and -not (Test-Path (Get-PathValue 'TASKS') -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $(Get-PathValue 'FEATURE_DIR')"
    Write-Output "Run /speckit.tasks first to create the task list."
    exit 1
}

# Build list of available documents
$docs = @()

# Always check these optional docs
if (Test-Path (Get-PathValue 'RESEARCH')) { $docs += 'research.md' }
if (Test-Path (Get-PathValue 'DATA_MODEL')) { $docs += 'data-model.md' }

# Check contracts directory (only if it exists and has files)
if ((Test-Path (Get-PathValue 'CONTRACTS_DIR')) -and (Get-ChildItem -Path (Get-PathValue 'CONTRACTS_DIR') -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $docs += 'contracts/'
}

if (Test-Path (Get-PathValue 'QUICKSTART')) { $docs += 'quickstart.md' }

# Include tasks.md if requested and it exists
if ($flags['IncludeTasks'] -and (Test-Path (Get-PathValue 'TASKS'))) {
    $docs += 'tasks.md'
}

# Output results
if ($flags['Json']) {
    $payload = @{
        'FEATURE_DIR' = (Get-PathValue 'FEATURE_DIR')
        'AVAILABLE_DOCS' = $docs
    }
    Write-Output (New-JsonObject -Map $payload)
} else {
    # Text output
    Write-Output "FEATURE_DIR:$(Get-PathValue 'FEATURE_DIR')"
    Write-Output "AVAILABLE_DOCS:"

    # Show status of each potential document
    Test-FileExists -Path (Get-PathValue 'RESEARCH') -Description 'research.md' | Out-Null
    Test-FileExists -Path (Get-PathValue 'DATA_MODEL') -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path (Get-PathValue 'CONTRACTS_DIR') -Description 'contracts/' | Out-Null
    Test-FileExists -Path (Get-PathValue 'QUICKSTART') -Description 'quickstart.md' | Out-Null

    if ($flags['IncludeTasks']) {
        Test-FileExists -Path (Get-PathValue 'TASKS') -Description 'tasks.md' | Out-Null
    }
}