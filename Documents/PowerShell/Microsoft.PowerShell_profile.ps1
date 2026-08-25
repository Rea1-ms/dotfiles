# 由 chezmoi 直接管理的 PowerShell 7 profile。

if (-not $global:DotfilesPowerShellProfileLoaded) {
    $global:DotfilesPowerShellProfileLoaded = $true

    # 让 PowerShell 与原生命令统一使用无 BOM 的 UTF-8。
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
    $global:OutputEncoding = $utf8NoBom
    $env:PYTHONIOENCODING = "utf-8"
    $env:PYTHONUTF8 = "1"

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Set-Alias -Name cc -Value claude
    }
    if (Get-Command codex -ErrorAction SilentlyContinue) {
        Set-Alias -Name cx -Value codex
    }

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
        $starshipInit = &starship init powershell --print-full-init | Out-String
        $historyCondition = 'if ($lastCmd = Get-History -Count 1) {'
        $singleUseHistoryCondition = @'
if (($lastCmd = Get-History -Count 1) -and $lastCmd.Id -ne $script:LastHistoryId) {
            $script:LastHistoryId = $lastCmd.Id
'@

        if ($starshipInit.Contains($historyCondition)) {
            # 空命令不会进入 PowerShell 历史；避免重复显示上一条命令的耗时。
            $starshipInit = $starshipInit.Replace($historyCondition, $singleUseHistoryCondition)
        } else {
            Write-Warning "当前 Starship 初始化脚本无法应用 cmd_duration 去重补丁。"
        }

        Invoke-Expression $starshipInit
    }

    $coreutilsProfile = Join-Path $HOME ".config\powershell\coreutils.generated.ps1"
    if (Test-Path -LiteralPath $coreutilsProfile) {
        . $coreutilsProfile
    }

    if (Get-Command ls.exe -ErrorAction SilentlyContinue) {
        function global:ll { ls.exe -l --color=auto @args }
    }
}
