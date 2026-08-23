# 由 chezmoi 管理的 PowerShell 7 配置。

if (-not $global:DotfilesPowerShellProfileLoaded) {
    $global:DotfilesPowerShellProfileLoaded = $true

    # 让 PowerShell 与原生命令统一使用无 BOM 的 UTF-8。
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
    $global:OutputEncoding = $utf8NoBom
    $env:PYTHONIOENCODING = "utf-8"
    $env:PYTHONUTF8 = "1"

    if ($Host.Name -eq "ConsoleHost") {
        Import-Module PSReadLine -ErrorAction SilentlyContinue
        if (Get-Module PSReadLine) {
            Set-PSReadLineOption -EditMode Windows
            Set-PSReadLineOption -BellStyle None
            Set-PSReadLineOption -HistoryNoDuplicates
            Set-PSReadLineOption -HistorySearchCursorMovesToEnd
            if (-not [Console]::IsOutputRedirected) {
                Set-PSReadLineOption -PredictionSource History
            }
            Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
            Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
            Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        }
    }

    if ((Get-Command fnm -ErrorAction SilentlyContinue) -and -not $env:FNM_MULTISHELL_PATH) {
        fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
    }

    if ((Get-Command starship -ErrorAction SilentlyContinue) -and $env:STARSHIP_SHELL -ne "pwsh") {
        Invoke-Expression (&starship init powershell)
    }

    # 私密或仅限当前设备的设置放在这里，这个文件不会由 chezmoi 管理。
    $localProfile = Join-Path $HOME ".config\powershell\profile.local.ps1"
    if (Test-Path -LiteralPath $localProfile) {
        . $localProfile
    }
}
