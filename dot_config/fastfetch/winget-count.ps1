param(
    [switch]$Refresh,
    [string]$CacheDirectory = (Join-Path $env:LOCALAPPDATA "fastfetch")
)

$ErrorActionPreference = "Stop"
$cachePath = Join-Path $CacheDirectory "winget-count.txt"
$lockPath = Join-Path $CacheDirectory "winget-count.lock"
$cacheLifetime = [TimeSpan]::FromHours(6)

function Get-CachedCount {
    if (-not (Test-Path -LiteralPath $cachePath -PathType Leaf)) {
        return $null
    }

    $value = 0
    $content = (Get-Content -LiteralPath $cachePath -Raw).Trim()
    if ([int]::TryParse($content, [ref]$value)) {
        return $value
    }

    return $null
}

if (-not $Refresh) {
    $cachedCount = Get-CachedCount
    if ($null -eq $cachedCount) {
        Write-Output "…"
    } else {
        Write-Output $cachedCount
    }

    $cacheIsFresh = $null -ne $cachedCount -and
        (Get-Item -LiteralPath $cachePath).LastWriteTimeUtc -gt [DateTime]::UtcNow.Subtract($cacheLifetime)
    if ($cacheIsFresh) {
        exit 0
    }

    New-Item -ItemType Directory -Path $CacheDirectory -Force | Out-Null
    if ((Test-Path -LiteralPath $lockPath) -and
        (Get-Item -LiteralPath $lockPath).LastWriteTimeUtc -lt [DateTime]::UtcNow.AddMinutes(-10)) {
        Remove-Item -LiteralPath $lockPath -Force
    }

    if (-not (Test-Path -LiteralPath $lockPath)) {
        $pwshPath = (Get-Process -Id $PID).Path
        $argumentLine = '-NoLogo -NoProfile -NonInteractive -File "{0}" -Refresh -CacheDirectory "{1}"' -f `
            $PSCommandPath.Replace('"', '\"'), $CacheDirectory.Replace('"', '\"')
        Start-Process -FilePath $pwshPath -ArgumentList $argumentLine -WindowStyle Hidden | Out-Null
    }

    exit 0
}

New-Item -ItemType Directory -Path $CacheDirectory -Force | Out-Null
$lockStream = $null
try {
    try {
        $lockStream = [System.IO.File]::Open(
            $lockPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )
    } catch [System.IO.IOException] {
        exit 0
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        exit 0
    }

    $lines = @(winget list --count 1000 --disable-interactivity --accept-source-agreements --nowarn 2>$null)
    if ($LASTEXITCODE -ne 0) {
        exit 0
    }

    $tableStarted = $false
    $packageCount = 0
    foreach ($line in $lines) {
        $plainLine = ([string]$line) -replace "`e\[[0-?]*[ -/]*[@-~]", ""
        if (-not $tableStarted) {
            if ($plainLine -match "^-{3,}\s*$") {
                $tableStarted = $true
            }
            continue
        }

        if ([string]::IsNullOrWhiteSpace($plainLine)) {
            if ($packageCount -gt 0) {
                break
            }
            continue
        }

        $packageCount++
    }

    if ($tableStarted) {
        [System.IO.File]::WriteAllText(
            $cachePath,
            $packageCount.ToString([Globalization.CultureInfo]::InvariantCulture),
            [System.Text.UTF8Encoding]::new($false)
        )
    }
} finally {
    if ($null -ne $lockStream) {
        $lockStream.Dispose()
        Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
    }
}
