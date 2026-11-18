[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

    # Reads the compatibility manifest from a local file, for example a clone of AsiBackbone/.github, instead of
    # downloading it from ManifestUri.
    [string]$ManifestPath,

    [string]$ManifestUri = 'https://raw.githubusercontent.com/AsiBackbone/.github/main/compatibility/ecosystem-compatibility.json',

    # Rewrites the generated block in index.html from the manifest instead of checking it.
    [switch]$Update,

    # Also checks the generated block served at this URL, for example https://asibackbone.github.io/.
    [string]$SiteUrl,

    [ValidateRange(1, 60)]
    [int]$MaximumAttempts = 1,

    [ValidateRange(0, 300)]
    [int]$RetryDelaySeconds = 20,

    [switch]$SelfTest
)

# Renders the landing page's "Current releases" summary from the organization compatibility manifest
# (AsiBackbone/.github compatibility/ecosystem-compatibility.json) and fails when index.html, or the live page with
# -SiteUrl, differs from that rendering (issue #45). The manifest is the only source of version data; this script
# holds no version numbers of its own. Run with -Update after the manifest changes, then commit index.html.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$matrixUrl = 'https://github.com/AsiBackbone/.github/blob/main/compatibility/README.md'
$beginMarker = '<!-- BEGIN release-summary:'
$endMarker = '<!-- END release-summary -->'
$blockPattern = '(?ms)^[ \t]*<!-- BEGIN release-summary:[^\r\n]*\r?\n.*?^[ \t]*<!-- END release-summary -->'
$stableVersionPattern = '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$'
$datePattern = '^\d{4}-\d{2}-\d{2}$'

# Canonical project order (AsiBackbone/.github LANDING-PAGE-STANDARD.md): Learn, Framework, Template, Reference.
$products = [ordered]@{
    learning = [pscustomobject]@{ Name = 'AsiBackbone Learning'; Short = 'Learning'; Repository = 'AsiBackbone/Learning' }
    asiBackbone = [pscustomobject]@{ Name = 'AsiBackbone'; Short = 'AsiBackbone'; Repository = 'AsiBackbone/AsiBackbone' }
    netCoreApplicationTemplate = [pscustomobject]@{ Name = '.NET Core Application Template'; Short = 'NCAT'; Repository = 'AsiBackbone/NetCoreApplicationTemplate' }
    referenceApplication = [pscustomobject]@{ Name = 'AsiBackbone Reference Application'; Short = 'Reference Application'; Repository = 'AsiBackbone/ReferenceApplication' }
}

function ConvertTo-Html([string]$Text) {
    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-ReleaseLink([string]$Product, [string]$Version) {
    $definition = $products[$Product]
    $url = "https://github.com/$($definition.Repository)/releases/tag/v$Version"
    return "<a href=`"$(ConvertTo-Html $url)`">$(ConvertTo-Html "$($definition.Short) $Version")</a>"
}

function Get-DateHtml([string]$Date) {
    return "<time datetime=`"$(ConvertTo-Html $Date)`">$(ConvertTo-Html $Date)</time>"
}

function Get-Entry($Object, [string]$Name) {
    if ($null -eq $Object -or $Object -isnot [System.Collections.IDictionary] -or -not $Object.Contains($Name)) {
        return $null
    }

    # The comma keeps arrays, including single-element and empty arrays, from being unrolled.
    return , $Object[$Name]
}

# Emits each element so callers can collect with @(); a single object, including a dictionary, is emitted once.
function Get-List($Value) {
    if ($null -eq $Value) {
        return
    }

    foreach ($item in $Value) {
        $item
    }
}

# Returns the values the summary needs, or throws with every manifest problem found.
function Read-ReleaseSummaryModel($Manifest) {
    $errors = [System.Collections.Generic.List[string]]::new()

    if ((Get-Entry $Manifest 'schemaVersion') -ne 1) {
        $errors.Add('schemaVersion must be 1; update this script for a new manifest schema.')
    }

    $updated = [string](Get-Entry $Manifest 'updated')
    if ($updated -notmatch $datePattern) {
        $errors.Add("updated must be a YYYY-MM-DD date, not '$updated'.")
    }

    $current = [ordered]@{}
    $lines = [ordered]@{}
    $supportLines = @(Get-List (Get-Entry $Manifest 'supportLines'))
    foreach ($product in $products.Keys) {
        $entries = @($supportLines | Where-Object { [string](Get-Entry $_ 'product') -ceq $product })
        if ($entries.Count -ne 1) {
            $errors.Add("supportLines must contain exactly one '$product' entry; found $($entries.Count).")
            continue
        }

        $version = [string](Get-Entry $entries[0] 'current')
        if ($version -notmatch $stableVersionPattern) {
            $errors.Add("supportLines '$product' current must be a stable MAJOR.MINOR.PATCH release, not '$version'.")
        }

        $line = [string](Get-Entry $entries[0] 'line')
        if ($line -notmatch '^\d+\.x$') {
            $errors.Add("supportLines '$product' line must look like '7.x', not '$line'.")
        }

        $current[$product] = $version
        $lines[$product] = $line
    }

    $combinations = @(Get-List (Get-Entry $Manifest 'combinations'))
    $integration = @($combinations | Where-Object {
            [string](Get-Entry $_ 'kind') -ceq 'integration' -and [string](Get-Entry $_ 'status') -ceq 'reviewed'
        })
    $learningReview = @($combinations | Where-Object {
            [string](Get-Entry $_ 'kind') -ceq 'learning-review' -and [string](Get-Entry $_ 'status') -ceq 'reviewed'
        })

    $integrationModel = $null
    if ($integration.Count -ne 1) {
        $errors.Add("combinations must contain exactly one reviewed integration entry; found $($integration.Count).")
    }
    else {
        $components = Get-Entry $integration[0] 'components'
        $integrationModel = [pscustomobject]@{
            Template = [string](Get-Entry $components 'netCoreApplicationTemplate')
            Framework = [string](Get-Entry $components 'asiBackbone')
            Reference = @(Get-List (Get-Entry $components 'referenceApplication') | ForEach-Object { [string]$_ })
            TargetFramework = [string](Get-Entry $integration[0] 'targetFramework')
            Reviewed = [string](Get-Entry $integration[0] 'reviewed')
        }

        foreach ($version in @($integrationModel.Template, $integrationModel.Framework) + $integrationModel.Reference) {
            if ($version -notmatch $stableVersionPattern) {
                $errors.Add("The reviewed integration entry must name stable releases; found '$version'.")
            }
        }
        if ($integrationModel.Reference.Count -eq 0) {
            $errors.Add('The reviewed integration entry must name at least one Reference Application release.')
        }
        if ($integrationModel.TargetFramework -notmatch '^net\d+\.\d+$') {
            $errors.Add("The reviewed integration entry has an invalid targetFramework '$($integrationModel.TargetFramework)'.")
        }
        if ($integrationModel.Reviewed -notmatch $datePattern) {
            $errors.Add("The reviewed integration entry has an invalid reviewed date '$($integrationModel.Reviewed)'.")
        }
    }

    $learningModel = $null
    $currentLearning = if ($current.Contains('learning')) { $current['learning'] } else { $null }
    $coveringReviews = @($learningReview | Where-Object {
            @(Get-List (Get-Entry (Get-Entry $_ 'components') 'learning')) -ccontains $currentLearning
        })
    if ($coveringReviews.Count -ne 1) {
        $errors.Add("combinations must contain exactly one reviewed learning-review entry for Learning $currentLearning; found $($coveringReviews.Count).")
    }
    else {
        $components = Get-Entry $coveringReviews[0] 'components'
        $learningModel = [pscustomobject]@{
            Framework = [string](Get-Entry $components 'asiBackbone')
            Template = [string](Get-Entry $components 'netCoreApplicationTemplate')
            Reviewed = [string](Get-Entry $coveringReviews[0] 'reviewed')
        }

        if ($learningModel.Framework -notmatch $stableVersionPattern) {
            $errors.Add("The current Learning review must name a stable AsiBackbone release; found '$($learningModel.Framework)'.")
        }
        if ($learningModel.Template -and $learningModel.Template -notmatch $stableVersionPattern) {
            $errors.Add("The current Learning review names an invalid NCAT release '$($learningModel.Template)'.")
        }
        if ($learningModel.Reviewed -notmatch $datePattern) {
            $errors.Add("The current Learning review has an invalid reviewed date '$($learningModel.Reviewed)'.")
        }
    }

    if ($errors.Count -gt 0) {
        throw "The compatibility manifest cannot be summarized:`n- $($errors -join "`n- ")"
    }

    return [pscustomobject]@{
        Updated = $updated
        Current = $current
        Lines = $lines
        Integration = $integrationModel
        Learning = $learningModel
    }
}

# Renders the generated block, indented for its place in index.html, with LF line endings.
function Get-ReleaseSummaryBlock($Manifest) {
    $model = Read-ReleaseSummaryModel $Manifest
    $i = '        '
    $rows = [System.Collections.Generic.List[string]]::new()

    foreach ($product in $products.Keys) {
        $name = ConvertTo-Html $products[$product].Name
        $release = Get-ReleaseLink $product $model.Current[$product]
        $line = if ($product -ceq 'learning') {
            'Archival snapshot; not a support line'
        }
        else {
            "$(ConvertTo-Html $model.Lines[$product]) line"
        }
        $label = if ($product -ceq 'learning') { 'Archive: ' } else { '' }

        $rows.Add("$i      <tr><th scope=`"row`">$name</th><td>$label$release</td><td>$line</td></tr>")
    }

    $integration = $model.Integration
    $referenceLinks = ($integration.Reference | ForEach-Object { Get-ReleaseLink 'referenceApplication' $_ }) -join ', '
    $learning = $model.Learning
    $learningPins = if ($learning.Template) {
        "$(Get-ReleaseLink 'asiBackbone' $learning.Framework) and $(Get-ReleaseLink 'netCoreApplicationTemplate' $learning.Template)"
    }
    else {
        Get-ReleaseLink 'asiBackbone' $learning.Framework
    }

    $lines = @(
        "$i<!-- BEGIN release-summary: generated from AsiBackbone/.github compatibility/ecosystem-compatibility.json by scripts/Test-ReleaseSummary.ps1 -Update. Do not edit by hand. -->"
        "$i<p>Current stable releases, from the organization <a href=`"$matrixUrl`">ecosystem compatibility matrix</a> updated $(Get-DateHtml $model.Updated). Each project releases on its own schedule; a current release is not automatically reviewed with the others.</p>"
        "$i<div class=`"table-scroll`">"
        "$i  <table>"
        "$i    <thead>"
        "$i      <tr><th scope=`"col`">Project</th><th scope=`"col`">Current release</th><th scope=`"col`">Support</th></tr>"
        "$i    </thead>"
        "$i    <tbody>"
    ) + $rows.ToArray() + @(
        "$i    </tbody>"
        "$i  </table>"
        "$i</div>"
        "$i<p><strong>Reviewed together:</strong> $referenceLinks builds and tests $(Get-ReleaseLink 'netCoreApplicationTemplate' $integration.Template) with $(Get-ReleaseLink 'asiBackbone' $integration.Framework) on <code>$(ConvertTo-Html $integration.TargetFramework)</code>, reviewed $(Get-DateHtml $integration.Reviewed).</p>"
        "$i<p><strong>Learning teaching baseline:</strong> $(Get-ReleaseLink 'learning' $model.Current['learning']) keeps its implementation-dependent pages reviewed against $learningPins, reviewed $(Get-DateHtml $learning.Reviewed). Those pins are deliberate teaching snapshots, not a recommendation to install older releases.</p>"
        "$i<p>A combination the matrix does not list is untested, not known to be broken. The matrix links the evidence for every reviewed and historical combination.</p>"
        "$i$endMarker"
    )

    return $lines -join "`n"
}

function Get-GeneratedBlock([string]$Html, [string]$Source) {
    $blocks = [regex]::Matches($Html, $blockPattern)
    if ($blocks.Count -ne 1) {
        throw "$Source must contain exactly one generated release-summary block between '$beginMarker' and '$endMarker'; found $($blocks.Count)."
    }

    return $blocks[0]
}

function Set-GeneratedBlock([string]$Html, [string]$Block) {
    $match = Get-GeneratedBlock $Html 'index.html'
    $newline = if ($Html.Contains("`r`n")) { "`r`n" } else { "`n" }
    return $Html.Substring(0, $match.Index) + $Block.Replace("`n", $newline) + $Html.Substring($match.Index + $match.Length)
}

function Test-BlockMatches([string]$Html, [string]$Expected, [string]$Source) {
    $actual = (Get-GeneratedBlock $Html $Source).Value.Replace("`r`n", "`n")
    return $actual -ceq $Expected
}

function Read-Manifest {
    if ($ManifestPath) {
        $json = Get-Content -LiteralPath $ManifestPath -Raw
        $source = $ManifestPath
    }
    else {
        $json = (Invoke-WebRequest -Uri $ManifestUri -TimeoutSec 30 -Headers @{ 'Cache-Control' = 'no-cache' }).Content
        $source = $ManifestUri
    }

    Write-Host "Compatibility manifest: $source"
    return $json | ConvertFrom-Json -AsHashtable -Depth 20
}

if ($SelfTest) {
    $fixture = @'
{
  "schemaVersion": 1,
  "updated": "2026-11-15",
  "supportLines": [
    { "product": "asiBackbone", "line": "7.x", "current": "7.5.4" },
    { "product": "netCoreApplicationTemplate", "line": "2.x", "current": "2.11.10" },
    { "product": "referenceApplication", "line": "1.x", "current": "1.0.2" },
    { "product": "learning", "line": "1.x", "current": "1.6.0" }
  ],
  "combinations": [
    { "kind": "integration", "status": "reviewed", "targetFramework": "net10.0", "reviewed": "2026-11-15",
      "components": { "netCoreApplicationTemplate": "2.11.10", "asiBackbone": "7.5.4", "referenceApplication": ["1.0.2"], "learning": [] } },
    { "kind": "integration", "status": "historical", "targetFramework": "net10.0", "reviewed": "2026-11-07",
      "components": { "netCoreApplicationTemplate": "2.11.7", "asiBackbone": "7.5.3", "referenceApplication": ["1.0.1"], "learning": [] } },
    { "kind": "learning-review", "status": "reviewed", "targetFramework": "net10.0", "reviewed": "2026-11-14",
      "components": { "netCoreApplicationTemplate": "2.11.2", "asiBackbone": "7.0.0", "referenceApplication": [], "learning": ["1.6.0"] } }
  ]
}
'@
    $failures = [System.Collections.Generic.List[string]]::new()
    function New-Fixture { return $fixture | ConvertFrom-Json -AsHashtable }
    function Set-Current($Manifest, [string]$Product, [string]$Version) {
        foreach ($line in $Manifest['supportLines']) {
            if ($line['product'] -ceq $Product) {
                $line['current'] = $Version
            }
        }
    }

    $block = Get-ReleaseSummaryBlock (New-Fixture)
    foreach ($expected in @(
            'https://github.com/AsiBackbone/Learning/releases/tag/v1.6.0">Learning 1.6.0</a>'
            'https://github.com/AsiBackbone/AsiBackbone/releases/tag/v7.5.4">AsiBackbone 7.5.4</a>'
            'https://github.com/AsiBackbone/NetCoreApplicationTemplate/releases/tag/v2.11.10">NCAT 2.11.10</a>'
            'https://github.com/AsiBackbone/ReferenceApplication/releases/tag/v1.0.2">Reference Application 1.0.2</a>'
            'https://github.com/AsiBackbone/AsiBackbone/releases/tag/v7.0.0">AsiBackbone 7.0.0</a>'
            'https://github.com/AsiBackbone/NetCoreApplicationTemplate/releases/tag/v2.11.2">NCAT 2.11.2</a>'
            $matrixUrl
            '<time datetime="2026-11-15">2026-11-15</time>'
            'not automatically reviewed with the others'
            'not a recommendation to install older releases'
        )) {
        if (-not $block.Contains($expected, [StringComparison]::Ordinal)) {
            $failures.Add("Rendered summary is missing: $expected")
        }
    }
    if ($block.Contains('7.5.3', [StringComparison]::Ordinal)) {
        $failures.Add('Rendered summary must not include historical combinations.')
    }

    # A newer release that has not yet been integration-reviewed is shown as current without being called reviewed.
    $ahead = New-Fixture
    Set-Current $ahead 'asiBackbone' '7.6.0'
    $aheadBlock = Get-ReleaseSummaryBlock $ahead
    if (-not $aheadBlock.Contains('>AsiBackbone 7.6.0</a></td>', [StringComparison]::Ordinal) -or
        -not $aheadBlock.Contains('with <a href="https://github.com/AsiBackbone/AsiBackbone/releases/tag/v7.5.4">AsiBackbone 7.5.4</a> on', [StringComparison]::Ordinal)) {
        $failures.Add('A current release ahead of the reviewed integration must be listed as current while the reviewed combination keeps its own versions.')
    }

    $rejected = [ordered]@{
        'pre-release current version' = { param($m) Set-Current $m 'learning' '1.7.0-beta.1' }
        'missing product' = { param($m) $m['supportLines'] = @($m['supportLines'] | Where-Object { $_['product'] -ne 'referenceApplication' }) }
        'two reviewed integrations' = { param($m) $m['combinations'][1]['status'] = 'reviewed' }
        'no review covering current Learning' = { param($m) Set-Current $m 'learning' '1.7.0' }
        'unsupported schema' = { param($m) $m['schemaVersion'] = 2 }
    }
    foreach ($case in $rejected.GetEnumerator()) {
        $manifest = New-Fixture
        & $case.Value $manifest
        try {
            $null = Get-ReleaseSummaryBlock $manifest
            $failures.Add("Manifest with $($case.Key) was not rejected.")
        }
        catch {
        }
    }

    $page = "<main>`n    <div class=`"releases`">`n        $beginMarker stale -->`n        <p>AsiBackbone 7.0.0</p>`n        $endMarker`n    </div>`n</main>`n"
    if (Test-BlockMatches $page $block 'fixture') {
        $failures.Add('A stale generated block was not detected.')
    }
    $updatedPage = Set-GeneratedBlock $page $block
    if (-not (Test-BlockMatches $updatedPage $block 'fixture') -or
        -not $updatedPage.StartsWith("<main>`n    <div class=`"releases`">`n", [StringComparison]::Ordinal) -or
        -not $updatedPage.EndsWith("`n    </div>`n</main>`n", [StringComparison]::Ordinal)) {
        $failures.Add('Updating the generated block did not replace exactly the block.')
    }
    if (-not (Test-BlockMatches ($updatedPage.Replace("`n", "`r`n")) $block 'fixture')) {
        $failures.Add('A CRLF checkout of a current block was reported as stale.')
    }
    try {
        $null = Get-GeneratedBlock ($updatedPage + $updatedPage) 'fixture'
        $failures.Add('Two generated blocks were not rejected.')
    }
    catch {
    }

    if ($failures.Count -gt 0) {
        $failures | ForEach-Object { Write-Host "::error::$_" }
        exit 1
    }

    Write-Host 'Release-summary self-test passed.'
    exit 0
}

$indexPath = Join-Path $RepositoryRoot 'index.html'
$html = Get-Content -LiteralPath $indexPath -Raw
$expected = Get-ReleaseSummaryBlock (Read-Manifest)

if ($Update) {
    $updatedHtml = Set-GeneratedBlock $html $expected
    if ($updatedHtml -ceq $html) {
        Write-Host 'index.html release summary is already current.'
    }
    else {
        [System.IO.File]::WriteAllText($indexPath, $updatedHtml, [System.Text.UTF8Encoding]::new($false))
        Write-Host 'Updated the index.html release summary. Review and commit the change.'
    }
    exit 0
}

if (-not (Test-BlockMatches $html $expected 'index.html')) {
    Write-Host '::error::index.html release summary does not match the compatibility manifest. Run ./scripts/Test-ReleaseSummary.ps1 -Update and commit index.html.'
    exit 1
}
Write-Host 'index.html release summary matches the compatibility manifest.'

if ($SiteUrl) {
    $committed = (Get-GeneratedBlock $html 'index.html').Value.Replace("`r`n", "`n")
    $reason = 'no attempt completed'

    for ($attempt = 1; $attempt -le $MaximumAttempts; $attempt++) {
        try {
            $separator = if ($SiteUrl.Contains('?')) { '&' } else { '?' }
            $uri = "$SiteUrl${separator}release-summary=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
            $live = (Invoke-WebRequest -Uri $uri -TimeoutSec 30 -Headers @{ 'Cache-Control' = 'no-cache' }).Content
            $liveBlock = (Get-GeneratedBlock $live $SiteUrl).Value.Replace("`r`n", "`n")

            if ($liveBlock -ceq $committed) {
                Write-Host "$SiteUrl serves the committed release summary, which matches the compatibility manifest."
                exit 0
            }

            $reason = "$SiteUrl does not serve the committed release summary yet"
        }
        catch {
            $reason = $_.Exception.Message
        }

        if ($attempt -lt $MaximumAttempts) {
            Write-Host "Attempt ${attempt}: $reason; retrying in $RetryDelaySeconds seconds."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    Write-Host "::error::Live release-summary check failed after $MaximumAttempts attempt(s): $reason."
    exit 1
}
