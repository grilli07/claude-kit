<#
.SYNOPSIS
  Atualiza manifest.json a partir do que esta instalado NESTA maquina
  (plugins de escopo user, marketplaces e skills do `npx skills`).
  Rode depois de instalar algo novo, revise o diff e faca commit/push.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\export.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Root = $PSScriptRoot
$ManifestPath = Join-Path $Root 'manifest.json'
$Manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

$Claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $Claude) { throw 'claude nao encontrado no PATH.' }

# Atribuir antes de usar no pipeline: no PS 5.1 o ConvertFrom-Json emite o array inteiro como um item so.
$pluginJson = & $Claude plugin list --json 2>$null | Out-String | ConvertFrom-Json
$marketJson = & $Claude plugin marketplace list --json 2>$null | Out-String | ConvertFrom-Json

# Plugins habilitados no escopo user (ignora os sincronizados do claude.ai, que vem com a conta)
$plugins = @($pluginJson | Where-Object { $_.scope -eq 'user' -and $_.enabled -and $_.id -notlike '*@synced' } |
  ForEach-Object { $_.id } | Sort-Object)

# Marketplaces do GitHub (os "From claude.ai" nao aparecem no --json)
$marketplaces = @($marketJson | Where-Object { $_.source -eq 'github' } | Sort-Object name |
  ForEach-Object { [ordered]@{ name = $_.name; source = $_.repo } })

# Skills do `npx skills`, agrupadas por repo. Mantem "*" onde o manifest ja usava "*".
$lockPath = Join-Path $env:USERPROFILE '.agents\.skill-lock.json'
$skillSources = @()
if (Test-Path $lockPath) {
  $lock = Get-Content $lockPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $bySource = @{}
  foreach ($prop in $lock.skills.PSObject.Properties) {
    $src = $prop.Value.source
    if (-not $bySource.ContainsKey($src)) { $bySource[$src] = New-Object System.Collections.Generic.List[string] }
    $bySource[$src].Add($prop.Name)
  }
  foreach ($src in ($bySource.Keys | Sort-Object)) {
    $old = $Manifest.skillSources | Where-Object source -eq $src
    $names = @($bySource[$src] | Sort-Object)
    $value = if ($old -and $old.skills -eq '*') { '*' } elseif ($names.Count -eq 1) { $names[0] } else { $names }
    $skillSources += [ordered]@{ source = $src; skills = $value }
  }
} else {
  Write-Warning "Nao achei $lockPath; mantendo skillSources atuais."
  $skillSources = $Manifest.skillSources
}

$out = [ordered]@{
  marketplaces = $marketplaces
  plugins      = $plugins
  skillSources = $skillSources
  skillsCli    = $Manifest.skillsCli
  extras       = $Manifest.extras
}
$json = $out | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText($ManifestPath, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Host "manifest.json atualizado: $($plugins.Count) plugins, $($marketplaces.Count) marketplaces, $($skillSources.Count) fontes de skills." -ForegroundColor Green
Write-Host 'Revise com: git diff manifest.json' -ForegroundColor DarkGray
