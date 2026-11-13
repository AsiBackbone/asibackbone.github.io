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
$searchPath = Get-RequiredFile 'search/index.html'
$searchScriptPath = Get-RequiredFile 'search/search.js'
$searchStylesPath = Get-RequiredFile 'search/search.css'
$siteSitemapPath = Get-RequiredFile 'site-sitemap.xml'
$readmePath = Get-RequiredFile 'README.md'
$robotsPath = Get-RequiredFile 'robots.txt'
$sitemapPath = Get-RequiredFile 'sitemap.xml'
$licensePath = Get-RequiredFile 'LICENSE'
$codeLicensePath = Get-RequiredFile 'LICENSE-CODE'
$licenseScopePath = Get-RequiredFile 'LICENSES.md'
$assetLicensePath = Get-RequiredFile 'ASSETS-LICENSES.md'
$securityBaselinePath = Get-RequiredFile 'SECURITY-BASELINE.md'
$publicationIntegrityPath = Get-RequiredFile 'PUBLICATION-INTEGRITY.md'
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
        'https://github.com/AsiBackbone/Learning/issues' = 'Learning issue route'
        'https://github.com/AsiBackbone/AsiBackbone/issues' = 'AsiBackbone issue route'
        'https://github.com/AsiBackbone/NetCoreApplicationTemplate/issues' = 'template issue route'
        'https://github.com/AsiBackbone/ReferenceApplication/issues' = 'Reference Application issue route'
        'https://github.com/AsiBackbone/Learning/blob/main/CONTRIBUTING.md' = 'Learning contribution route'
        'https://github.com/AsiBackbone/AsiBackbone/blob/main/CONTRIBUTING.md' = 'AsiBackbone contribution route'
        'https://github.com/AsiBackbone/NetCoreApplicationTemplate/blob/main/CONTRIBUTING.md' = 'template contribution route'
        'https://github.com/AsiBackbone/.github/blob/main/CONTRIBUTING.md' = 'Reference Application contribution route'
        'https://github.com/AsiBackbone/Learning/security/policy' = 'Learning security route'
        'https://github.com/AsiBackbone/AsiBackbone/security/policy' = 'AsiBackbone security route'
        'https://github.com/AsiBackbone/NetCoreApplicationTemplate/security/policy' = 'template security route'
        'https://github.com/AsiBackbone/ReferenceApplication/security/policy' = 'Reference Application security route'
        'https://www.patreon.com/AsiBackbone' = 'organization Patreon funding route'
    }

    foreach ($entry in $requiredCommunityRoutes.GetEnumerator()) {
        if (-not $html.Contains('href="' + $entry.Key + '"', [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing its $($entry.Value)."
        }
    }

    foreach ($requiredText in @(
        'Use organization Q&amp;A for project-specific and cross-project questions, and name the affected repository and version.'
        "Route concrete work to the affected repository's issues and contribution guidance."
    )) {
        if (-not $html.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing required support-routing guidance: $requiredText"
        }
    }

    foreach ($requiredText in @(
        '<form class="site-search" role="search" action="https://asibackbone.github.io/search/" method="get">'
        '<input name="q" type="search"'
    )) {
        if (-not $html.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing required organization-search entry point: $requiredText"
        }
    }

    foreach ($requiredText in @(
        '<a href="#funding">Funding</a>'
        '<section id="funding" aria-labelledby="funding-title">'
        '<h2 id="funding-title">Support AsiBackbone</h2>'
        'Sponsorship is voluntary and does not provide roadmap priority, governance authority, or preferential technical support.'
    )) {
        if (-not $html.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing required funding content: $requiredText"
        }
    }

    if ($html -match 'https://github\.com/AsiBackbone/(?:Learning|AsiBackbone|NetCoreApplicationTemplate|ReferenceApplication)/discussions') {
        Add-Failure 'index.html must not route readers to a project repository Discussions surface.'
    }

    foreach ($requiredText in @(
        'A reusable, production-oriented ASP.NET Core baseline with secure defaults'
        'It is not a finished, penetration-tested, or certified application'
        'each generated application still requires application-specific configuration, threat analysis, deployment controls, testing, and security review.'
    )) {
        if (-not $html.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "index.html is missing the NCAT product-boundary statement: $requiredText"
        }
    }

    if ($html -match '(?i)production-ready|enterprise application template') {
        Add-Failure 'index.html overstates the NCAT boundary; use production-oriented baseline terminology.'
    }

    if (-not $html.Contains('a:focus-visible', [StringComparison]::Ordinal)) {
        Add-Failure 'index.html must retain a visible keyboard-focus treatment for links.'
    }

    if ($html -match '(?is)@media\s*\(max-width:[^)]+\).*?header\.site\s+nav\s*\{[^}]*display:\s*none') {
        Add-Failure 'index.html must keep the ecosystem navigation reachable at narrow viewport widths.'
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

if ($searchPath) {
    $searchHtml = Get-Content -LiteralPath $searchPath -Raw
    foreach ($requiredText in @(
        '<html lang="en">'
        '<link rel="canonical" href="https://asibackbone.github.io/search/">'
        '<form id="organization-search" role="search" action="/search/" method="get">'
        '<input id="search-query" name="q" type="search"'
        '<p id="search-status" class="status" role="status" aria-live="polite"></p>'
        '<script src="search.js" defer></script>'
    )) {
        if (-not $searchHtml.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "search/index.html is missing required organization-search content: $requiredText"
        }
    }
}

if ($searchScriptPath) {
    $searchScript = Get-Content -LiteralPath $searchScriptPath -Raw
    foreach ($requiredText in @(
        'https://asibackbone.github.io/Learning/index.json'
        'https://asibackbone.github.io/AsiBackbone/index.json'
        'https://asibackbone.github.io/NetCoreApplicationTemplate/index.json'
        'https://asibackbone.github.io/ReferenceApplication/index.json'
        'Promise.allSettled'
        'new URL(entry.href || key, source.base).href'
        'link.textContent = result.entry.title'
        'summary.textContent = result.entry.summary.length > 320'
    )) {
        if (-not $searchScript.Contains($requiredText, [StringComparison]::Ordinal)) {
            Add-Failure "search/search.js is missing required organization-search behavior: $requiredText"
        }
    }
}

if ($readmePath) {
    $readme = Get-Content -LiteralPath $readmePath -Raw
    foreach ($projectSite in @('Learning', 'AsiBackbone', 'NetCoreApplicationTemplate', 'ReferenceApplication')) {
        if (-not $readme.Contains("https://asibackbone.github.io/$projectSite/", [StringComparison]::Ordinal)) {
            Add-Failure "README.md is missing the $projectSite project-site path."
        }
    }

    if (-not $readme.Contains('linking the four projects', [StringComparison]::Ordinal)) {
        Add-Failure 'README.md must describe index.html as linking the four projects.'
    }

    if (-not $readme.Contains('`ReferenceApplication`', [StringComparison]::Ordinal)) {
        Add-Failure 'README.md must reserve the ReferenceApplication project-site path.'
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
            'https://asibackbone.github.io/site-sitemap.xml'
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

if ($siteSitemapPath) {
    try {
        [xml]$siteSitemap = Get-Content -LiteralPath $siteSitemapPath -Raw
        $namespaceManager = [Xml.XmlNamespaceManager]::new($siteSitemap.NameTable)
        $namespaceManager.AddNamespace('sm', 'http://www.sitemaps.org/schemas/sitemap/0.9')
        $actualLocations = @($siteSitemap.SelectNodes('/sm:urlset/sm:url/sm:loc', $namespaceManager) | ForEach-Object InnerText | Sort-Object)
        $expectedLocations = @(
            'https://asibackbone.github.io/'
            'https://asibackbone.github.io/search/'
        ) | Sort-Object

        if (($actualLocations -join "`n") -cne ($expectedLocations -join "`n")) {
            Add-Failure "site-sitemap.xml must list exactly the organization landing page and search page. Found: $($actualLocations -join ', ')"
        }
    }
    catch {
        Add-Failure "site-sitemap.xml is invalid XML: $($_.Exception.Message)"
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
        'images/asibackbone-icon-50.png' = 'A0AE4385961155EF9155A8C6BD85AEC2BE7C7002773CBC22292D972FB0F52FCA'
        'images/asibackbone-social.png' = 'C1B942F50D40A2274B43CFDD8E9FE77F24AE4BA2D3E2287ECDEA5C39EA0CC4EB'
        'images/favicon.ico' = '52DF4FBAF8D4F8D202CAB9309AFCB05BD0012BF59A0ADEA964B22BF35B6FDBEA'
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

    if (-not $securityBaseline.Contains('[publication-integrity assessment](PUBLICATION-INTEGRITY.md)', [StringComparison]::Ordinal)) {
        Add-Failure 'SECURITY-BASELINE.md must link the publication-integrity assessment.'
    }
}

# Sigstore signing is deferred because this repository distributes no downloadable artifact (issue #35). Publishing
# one requires revisiting that decision first, so its file types fail validation while the deferral stands.
if ($publicationIntegrityPath) {
    $publicationIntegrity = Get-Content -LiteralPath $publicationIntegrityPath -Raw
    $decision = [regex]::Match($publicationIntegrity, '(?m)^\*\*Decision:\*\*\s*(?<decision>[A-Za-z]+)\s*$')
    if (-not $decision.Success) {
        Add-Failure "PUBLICATION-INTEGRITY.md must record a '**Decision:**' line."
    }
    elseif ($decision.Groups['decision'].Value -ne 'Deferred') {
        Add-Failure "PUBLICATION-INTEGRITY.md records decision '$($decision.Groups['decision'].Value)', but this validation only supports 'Deferred'. Add signed-artifact verification before changing the decision."
    }
    else {
        foreach ($requiredText in @(
            'https://github.com/AsiBackbone/.github/blob/main/assurance/SIGSTORE.md'
            'GitHub Pages does **not** sign the files it serves'
            '## Revisit triggers'
        )) {
            if (-not $publicationIntegrity.Contains($requiredText, [StringComparison]::Ordinal)) {
                Add-Failure "PUBLICATION-INTEGRITY.md is missing required content: $requiredText"
            }
        }

        $trackedFiles = @(& git -C $RepositoryRoot ls-files 2>$null)
        if ($LASTEXITCODE -ne 0) {
            Add-Failure 'Unable to list tracked files to check for downloadable artifacts.'
        }
        else {
            $artifactPattern = '\.(zip|tar|tgz|gz|bz2|xz|7z|rar|nupkg|snupkg|jar|whl|exe|msi|msix|dll|so|dylib|deb|rpm|dmg|pkg|appimage|iso|pdf)$'
            foreach ($trackedFile in $trackedFiles) {
                if ($trackedFile -match $artifactPattern) {
                    Add-Failure "Downloadable artifact '$trackedFile' is tracked, but PUBLICATION-INTEGRITY.md defers Sigstore signing because none are published. Revisit that decision before publishing artifacts."
                }
            }
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
    '.github/workflows/dependency-review.yml' = @('name: Dependency Review', 'fail-on-severity: moderate')
    '.github/workflows/codeql.yml' = @('name: CodeQL Analysis', 'pull_request:', 'push:', 'languages: actions')
    '.github/workflows/workflow-security.yml' = @('name: GitHub Actions security analysis', 'advanced-security: true', 'docker://rhysd/actionlint@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667')
    '.github/workflows/openssf-scorecard.yml' = @('name: OpenSSF Scorecard supply-chain security', 'publish_results: true')
}

# Required actions are checked by name and commit-SHA form, not by a specific SHA, so Dependabot
# version updates satisfy the contract. The workflow loop below still rejects unpinned references.
$requiredPinnedActions = [ordered]@{
    '.github/workflows/dependency-review.yml' = @('actions/dependency-review-action')
    '.github/workflows/codeql.yml' = @('github/codeql-action/init', 'github/codeql-action/analyze')
    '.github/workflows/workflow-security.yml' = @('zizmorcore/zizmor-action')
    '.github/workflows/openssf-scorecard.yml' = @('ossf/scorecard-action', 'github/codeql-action/upload-sarif')
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

foreach ($contract in $requiredPinnedActions.GetEnumerator()) {
    $workflowPath = Join-Path $RepositoryRoot $contract.Key
    if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
        continue
    }

    $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredAction in $contract.Value) {
        $pinnedUsePattern = '(?m)^\s*(?:-\s+)?uses:\s*' + [regex]::Escape($requiredAction) + '@[0-9a-f]{40}(?:\s|$)'
        if ($workflowContent -notmatch $pinnedUsePattern) {
            Add-Failure "$($contract.Key) must use $requiredAction pinned to a full commit SHA."
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

foreach ($reservedPath in @('Learning', 'AsiBackbone', 'NetCoreApplicationTemplate', 'ReferenceApplication')) {
    if (Test-Path -LiteralPath (Join-Path $RepositoryRoot $reservedPath)) {
        Add-Failure "Reserved project-site path exists in the landing repository: $reservedPath"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host 'Landing-page HTML and crawler metadata contract passed.'
