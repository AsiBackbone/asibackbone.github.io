[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Ref = 'origin/main',
    [string]$BaseUrl = 'https://asibackbone.github.io/',

    # Retries the whole comparison so the check can run while a Pages deployment is still propagating.
    [ValidateRange(1, 60)]
    [int]$MaximumAttempts = 1,

    [ValidateRange(0, 300)]
    [int]$RetryDelaySeconds = 20
)

# Confirms that GitHub Pages serves the committed bytes of every site file at $Ref (see PUBLICATION-INTEGRITY.md).
# This is a monitoring check, not a signature: it trusts GitHub's HTTPS endpoint and the repository's main branch.
# A mismatch shortly after a merge can mean the Pages deployment has not finished yet; -MaximumAttempts retries the
# comparison for that case. Each request adds a query string so a cached copy is not mistaken for the deployment.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$siteFiles = @(
    'index.html'
    'search/index.html'
    'search/search.js'
    'search/search.css'
    'robots.txt'
    'sitemap.xml'
    'site-sitemap.xml'
    'images/asibackbone-icon-50.png'
    'images/asibackbone-social.png'
    'images/favicon.ico'
)

$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("site-parity-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workRoot | Out-Null
$failures = [System.Collections.Generic.List[string]]::new()

try {
    $commit = (& git -C $RepositoryRoot rev-parse --verify "$Ref^{commit}" 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($commit)) {
        throw "Unable to resolve '$Ref' to a commit. Fetch it first."
    }
    $commit = $commit.Trim()

    for ($attempt = 1; $attempt -le $MaximumAttempts; $attempt++) {
        $failures.Clear()

        foreach ($file in $siteFiles) {
            $committedPath = Join-Path $workRoot 'committed'
            $servedPath = Join-Path $workRoot 'served'

            # Copy the blob's raw output stream so the bytes are not re-encoded by the PowerShell pipeline.
            $startInfo = [System.Diagnostics.ProcessStartInfo]::new('git')
            foreach ($argument in @('-C', $RepositoryRoot, 'cat-file', 'blob', "${commit}:$file")) {
                $startInfo.ArgumentList.Add($argument)
            }
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.UseShellExecute = $false
            $process = [System.Diagnostics.Process]::Start($startInfo)
            $stream = [System.IO.File]::Create($committedPath)
            try {
                $process.StandardOutput.BaseStream.CopyTo($stream)
            }
            finally {
                $stream.Dispose()
            }
            $null = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            if ($process.ExitCode -ne 0) {
                $failures.Add("$file is not present at $commit.")
                continue
            }

            try {
                $servedUri = [System.UriBuilder]::new([uri]::new([uri]$BaseUrl, $file))
                $servedUri.Query = "parity=$commit-$attempt"
                Invoke-WebRequest -Uri $servedUri.Uri -OutFile $servedPath -MaximumRedirection 0 -TimeoutSec 30 -Headers @{ 'Cache-Control' = 'no-cache' } | Out-Null
            }
            catch {
                $failures.Add("$file could not be downloaded from ${BaseUrl}: $($_.Exception.Message)")
                continue
            }

            $committedHash = (Get-FileHash -LiteralPath $committedPath -Algorithm SHA256).Hash
            $servedHash = (Get-FileHash -LiteralPath $servedPath -Algorithm SHA256).Hash
            if ($committedHash -ne $servedHash) {
                $failures.Add("$file differs: committed $committedHash, served $servedHash.")
            }
            else {
                Write-Host "Match: $file ($($committedHash.ToLowerInvariant()))"
            }
        }

        if ($failures.Count -eq 0 -or $attempt -eq $MaximumAttempts) {
            break
        }

        Write-Host "Attempt ${attempt}: $($failures.Count) file(s) differ or could not be downloaded; retrying in $RetryDelaySeconds seconds."
        Start-Sleep -Seconds $RetryDelaySeconds
    }
}
finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    throw "Published site parity failed for $($failures.Count) of $($siteFiles.Count) files against $commit."
}

Write-Host "All $($siteFiles.Count) served site files match $commit."
