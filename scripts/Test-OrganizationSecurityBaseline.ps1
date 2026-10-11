[CmdletBinding()]
param(
    [string]$Organization = 'AsiBackbone',
    [string[]]$Repositories = @('.github', 'asibackbone.github.io'),
    [switch]$SelfTest,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$twoFactorReviewBy = [DateTimeOffset]'2026-10-18T23:59:59-05:00'

function New-Result {
    param(
        [string]$Control,
        [string]$Expected,
        [string]$Actual,
        [ValidateSet('Pass', 'Warning', 'Fail')]
        [string]$Status
    )

    [pscustomobject]@{
        Control = $Control
        Expected = $Expected
        Actual = $Actual
        Status = $Status
    }
}

function Test-OrganizationBaseline {
    param(
        [pscustomobject]$OrganizationState,
        [hashtable]$RepositoryStates,
        [DateTimeOffset]$Now = [DateTimeOffset]::Now
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $organizationControls = [ordered]@{
        dependency_graph_enabled_for_new_repositories = 'Dependency graph default'
        dependabot_alerts_enabled_for_new_repositories = 'Dependabot alerts default'
        dependabot_security_updates_enabled_for_new_repositories = 'Dependabot security updates default'
        secret_scanning_enabled_for_new_repositories = 'Secret scanning default'
        secret_scanning_push_protection_enabled_for_new_repositories = 'Push protection default'
    }

    foreach ($entry in $organizationControls.GetEnumerator()) {
        $actual = [bool]$OrganizationState.($entry.Key)
        $results.Add((New-Result "Organization: $($entry.Value)" 'enabled' $(if ($actual) { 'enabled' } else { 'disabled' }) $(if ($actual) { 'Pass' } else { 'Fail' })))
    }

    $requiresTwoFactor = [bool]$OrganizationState.two_factor_requirement_enabled
    $membersWithoutTwoFactor = [int]$OrganizationState.members_without_two_factor

    if ($requiresTwoFactor) {
        $results.Add((New-Result 'Organization: require 2FA' 'enabled' 'enabled' 'Pass'))
    }
    elseif ($membersWithoutTwoFactor -eq 0 -and $Now -le $twoFactorReviewBy) {
        $results.Add((New-Result 'Organization: require 2FA' 'enabled after recovery-readiness confirmation' "deferred; no member is reported without 2FA; review by $($twoFactorReviewBy.ToString('yyyy-MM-dd'))" 'Warning'))
    }
    else {
        $results.Add((New-Result 'Organization: require 2FA' 'enabled after recovery-readiness confirmation' "disabled; $membersWithoutTwoFactor member(s) reported without 2FA; review deadline $($twoFactorReviewBy.ToString('yyyy-MM-dd'))" 'Fail'))
    }

    foreach ($repository in @($RepositoryStates.Keys | Sort-Object)) {
        $state = $RepositoryStates[$repository]
        $repositoryControls = [ordered]@{
            dependency_graph = [bool]$state.dependency_alerts_enabled
            dependabot_alerts = [bool]$state.dependency_alerts_enabled
            dependabot_security_updates = [bool]$state.dependabot_security_updates_enabled
            secret_scanning = $state.secret_scanning -eq 'enabled'
            secret_scanning_push_protection = $state.secret_scanning_push_protection -eq 'enabled'
        }

        foreach ($entry in $repositoryControls.GetEnumerator()) {
            $results.Add((New-Result "Repository $repository`: $($entry.Key)" 'enabled' $(if ($entry.Value) { 'enabled' } else { 'disabled' }) $(if ($entry.Value) { 'Pass' } else { 'Fail' })))
        }
    }

    return $results
}

function Invoke-GitHubJson {
    param([string]$Endpoint)

    $output = & gh api -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2026-03-10' $Endpoint
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub API request failed: $Endpoint"
    }

    return $output | ConvertFrom-Json
}

function Test-GitHubEndpoint {
    param([string]$Endpoint)

    & gh api --silent -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2026-03-10' $Endpoint 2>$null
    return $LASTEXITCODE -eq 0
}

function Invoke-SelfTest {
    $failures = [System.Collections.Generic.List[string]]::new()
    $organizationState = [pscustomobject]@{
        dependency_graph_enabled_for_new_repositories = $true
        dependabot_alerts_enabled_for_new_repositories = $true
        dependabot_security_updates_enabled_for_new_repositories = $true
        secret_scanning_enabled_for_new_repositories = $true
        secret_scanning_push_protection_enabled_for_new_repositories = $true
        two_factor_requirement_enabled = $true
        members_without_two_factor = 0
    }
    $repositoryState = [pscustomobject]@{
        dependency_alerts_enabled = $true
        dependabot_security_updates_enabled = $true
        secret_scanning = 'enabled'
        secret_scanning_push_protection = 'enabled'
    }
    $repositories = @{
        '.github' = $repositoryState
        'asibackbone.github.io' = $repositoryState
    }

    $compliant = @(Test-OrganizationBaseline $organizationState $repositories ([DateTimeOffset]'2026-10-11T12:00:00-05:00'))
    if (@($compliant | Where-Object Status -ne 'Pass').Count -ne 0) {
        $unexpected = $compliant | Where-Object Status -ne 'Pass' | ConvertTo-Json -Compress
        $failures.Add("A compliant baseline did not pass every check: $unexpected")
    }

    $organizationState.secret_scanning_enabled_for_new_repositories = $false
    $repositories['.github'] = [pscustomobject]@{
        dependency_alerts_enabled = $true
        dependabot_security_updates_enabled = $true
        secret_scanning = 'enabled'
        secret_scanning_push_protection = 'disabled'
    }
    $drift = @(Test-OrganizationBaseline $organizationState $repositories ([DateTimeOffset]'2026-10-11T12:00:00-05:00'))
    if (@($drift | Where-Object Status -eq 'Fail').Count -ne 2) {
        $failures.Add('Organization and repository drift were not both detected.')
    }

    $organizationState.secret_scanning_enabled_for_new_repositories = $true
    $organizationState.two_factor_requirement_enabled = $false
    $repositories['.github'] = $repositoryState
    $deferred = @(Test-OrganizationBaseline $organizationState $repositories ([DateTimeOffset]'2026-10-11T12:00:00-05:00'))
    if (@($deferred | Where-Object Status -eq 'Warning').Count -ne 1 -or @($deferred | Where-Object Status -eq 'Fail').Count -ne 0) {
        $failures.Add('The dated 2FA recovery-readiness deferral was not reported as a warning.')
    }

    $expired = @(Test-OrganizationBaseline $organizationState $repositories ([DateTimeOffset]'2026-10-19T00:00:00-05:00'))
    if (@($expired | Where-Object Status -eq 'Fail').Count -ne 1) {
        $failures.Add('An expired 2FA recovery-readiness deferral was not reported as a failure.')
    }

    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Error $_ }
        return 1
    }

    Write-Host 'Organization security baseline self-test passed.'
    return 0
}

if ($SelfTest) {
    exit (Invoke-SelfTest)
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install it and authenticate as an organization owner or security manager.'
}

$organizationState = Invoke-GitHubJson "orgs/$Organization"
$membersWithoutTwoFactor = @(Invoke-GitHubJson "orgs/$Organization/members?filter=2fa_disabled&per_page=100").Count
$organizationState | Add-Member -NotePropertyName members_without_two_factor -NotePropertyValue $membersWithoutTwoFactor

$repositoryStates = @{}
foreach ($repository in $Repositories) {
    $details = Invoke-GitHubJson "repos/$Organization/$repository"
    $securityUpdates = Invoke-GitHubJson "repos/$Organization/$repository/automated-security-fixes"
    $repositoryStates[$repository] = [pscustomobject]@{
        dependency_alerts_enabled = Test-GitHubEndpoint "repos/$Organization/$repository/vulnerability-alerts"
        dependabot_security_updates_enabled = [bool]$securityUpdates.enabled
        secret_scanning = $details.security_and_analysis.secret_scanning.status
        secret_scanning_push_protection = $details.security_and_analysis.secret_scanning_push_protection.status
    }
}

$results = @(Test-OrganizationBaseline $organizationState $repositoryStates)
if ($Json) {
    $results | ConvertTo-Json -Depth 4
}
else {
    $results | Format-Table -AutoSize
}

if (@($results | Where-Object Status -eq 'Fail').Count -gt 0) {
    exit 1
}

if (@($results | Where-Object Status -eq 'Warning').Count -gt 0) {
    Write-Warning 'The baseline has a documented temporary exception. Resolve it by the recorded review date.'
}
