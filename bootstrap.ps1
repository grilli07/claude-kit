# Baixa (ou atualiza) o claude-kit e roda o instalador.
# Uso, numa janela do PowerShell:
#   irm https://raw.githubusercontent.com/grilli07/claude-kit/main/bootstrap.ps1 | iex
# Pasta destino: $env:CLAUDE_KIT_DIR, ou ~/claude-kit se nao definida.

$ErrorActionPreference = 'Continue'
$repo = 'https://github.com/grilli07/claude-kit.git'
$dir = if ($env:CLAUDE_KIT_DIR) { $env:CLAUDE_KIT_DIR } else { Join-Path $env:USERPROFILE 'claude-kit' }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'git nao encontrado. Instale com: winget install Git.Git' -ForegroundColor Yellow
  return
}

if (Test-Path (Join-Path $dir '.git')) {
  Write-Host "==> Atualizando $dir" -ForegroundColor Cyan
  git -C $dir pull --ff-only
} else {
  Write-Host "==> Clonando em $dir" -ForegroundColor Cyan
  git clone $repo $dir
}
if ($LASTEXITCODE -ne 0) { Write-Host 'Falha no git; nada foi instalado.' -ForegroundColor Yellow; return }

# Processo filho com Bypass: a politica padrao do Windows bloqueia rodar .ps1 baixado.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'install.ps1')
