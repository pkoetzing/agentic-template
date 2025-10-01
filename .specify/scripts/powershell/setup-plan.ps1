#!/usr/bin/env pwsh
# Setup implementation plan for a feature

# Avoid typed [switch] params for compatibility with -File invocation and constrained environments
$Json = $false; $Help = $false
if ($args) {
    if ($args -contains '-Json' -or $args -contains '-json' -or $args -contains '/Json') { $Json = $true }
    if ($args -contains '-Help' -or $args -contains '-h' -or $args -contains '/?') { $Help = $true }
}

$ErrorActionPreference = 'Stop'

# Show help if requested
if ($Help) {
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
if (-not (Test-FeatureBranch -Branch $paths.CURRENT_BRANCH -HasGit $paths.HAS_GIT)) {
    exit 1
}

# Ensure the feature directory exists
New-Item -ItemType Directory -Path $paths.FEATURE_DIR -Force | Out-Null

# Copy plan template if it exists, otherwise note it or create empty file
$template = Join-Path $paths.REPO_ROOT '.specify/templates/plan-template.md'
if (Test-Path $template) {
    Copy-Item $template $paths.IMPL_PLAN -Force
    Write-Output "Copied plan template to $($paths.IMPL_PLAN)"
} else {
    Write-Warning "Plan template not found at $template"
    # Create a basic plan file if template doesn't exist
    New-Item -ItemType File -Path $paths.IMPL_PLAN -Force | Out-Null
}

# Output results
if ($Json) {
    # Construct a lightweight JSON string to avoid ConvertTo-Json in constrained environments
    $escFeatureSpec = ($paths.FEATURE_SPEC -replace '"','\\"')
    $escImplPlan = ($paths.IMPL_PLAN -replace '"','\\"')
    $escSpecsDir = ($paths.FEATURE_DIR -replace '"','\\"')
    $escBranch = ($paths.CURRENT_BRANCH -replace '"','\\"')
    $hasGitStr = ($paths.HAS_GIT -eq $true).ToString().ToLower()
    $json = '{"FEATURE_SPEC":"' + $escFeatureSpec + '","IMPL_PLAN":"' + $escImplPlan + '","SPECS_DIR":"' + $escSpecsDir + '","BRANCH":"' + $escBranch + '","HAS_GIT":' + $hasGitStr + '}'
    Write-Output $json
} else {
    Write-Output "FEATURE_SPEC: $($paths.FEATURE_SPEC)"
    Write-Output "IMPL_PLAN: $($paths.IMPL_PLAN)"
    Write-Output "SPECS_DIR: $($paths.FEATURE_DIR)"
    Write-Output "BRANCH: $($paths.CURRENT_BRANCH)"
    Write-Output "HAS_GIT: $($paths.HAS_GIT)"
}
