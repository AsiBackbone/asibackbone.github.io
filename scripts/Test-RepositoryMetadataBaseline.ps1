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
        [string]$Control,
        [string]$Expected,
        [string]$Actual
    )

    [pscustomobject]@{
        Repository = $Repository
        Control = $Control
        Expected = $Expected
        Actual = $Actual
        Status = $(if ($Expected -eq $Actual) { 'Pass' } else { 'Fail' })
    }
}

function Test-RepositoryMetadataBaseline {
    param([hashtable]$RepositoryStates)

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($repository in @($RepositoryStates.Keys | Sort-Object)) {
        $wikiState = if ([bool]$RepositoryStates[$repository].has_wiki) { 'enabled' } else { 'disabled' }
        $discussionState = if ([bool]$RepositoryStates[$repository].has_discussions) { 'enabled' } else { 'disabled' }
        $expectedDiscussionState = if ($repository -eq '.github') { 'enabled' } else { 'disabled' }

        $results.Add((New-Result -Repository $repository -Control 'wiki' -Expected 'disabled' -Actual $wikiState))
        $results.Add((New-Result -Repository $repository -Control 'discussions' -Expected $expectedDiscussionState -Actual $discussionState))
    }

    return $results
}

function Invoke-SelfTest {
    $failures = [System.Collections.Generic.List[string]]::new()
    $compliantStates = @{
        '.github' = [pscustomobject]@{ has_wiki = $false; has_discussions = $true }
        'asibackbone.github.io' = [pscustomobject]@{ has_wiki = $false; has_discussions = $false }
        'AsiBackbone' = [pscustomobject]@{ has_wiki = $false; has_discussions = $false }
        'Learning' = [pscustomobject]@{ has_wiki = $false; has_discussions = $false }
        'NetCoreApplicationTemplate' = [pscustomobject]@{ has_wiki = $false; has_discussions = $false }
    }

    $compliant = @(Test-RepositoryMetadataBaseline $compliantStates)
    if ($compliant.Count -ne 10 -or @($compliant | Where-Object Status -ne 'Pass').Count -ne 0) {
        $failures.Add('A compliant five-repository baseline did not pass all ten checks.')
    }

    $compliantStates['Learning'].has_wiki = $true
    $drift = @(Test-RepositoryMetadataBaseline $compliantStates)
    $failed = @($drift | Where-Object Status -eq 'Fail')
    if ($failed.Count -ne 1 -or $failed[0].Repository -ne 'Learning' -or $failed[0].Control -ne 'wiki') {
        $failures.Add('An enabled wiki was not reported as repository metadata drift.')
    }

    $compliantStates['Learning'].has_wiki = $false
    $compliantStates['Learning'].has_discussions = $true
    $drift = @(Test-RepositoryMetadataBaseline $compliantStates)
    $failed = @($drift | Where-Object Status -eq 'Fail')
    if ($failed.Count -ne 1 -or $failed[0].Repository -ne 'Learning' -or $failed[0].Control -ne 'discussions') {
        $failures.Add('Repository-specific Discussions were not reported as repository metadata drift.')
    }

    $compliantStates['Learning'].has_discussions = $false
    $compliantStates['.github'].has_discussions = $false
    $drift = @(Test-RepositoryMetadataBaseline $compliantStates)
    $failed = @($drift | Where-Object Status -eq 'Fail')
    if ($failed.Count -ne 1 -or $failed[0].Repository -ne '.github' -or $failed[0].Control -ne 'discussions') {
        $failures.Add('A disabled organization Discussions source was not reported as repository metadata drift.')
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
