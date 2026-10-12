[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Get-RequiredFile {
    param([string]$RelativePath)

    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Required file is missing: $RelativePath"
        return $null
    }

    return $path
}

$indexPath = Get-RequiredFile 'index.html'
$robotsPath = Get-RequiredFile 'robots.txt'
$sitemapPath = Get-RequiredFile 'sitemap.xml'
$licensePath = Get-RequiredFile 'LICENSE'
$codeLicensePath = Get-RequiredFile 'LICENSE-CODE'
$licenseScopePath = Get-RequiredFile 'LICENSES.md'
$assetLicensePath = Get-RequiredFile 'ASSETS-LICENSES.md'
$securityBaselinePath = Get-RequiredFile 'SECURITY-BASELINE.md'
$editorConfigPath = Get-RequiredFile '.editorconfig'
$gitAttributesPath = Get-RequiredFile '.gitattributes'
$gitIgnorePath = Get-RequiredFile '.gitignore'
$dependabotPath = Get-RequiredFile '.github/dependabot.yml'
$dependencyReviewPath = Get-RequiredFile '.github/workflows/dependency-review.yml'
$codeqlPath = Get-RequiredFile '.github/workflows/codeql.yml'
$workflowSecurityPath = Get-RequiredFile '.github/workflows/workflow-security.yml'
$scorecardPath = Get-RequiredFile '.github/workflows/openssf-scorecard.yml'

if ($indexPath) {
    $html = Get-Content -LiteralPath $indexPath -Raw
    $requiredHtml = [ordered]@{
        '<!DOCTYPE html>' = 'HTML5 doctype'
        '<html lang="en">' = 'English document language'
        '<link rel="canonical" href="https://asibackbone.github.io/">' = 'canonical URL'
        '<meta property="og:url" content="https://asibackbone.github.io/">' = 'Open Graph URL'
        '</html>' = 'closing html element'
    }

    foreach ($entry in $requiredHtml.GetEnumerator()) {
        if (-not $html.Contains($entry.Key, [StringComparison]::OrdinalIgnoreCase)) {
            Add-Failure "index.html is missing its $($entry.Value)."
        }
    }

    $requiredCommunityRoutes = [ordered]@{
        'https://asibackbone.github.io/Learning/' = 'Learning entry route'
        'https://github.com/orgs/AsiBackbone/discussions/categories/q-a' = 'organization Q&A route'
        'https://github.com/orgs/AsiBackbone/discussions/categories/ideas' = 'organization Ideas route'
        'https://github.com/orgs/AsiBackbone/discussions/categories/architecture-integration' = 'organization architecture route'
        'https://github.com/AsiBackbone/Learning/blob/main/CONTRIBUTING.md' = 'Learning contribution route'
        'https://github.com/AsiBackbone/AsiBackbone/blob/main/CONTRIBUTING.md' = 'AsiBackbone contribution route'
        'https://github.com/AsiBackbone/NetCoreApplicationTemplate/blob/main/CONTRIBUTING.md' = 'template contribution route'
        'https://github.com/AsiBackbone/Learning/security/policy' = 'Learning security route'
        'https://github.com/AsiBackbone/AsiBackbone/security/policy' = 'AsiBackbone security route'
        'https://github.com/AsiBackbone/NetCoreApplicationTemplate/security/policy' = 'template security route'
    }

    foreach ($entry in $requiredCommunityRoutes.GetEnumerator()) {
        if (-not $html.Contains('href="' + $entry.Key + '"', [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing its $($entry.Value)."
        }
    }

    if (-not $html.Contains('a:focus-visible', [StringComparison]::Ordinal)) {
        Add-Failure 'index.html must retain a visible keyboard-focus treatment for links.'
    }

    if ($html -match '(?i)tabindex\s*=\s*["'']?[1-9]') {
        Add-Failure 'index.html must not define a positive tabindex.'
    }

    $jsonLdMatch = [regex]::Match(
        $html,
        '<script\s+type="application/ld\+json">(?<json>.*?)</script>',
        [Text.RegularExpressions.RegexOptions]::Singleline -bor [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $jsonLdMatch.Success) {
        Add-Failure 'index.html is missing its JSON-LD block.'
    }
    else {
        try {
            $jsonLd = $jsonLdMatch.Groups['json'].Value | ConvertFrom-Json
            if ($jsonLd.'@context' -ne 'https://schema.org' -or @($jsonLd.'@graph').Count -lt 2) {
                Add-Failure 'index.html JSON-LD does not contain the expected schema.org organization and website graph.'
            }
        }
        catch {
            Add-Failure "index.html contains invalid JSON-LD: $($_.Exception.Message)"
        }
    }

    foreach ($match in [regex]::Matches($html, '(?:href|src)="(?<path>(?!https?://|mailto:|#)[^"?#]+)"', [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $relativePath = $match.Groups['path'].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $relativePath) -PathType Leaf)) {
            Add-Failure "index.html references a missing local file: $($match.Groups['path'].Value)"
        }
    }
}

if ($robotsPath) {
    $robotsLines = @(Get-Content -LiteralPath $robotsPath | ForEach-Object Trim | Where-Object { $_ })
    foreach ($requiredLine in @('User-agent: *', 'Allow: /', 'Sitemap: https://asibackbone.github.io/sitemap.xml')) {
        if ($robotsLines -cnotcontains $requiredLine) {
            Add-Failure "robots.txt is missing '$requiredLine'."
        }
    }

    if (@($robotsLines | Where-Object { $_ -like 'Sitemap:*' }).Count -ne 1) {
        Add-Failure 'robots.txt must advertise exactly the domain-root sitemap index.'
    }
}

if ($sitemapPath) {
    try {
        [xml]$sitemap = Get-Content -LiteralPath $sitemapPath -Raw
        $namespaceManager = [Xml.XmlNamespaceManager]::new($sitemap.NameTable)
        $namespaceManager.AddNamespace('sm', 'http://www.sitemaps.org/schemas/sitemap/0.9')
        $actualLocations = @($sitemap.SelectNodes('/sm:sitemapindex/sm:sitemap/sm:loc', $namespaceManager) | ForEach-Object InnerText | Sort-Object)
        $expectedLocations = @(
            'https://asibackbone.github.io/AsiBackbone/sitemap.xml'
            'https://asibackbone.github.io/Learning/sitemap.xml'
            'https://asibackbone.github.io/NetCoreApplicationTemplate/sitemap.xml'
        ) | Sort-Object

        if (($actualLocations -join "`n") -cne ($expectedLocations -join "`n")) {
            Add-Failure "sitemap.xml must list exactly the three project sitemap URLs. Found: $($actualLocations -join ', ')"
        }
    }
    catch {
        Add-Failure "sitemap.xml is invalid XML: $($_.Exception.Message)"
    }
}

if ($licensePath -and -not (Get-Content -LiteralPath $licensePath -Raw).StartsWith('Attribution 4.0 International', [StringComparison]::Ordinal)) {
    Add-Failure 'LICENSE must contain the complete CC BY 4.0 text.'
}

if ($codeLicensePath -and -not (Get-Content -LiteralPath $codeLicensePath -Raw).StartsWith('MIT License', [StringComparison]::Ordinal)) {
    Add-Failure 'LICENSE-CODE must contain the complete MIT License text.'
}

if ($licenseScopePath) {
    $licenseScope = Get-Content -LiteralPath $licenseScopePath -Raw
    foreach ($requiredText in @('CC BY 4.0 content', 'MIT-licensed source', 'Brand and third-party boundaries', 'Contributions')) {
        if (-not $licenseScope.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "LICENSES.md is missing its '$requiredText' boundary."
        }
    }
}

if ($assetLicensePath) {
    $assetLicense = Get-Content -LiteralPath $assetLicensePath -Raw
    $expectedAssetHashes = [ordered]@{
        'images/asibackbone-icon-50.png' = 'A7D5AF4069DF86398EFACFCE3ADC8AE51BFC5BE81AB58EE3052219998EA0A01E'
        'images/asibackbone-social.png' = '8EB614CBCAE9B53577F434E0E458D11106581CBEC8FC82F944E17E75403B5C35'
        'images/favicon.ico' = '91A4AB87978D184009821BFDC6C6BEC0D6F00E364B420D630B64122F19D1F5D8'
    }

    foreach ($entry in $expectedAssetHashes.GetEnumerator()) {
        $assetPath = Get-RequiredFile $entry.Key
        if ($assetPath -and (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash -cne $entry.Value) {
            Add-Failure "$($entry.Key) does not match its recorded SHA-256."
        }

        if (-not $assetLicense.Contains($entry.Value, [StringComparison]::Ordinal)) {
            Add-Failure "ASSETS-LICENSES.md does not record the SHA-256 for $($entry.Key)."
        }
    }
}

if ($securityBaselinePath) {
    $securityBaseline = Get-Content -LiteralPath $securityBaselinePath -Raw
    foreach ($requiredText in @(
        '## OpenSSF Scorecard finding disposition'
        '### Triage policy'
        'Reserve `false positive` for a finding whose underlying observation is'
        'The `Maintained` check is a special age gate'
        'It is not a `false positive`, because Scorecard correctly observed the'
        '### 2026-10-12 triage record'
        '| `.github` | #4 | 2026-11-09 |'
        '| `Learning` | #5 | 2026-11-10 |'
        '| `asibackbone.github.io` | #5 | 2026-12-26 |'
        '### Repository-specific controls'
        'CodeQL analyzes GitHub Actions workflows on every pull request'
        'A CI-tests warning can temporarily reflect historical pull requests'
        'Fuzzing is not adopted because this static landing repository'
        'The branch-protection and code-review findings reflect the documented'
    )) {
        if (-not $securityBaseline.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "SECURITY-BASELINE.md is missing its '$requiredText' control disposition."
        }
    }
}

if ($editorConfigPath -and -not (Get-Content -LiteralPath $editorConfigPath -Raw).Contains('root = true', [StringComparison]::Ordinal)) {
    Add-Failure '.editorconfig must declare itself as the top-level configuration.'
}

if ($gitAttributesPath -and -not (Get-Content -LiteralPath $gitAttributesPath -Raw).Contains('*.png     binary', [StringComparison]::Ordinal)) {
    Add-Failure '.gitattributes must preserve image assets as binary files.'
}

if ($gitIgnorePath -and -not (Get-Content -LiteralPath $gitIgnorePath -Raw).Contains('.vs/', [StringComparison]::Ordinal)) {
    Add-Failure '.gitignore must exclude Visual Studio workspace state.'
}

if ($dependabotPath) {
    $dependabot = Get-Content -LiteralPath $dependabotPath -Raw
    foreach ($requiredText in @('package-ecosystem: "github-actions"', 'interval: "weekly"', 'day: "friday"', 'timezone: "America/Chicago"', 'github-actions:')) {
        if (-not $dependabot.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure ".github/dependabot.yml is missing its '$requiredText' contract."
        }
    }
}

$securityWorkflowContracts = [ordered]@{
    '.github/workflows/dependency-review.yml' = @('name: Dependency Review', 'actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294', 'fail-on-severity: moderate')
    '.github/workflows/codeql.yml' = @('name: CodeQL Analysis', 'pull_request:', 'push:', 'languages: actions', 'github/codeql-action/init@24c54180a607b1449ed407dd24f251e4e9147c8d', 'github/codeql-action/analyze@24c54180a607b1449ed407dd24f251e4e9147c8d')
    '.github/workflows/workflow-security.yml' = @('name: GitHub Actions security analysis', 'zizmorcore/zizmor-action@cc914d7f3750a2d13d75c7f184a1060aa0e9d482', 'advanced-security: true', 'docker://rhysd/actionlint@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667')
    '.github/workflows/openssf-scorecard.yml' = @('name: OpenSSF Scorecard supply-chain security', 'ossf/scorecard-action@2d1146689b8cda280b9bc96326124645441f03bc', 'publish_results: true', 'github/codeql-action/upload-sarif@24c54180a607b1449ed407dd24f251e4e9147c8d')
}

foreach ($contract in $securityWorkflowContracts.GetEnumerator()) {
    $workflowPath = Join-Path $RepositoryRoot $contract.Key
    if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
        continue
    }

    $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredText in $contract.Value) {
        if (-not $workflowContent.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "$($contract.Key) is missing required content: $requiredText"
        }
    }
}

foreach ($workflowFile in Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot '.github/workflows') -File -Filter '*.yml') {
    $workflowContent = Get-Content -LiteralPath $workflowFile.FullName -Raw
    foreach ($use in [regex]::Matches($workflowContent, '(?m)^\s*uses:\s*(?<action>\S+)')) {
        $action = $use.Groups['action'].Value
        if ($action -notmatch '@(?:[0-9a-f]{40}|sha256:[0-9a-f]{64})$') {
            Add-Failure "$($workflowFile.Name) contains an action that is not pinned to an immutable digest: $action"
        }
    }
}

foreach ($reservedPath in @('Learning', 'AsiBackbone', 'NetCoreApplicationTemplate')) {
    if (Test-Path -LiteralPath (Join-Path $RepositoryRoot $reservedPath)) {
        Add-Failure "Reserved project-site path exists in the landing repository: $reservedPath"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host 'Landing-page HTML and crawler metadata contract passed.'
