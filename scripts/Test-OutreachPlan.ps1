[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$failures = [System.Collections.Generic.List[string]]::new()
$planPath = Join-Path $RepositoryRoot 'OUTREACH-PLAN.md'
$readmePath = Join-Path $RepositoryRoot 'README.md'

if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
    throw 'Required file is missing: OUTREACH-PLAN.md'
}

$plan = Get-Content -LiteralPath $planPath -Raw
$readme = Get-Content -LiteralPath $readmePath -Raw

foreach ($heading in @(
    '## Audiences and problem-first entry points',
    '## Canonical content map',
    '## Initial 90-day calendar',
    '## Candidate communities and CFP sources',
    '## Reusable publication checklist',
    '## Permission, attribution, and privacy guardrails',
    '## Ownership and review cadence',
    '## Measurement and limits'
)) {
    if (-not $plan.Contains($heading, [StringComparison]::Ordinal)) {
        $failures.Add("OUTREACH-PLAN.md is missing required section: $heading")
    }
}

foreach ($requiredText in @(
    'Scheduled items below are **planned**, not already published',
    'stars, forks, maintainers, adopters, or conference acceptance',
    'Recheck every link and the channel rules on publication day.',
    'without explicit permission',
    'Do not commit raw analytics exports'
)) {
    if (-not $plan.Contains($requiredText, [StringComparison]::OrdinalIgnoreCase)) {
        $failures.Add("OUTREACH-PLAN.md is missing required guardrail: $requiredText")
    }
}

if (-not $readme.Contains('[OUTREACH-PLAN.md](OUTREACH-PLAN.md)', [StringComparison]::Ordinal)) {
    $failures.Add('README.md must link to OUTREACH-PLAN.md.')
}

$calendarRows = [regex]::Matches($plan, '(?m)^\| Days [^\r\n]+\|$').Count
if ($calendarRows -lt 3) {
    $failures.Add("The initial calendar must contain at least three concrete deliverables; found $calendarRows.")
}

$communityRows = [regex]::Matches($plan, '(?m)^\| (?:\.NET Foundation|\.NET Conf|ASP\.NET Core|OWASP|iSAQB|AI Alliance)[^\r\n]+\|$').Count
if ($communityRows -lt 5) {
    $failures.Add("The candidate community list must cover at least five suitable channels; found $communityRows.")
}

foreach ($match in [regex]::Matches($plan + "`n" + $readme, '\[[^\]]+\]\((?<target>[^)]+)\)')) {
    $target = $match.Groups['target'].Value
    if ($target -match '^https://') {
        continue
    }

    if ($target -match '^[a-z][a-z0-9+.-]*:') {
        $failures.Add("Documentation link must use HTTPS or a repository-relative path: $target")
        continue
    }

    $relativeTarget = ($target -split '#', 2)[0]
    if ([string]::IsNullOrWhiteSpace($relativeTarget)) {
        continue
    }

    $localPath = Join-Path $RepositoryRoot $relativeTarget.Replace('/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $localPath)) {
        $failures.Add("Documentation references a missing local path: $target")
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host 'Outreach plan structure, guardrails, and repository-relative links passed.'
