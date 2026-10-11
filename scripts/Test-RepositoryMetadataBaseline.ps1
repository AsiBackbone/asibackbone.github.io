[CmdletBinding()]
param(
    [string]$Organization = 'AsiBackbone',
    [string[]]$Repositories = @('.github', 'asibackbone.github.io', 'AsiBackbone', 'Learning', 'NetCoreApplicationTemplate'),
    [switch]$SelfTest,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-Result {
    param(
        [string]$Repository,
        [bool]$HasWiki
    )

    [pscustomobject]@{
        Repository = $Repository
        Control = 'wiki'
        Expected = 'disabled'
        Actual = $(if ($HasWiki) { 'enabled' } else { 'disabled' })
        Status = $(if ($HasWiki) { 'Fail' } else { 'Pass' })
    }
}

function Test-RepositoryMetadataBaseline {
    param([hashtable]$RepositoryStates)

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($repository in @($RepositoryStates.Keys | Sort-Object)) {
        $results.Add((New-Result -Repository $repository -HasWiki ([bool]$RepositoryStates[$repository].has_wiki)))
    }

    return $results
}

function Invoke-SelfTest {
    $failures = [System.Collections.Generic.List[string]]::new()
    $compliantStates = @{
        '.github' = [pscustomobject]@{ has_wiki = $false }
        'asibackbone.github.io' = [pscustomobject]@{ has_wiki = $false }
        'AsiBackbone' = [pscustomobject]@{ has_wiki = $false }
        'Learning' = [pscustomobject]@{ has_wiki = $false }
        'NetCoreApplicationTemplate' = [pscustomobject]@{ has_wiki = $false }
    }

    $compliant = @(Test-RepositoryMetadataBaseline $compliantStates)
    if ($compliant.Count -ne 5 -or @($compliant | Where-Object Status -ne 'Pass').Count -ne 0) {
        $failures.Add('A compliant five-repository baseline did not pass every check.')
    }

    $compliantStates['Learning'] = [pscustomobject]@{ has_wiki = $true }
    $drift = @(Test-RepositoryMetadataBaseline $compliantStates)
    $failed = @($drift | Where-Object Status -eq 'Fail')
    if ($failed.Count -ne 1 -or $failed[0].Repository -ne 'Learning') {
        $failures.Add('An enabled wiki was not reported as repository metadata drift.')
    }

    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Error $_ }
        return 1
    }

    Write-Host 'Repository metadata baseline self-test passed.'
    return 0
}

if ($SelfTest) {
    exit (Invoke-SelfTest)
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install it and authenticate before running the live review.'
}

$repositoryStates = @{}
foreach ($repository in $Repositories) {
    $output = & gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' "repos/$Organization/$repository"
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub API request failed: repos/$Organization/$repository"
    }

    $repositoryStates[$repository] = $output | ConvertFrom-Json
}

$results = @(Test-RepositoryMetadataBaseline $repositoryStates)
if ($Json) {
    $results | ConvertTo-Json -Depth 3
}
else {
    $results | Format-Table -AutoSize
}

if (@($results | Where-Object Status -eq 'Fail').Count -gt 0) {
    exit 1
}
