#!/usr/bin/env pwsh
$CmdletBinding = $null
# Deprecated: avoid [switch] param to keep compatibility with constrained language-mode callers.
# Detect a -Json flag passed on the command line (seen in $args when invoked via -File).
$Json = $false
if ($args -and ($args -contains '-Json' -or $args -contains '-json' -or $args -contains '/Json')) { $Json = $true }
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv
if (-not (Test-FeatureBranch -Branch $paths['CURRENT_BRANCH'])) { exit 1 }

if (-not (Test-Path $paths['FEATURE_DIR'] -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths['FEATURE_DIR'])"
    Write-Output "Run /specify first to create the feature structure."
    exit 1
}
if (-not (Test-Path $paths['IMPL_PLAN'] -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found in $($paths['FEATURE_DIR'])"
    Write-Output "Run /plan first to create the plan."
    exit 1
}
if (-not (Test-Path $paths['TASKS'] -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $($paths['FEATURE_DIR'])"
    Write-Output "Run /tasks first to create the task list."
    exit 1
}

if ($Json) {
    # Build a plain JSON string using only core types so the script works in constrained language mode.
    $docsList = @()
    if (Test-Path $paths['RESEARCH']) { $docsList += 'research.md' }
    if (Test-Path $paths['DATA_MODEL']) { $docsList += 'data-model.md' }
    if (Test-Path $paths['CONTRACTS_DIR']) {
        $names = Get-ChildItem -Path $paths['CONTRACTS_DIR'] -File -Name -ErrorAction SilentlyContinue
        if ($names -and $names.Count -gt 0) { $docsList += 'contracts/' }
    }
    if (Test-Path $paths['QUICKSTART']) { $docsList += 'quickstart.md' }
    if (Test-Path $paths['TASKS']) { $docsList += 'tasks.md' }

    # Escape double-quotes in path
    $escFeatureDir = $paths['FEATURE_DIR'] -replace '"', '\\"'

    # Build JSON array for AVAILABLE_DOCS
    $escapedDocs = $docsList | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }
    $docsJson = '[' + ($escapedDocs -join ',') + ']'

    $json = '{"FEATURE_DIR":"' + $escFeatureDir + '","AVAILABLE_DOCS":' + $docsJson + '}'
    Write-Output $json
} else {
    Write-Output "FEATURE_DIR:$($paths['FEATURE_DIR'])"
    Write-Output "AVAILABLE_DOCS:"
    Test-FileExists -Path $paths['RESEARCH'] -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths['DATA_MODEL'] -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths['CONTRACTS_DIR'] -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths['QUICKSTART'] -Description 'quickstart.md' | Out-Null
    Test-FileExists -Path $paths['TASKS'] -Description 'tasks.md' | Out-Null
}