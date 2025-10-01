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

# Deprecated: avoid typed [switch] params to keep compatibility with constrained language-mode and -File invocation.
$Json = $false; $RequireTasks = $false; $IncludeTasks = $false; $PathsOnly = $false; $Help = $false
if ($args) {
    if ($args -contains '-Json' -or $args -contains '-json' -or $args -contains '/Json') { $Json = $true }
    if ($args -contains '-RequireTasks' -or $args -contains '/RequireTasks') { $RequireTasks = $true }
    if ($args -contains '-IncludeTasks' -or $args -contains '/IncludeTasks') { $IncludeTasks = $true }
    if ($args -contains '-PathsOnly' -or $args -contains '/PathsOnly') { $PathsOnly = $true }
    if ($args -contains '-Help' -or $args -contains '-h' -or $args -contains '/?') { $Help = $true }
}

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
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

if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit:$paths.HAS_GIT)) {
    exit 1
}

# If paths-only mode, output paths and exit (support combined -Json -PathsOnly)
if ($PathsOnly) {
    if ($Json) {
        # Build a minimal JSON string using primitive types to be compatible with constrained language
        $escRepoRoot = ($paths.REPO_ROOT -replace '"','\\"')
        $escBranch = ($paths.CURRENT_BRANCH -replace '"','\\"')
        $escFeatureDir = ($paths.FEATURE_DIR -replace '"','\\"')
        $escFeatureSpec = ($paths.FEATURE_SPEC -replace '"','\\"')
        $escImplPlan = ($paths.IMPL_PLAN -replace '"','\\"')
        $escTasks = ($paths.TASKS -replace '"','\\"')
        $json = '{"REPO_ROOT":"' + $escRepoRoot + '","BRANCH":"' + $escBranch + '","FEATURE_DIR":"' + $escFeatureDir + '","FEATURE_SPEC":"' + $escFeatureSpec + '","IMPL_PLAN":"' + $escImplPlan + '","TASKS":"' + $escTasks + '"}'
        Write-Output $json
    } else {
        Write-Output "REPO_ROOT: $($paths.REPO_ROOT)"
        Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
        Write-Output "FEATURE_DIR: $($paths.FEATURE_DIR)"
        Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
        Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
        Write-Output "TASKS: $($paths.TASKS)"
    }
    exit 0
}

# Validate required directories and files
if (-not (Test-Path $paths.FEATURE_DIR -PathType Container)) {
    Write-Output "ERROR: Feature directory not found: $($paths.FEATURE_DIR)"
    Write-Output "Run /specify first to create the feature structure."
    exit 1
}

if (-not (Test-Path $paths.IMPL_PLAN -PathType Leaf)) {
    Write-Output "ERROR: plan.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /plan first to create the implementation plan."
    exit 1
}

# Check for tasks.md if required
if ($RequireTasks -and -not (Test-Path $paths.TASKS -PathType Leaf)) {
    Write-Output "ERROR: tasks.md not found in $($paths.FEATURE_DIR)"
    Write-Output "Run /tasks first to create the task list."
    exit 1
}

# Build list of available documents
$docs = @()

# Always check these optional docs
if (Test-Path $paths.RESEARCH) { $docs += 'research.md' }
if (Test-Path $paths.DATA_MODEL) { $docs += 'data-model.md' }

# Check contracts directory (only if it exists and has files)
if ((Test-Path $paths.CONTRACTS_DIR) -and (Get-ChildItem -Path $paths.CONTRACTS_DIR -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    $docs += 'contracts/'
}

if (Test-Path $paths.QUICKSTART) { $docs += 'quickstart.md' }

# Include tasks.md if requested and it exists
if ($IncludeTasks -and (Test-Path $paths.TASKS)) {
    $docs += 'tasks.md'
}

# Output results
if ($Json) {
    # Build a simple JSON output listing the feature dir and available docs
    $escFeatureDir = ($paths.FEATURE_DIR -replace '"','\\"')
    $escapedDocs = $docs | ForEach-Object { '"' + ($_ -replace '"','\\"') + '"' }
    $docsJson = '[' + ($escapedDocs -join ',') + ']'
    $json = '{"FEATURE_DIR":"' + $escFeatureDir + '","AVAILABLE_DOCS":' + $docsJson + '}'
    Write-Output $json
} else {
    # Text output
    Write-Output "FEATURE_DIR:$($paths.FEATURE_DIR)"
    Write-Output "AVAILABLE_DOCS:"

    # Show status of each potential document
    Test-FileExists -Path $paths.RESEARCH -Description 'research.md' | Out-Null
    Test-FileExists -Path $paths.DATA_MODEL -Description 'data-model.md' | Out-Null
    Test-DirHasFiles -Path $paths.CONTRACTS_DIR -Description 'contracts/' | Out-Null
    Test-FileExists -Path $paths.QUICKSTART -Description 'quickstart.md' | Out-Null

    if ($IncludeTasks) {
        Test-FileExists -Path $paths.TASKS -Description 'tasks.md' | Out-Null
    }
}