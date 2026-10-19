# Applies a Windhawk mod settings JSON to the registry and makes the mod reload.
# Usage (elevated):  .\apply-theme.ps1 -Mod windows-11-taskbar-styler -Json .\taskbar-royale.json
#                    .\apply-theme.ps1 -Watch   (keeps applying taskbar-royale.json / startmenu-royale.json on change)
param(
    [string]$Mod,
    [string]$Json,
    [switch]$Watch
)

$ErrorActionPreference = 'Stop'
$root = 'HKLM:\SOFTWARE\Windhawk\Engine\Mods'
$log = Join-Path $PSScriptRoot 'apply.log'

function Write-Log($msg) {
    $line = "$(Get-Date -Format 'HH:mm:ss') $msg"
    Write-Host $line
    Add-Content -Path $log -Value $line -Encoding utf8
}

# Flattens JSON into Windhawk's registry naming: a.b, list[0], list[0].field
function Add-Flat($prefix, $node, [hashtable]$out) {
    if ($node -is [System.Array]) {
        for ($i = 0; $i -lt $node.Count; $i++) { Add-Flat "$prefix[$i]" $node[$i] $out }
    } elseif ($node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($p in $node.PSObject.Properties) {
            $key = if ($prefix) { "$prefix.$($p.Name)" } else { $p.Name }
            Add-Flat $key $p.Value $out
        }
    } else {
        $out[$prefix] = $node
    }
}

function Apply-Settings($modId, $jsonPath) {
    $data = Get-Content -Raw -Encoding utf8 $jsonPath | ConvertFrom-Json
    $flat = @{}
    Add-Flat '' $data $flat

    $modKey = Join-Path $root $modId
    if (-not (Test-Path $modKey)) { throw "Mod not installed: $modId" }
    $settingsKey = Join-Path $modKey 'Settings'
    if (Test-Path $settingsKey) { Remove-Item $settingsKey -Recurse -Force }
    New-Item $settingsKey -Force | Out-Null

    foreach ($k in $flat.Keys) {
        $v = $flat[$k]
        if ($v -is [bool]) { $v = [int]$v }
        if ($v -is [int] -or $v -is [long]) {
            New-ItemProperty $settingsKey -Name $k -Value ([int]$v) -PropertyType DWord -Force | Out-Null
        } else {
            New-ItemProperty $settingsKey -Name $k -Value ([string]$v) -PropertyType String -Force | Out-Null
        }
    }

    $now = [int][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    Set-ItemProperty $modKey -Name SettingsChangeTime -Value $now -Type DWord
    Write-Log "Applied $($flat.Count) values to $modId from $(Split-Path $jsonPath -Leaf)"
}

if ($Watch) {
    $targets = @{
        (Join-Path $PSScriptRoot 'taskbar-royale.json')   = 'windows-11-taskbar-styler'
        (Join-Path $PSScriptRoot 'startmenu-royale.json') = 'windows-11-start-menu-styler'
    }
    $seen = @{}
    # Creating this file asks the elevated watcher to reset Windows Search / SearchHost
    # (needed after live webContentStyles changes, which leave search results blank).
    $resetFlag = Join-Path $PSScriptRoot 'reset-search.flag'
    Write-Log 'Watcher started'
    while ($true) {
        if (Test-Path $resetFlag) {
            Remove-Item $resetFlag -Force
            try { & (Join-Path $PSScriptRoot 'reset-search.ps1'); Write-Log 'Reset Windows Search and SearchHost' }
            catch { Write-Log "ERROR reset: $_" }
        }
        foreach ($f in $targets.Keys) {
            if (-not (Test-Path $f)) { continue }
            $t = (Get-Item $f).LastWriteTimeUtc
            if ($seen[$f] -ne $t) {
                $seen[$f] = $t
                try { Apply-Settings $targets[$f] $f } catch { Write-Log "ERROR $f : $_" }
            }
        }
        Start-Sleep -Milliseconds 700
    }
} else {
    Apply-Settings $Mod (Resolve-Path $Json)
}
