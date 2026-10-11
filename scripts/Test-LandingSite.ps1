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
