<#
.SYNOPSIS
  Instala o mesmo conjunto de plugins, skills e regras (CLAUDE.md) do Claude Code
  descrito em manifest.json. Idempotente: pode rodar de novo para atualizar.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkipRea -ConfigDir "$env:USERPROFILE\.claude-work"
#>
[CmdletBinding()]
param(
  # Pasta de config do Claude Code (padrao: ~/.claude). Use se o agente do trabalho tiver CLAUDE_CONFIG_DIR proprio.
  [string]$ConfigDir,
  # Nao instala o REA (MCP rea-agents + skill reverse-engineer-anything).
  [switch]$SkipRea,
  # Nao mexe no CLAUDE.md global.
  [switch]$NoClaudeMd,
  # So mostra o que seria feito.
  [switch]$DryRun
)

# 'Continue': no Windows PowerShell 5.1, stderr de executavel nativo com 'Stop' vira erro fatal.
$ErrorActionPreference = 'Continue'
$Root = $PSScriptRoot
$Manifest = Get-Content (Join-Path $Root 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'Precisa do PowerShell 5.1 ou superior.' }
$Failures = New-Object System.Collections.Generic.List[string]

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    ok  $msg" -ForegroundColor Green }
function Write-Skip($msg) { Write-Host "    --  $msg" -ForegroundColor DarkGray }
function Write-Bad($msg)  { Write-Host "    !!  $msg" -ForegroundColor Yellow; $Failures.Add($msg) }

# Roda um executavel externo; em -DryRun so imprime. Retorna $true se exit code 0.
function Invoke-Native([string]$exe, [string[]]$argv, [string]$label) {
  if ($DryRun) { Write-Host "    [dry-run] $exe $($argv -join ' ')"; return $true }
  & $exe @argv 2>&1 | ForEach-Object { Write-Host "        $_" -ForegroundColor DarkGray }
  if ($LASTEXITCODE -ne 0) { Write-Bad "$label (exit $LASTEXITCODE)"; return $false }
  Write-Ok $label
  return $true
}

# --- Pre-requisitos -----------------------------------------------------------
Write-Step 'Verificando pre-requisitos'

$Claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $Claude) {
  # Fallback: binario que o Claude Desktop baixa em %APPDATA%\Claude*\claude-code\<versao>\<hash>\claude.exe
  $Claude = Get-ChildItem "$env:APPDATA\Claude*\claude-code\*\*\claude.exe" -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.Directory.Parent.Name -replace '[^0-9.]', '') } -Descending |
    Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Claude) { throw 'Claude Code nao encontrado. Instale o CLI (https://docs.claude.com/en/docs/claude-code/setup) ou abra o Code tab do Claude Desktop uma vez.' }
Write-Ok "claude: $Claude"

$Npx = (Get-Command npx -ErrorAction SilentlyContinue).Source
if (-not $Npx) { throw 'npx nao encontrado. Instale o Node.js LTS (winget install OpenJS.NodeJS.LTS) e abra um terminal novo.' }
Write-Ok "npx: $Npx"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git nao encontrado (winget install Git.Git).' }
Write-Ok 'git'

if ($ConfigDir) {
  $ClaudeHome = [IO.Path]::GetFullPath($ConfigDir)
  $env:CLAUDE_CONFIG_DIR = $ClaudeHome
  Write-Ok "CLAUDE_CONFIG_DIR = $ClaudeHome"
} elseif ($env:CLAUDE_CONFIG_DIR) {
  $ClaudeHome = $env:CLAUDE_CONFIG_DIR
  Write-Ok "CLAUDE_CONFIG_DIR (do ambiente) = $ClaudeHome"
} else {
  $ClaudeHome = Join-Path $env:USERPROFILE '.claude'
}
if (-not $DryRun) { New-Item -ItemType Directory -Force -Path (Join-Path $ClaudeHome 'skills') | Out-Null }

# --- Marketplaces -------------------------------------------------------------
Write-Step 'Marketplaces de plugins'
# Atribuir antes de usar no pipeline: no PS 5.1 o ConvertFrom-Json emite o array inteiro como um item so.
$mkJson = & $Claude plugin marketplace list --json 2>$null | Out-String | ConvertFrom-Json
$mkNames = @($mkJson | ForEach-Object { $_.name })
foreach ($m in $Manifest.marketplaces) {
  if ($mkNames -contains $m.name) { Write-Skip "$($m.name) ja configurado"; continue }
  # "Clone succeeded, but checkout failed" = caminho > 260 chars: use uma pasta de config curta
  # ou habilite caminhos longos (git config --global core.longpaths true).
  Invoke-Native $Claude @('plugin', 'marketplace', 'add', $m.source) "marketplace $($m.name)" | Out-Null
}

# --- Plugins ------------------------------------------------------------------
Write-Step 'Plugins'
$plJson = & $Claude plugin list --json 2>$null | Out-String | ConvertFrom-Json
$plIds = @($plJson | ForEach-Object { $_.id })
foreach ($p in $Manifest.plugins) {
  if ($plIds -contains $p) { Write-Skip "$p ja instalado"; continue }
  Invoke-Native $Claude @('plugin', 'install', $p) $p | Out-Null
}

# --- Skills via npx skills ----------------------------------------------------
Write-Step 'Skills (npx skills)'
# --copy: copia em vez de symlink (symlink no Windows pode exigir modo desenvolvedor)
foreach ($s in $Manifest.skillSources) {
  # "skills" pode ser "*" (todas do repo) ou uma lista de nomes
  $argv = @('-y', $Manifest.skillsCli, 'add', $s.source, '-g', '-y', '-a', 'claude-code', '--copy', '--skill') + @($s.skills)
  # o CLI respeita CLAUDE_CONFIG_DIR, entao -ConfigDir tambem vale aqui
  Invoke-Native $Npx $argv "skills de $($s.source)" | Out-Null
}

# --- Skills proprias (pasta skills/ deste repo) ------------------------------
Write-Step 'Skills proprias (skills/)'
$rea = $Manifest.extras.rea
$skillsDst = Join-Path $ClaudeHome 'skills'
Get-ChildItem (Join-Path $Root 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object {
  if ($SkipRea -and $_.Name -eq $rea.skillName) { Write-Skip "$($_.Name) pulada (-SkipRea)"; return }
  if ($DryRun) { Write-Host "    [dry-run] copiar skills\$($_.Name) -> $skillsDst"; return }
  Copy-Item $_.FullName $skillsDst -Recurse -Force
  Write-Ok $_.Name
}

# --- MCP do REA (opcional) ----------------------------------------------------
if ($SkipRea) {
  Write-Step 'MCP do REA'; Write-Skip 'pulado (-SkipRea)'
} else {
  Write-Step 'MCP do REA (reverse-engineer-anything)'
  & $Claude mcp get $rea.mcpName *> $null
  if ($LASTEXITCODE -eq 0) { Write-Skip "MCP $($rea.mcpName) ja existe" }
  else { Invoke-Native $Claude (@('mcp', 'add', $rea.mcpName, '-s', 'user', '--') + $rea.mcpCommand) "MCP $($rea.mcpName)" | Out-Null }
}

# --- CLAUDE.md global (bloco entre marcadores) -------------------------------
if ($NoClaudeMd) {
  Write-Step 'CLAUDE.md'; Write-Skip 'pulado (-NoClaudeMd)'
} else {
  Write-Step 'CLAUDE.md global'
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  # Tudo normalizado para LF: o checkout do git pode trazer CRLF e isso nao e mudanca de verdade.
  $block = [IO.File]::ReadAllText((Join-Path $Root 'CLAUDE.md'), $utf8).Replace("`r`n", "`n").Trim()
  $target = Join-Path $ClaudeHome 'CLAUDE.md'
  $pattern = '(?s)<!-- claude-kit:begin.*?<!-- claude-kit:end -->'
  if (Test-Path $target) {
    $current = [IO.File]::ReadAllText($target, $utf8).Replace("`r`n", "`n")
    if ($current -match $pattern) { $new = [regex]::Replace($current, $pattern, { param($m) $block }) }
    else { $new = $current.TrimEnd() + "`n`n" + $block + "`n" }
  } else {
    $current = $null
    $new = $block + "`n"
  }
  if ($current -eq $new) { Write-Skip 'ja atualizado' }
  elseif ($DryRun) { Write-Host "    [dry-run] gravar bloco claude-kit em $target" }
  else {
    if ($current) { Copy-Item $target "$target.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"; Write-Ok 'backup do CLAUDE.md anterior' }
    [IO.File]::WriteAllText($target, $new, $utf8)
    Write-Ok "regras gravadas em $target"
  }
}

# --- Resumo -------------------------------------------------------------------
Write-Step 'Resumo'
if ($Failures.Count) {
  Write-Host "Terminou com $($Failures.Count) falha(s):" -ForegroundColor Yellow
  $Failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
  exit 1
}
Write-Host 'Tudo certo. Abra uma sessao nova do Claude Code (ou rode /reload-plugins) para carregar.' -ForegroundColor Green
