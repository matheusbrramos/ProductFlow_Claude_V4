# setup.ps1
# Execute este script de dentro da pasta do seu projeto.
# Ele baixa e instala o PM Builder automaticamente.
#
# Como usar (dentro da pasta do projeto):
#   iex (iwr "https://raw.githubusercontent.com/matheusbrramos/ProductFlow_Claude_V4/main/setup.ps1" -UseBasicParsing).Content

$ProjectDir = (Get-Location).Path
$TempDir    = "$env:TEMP\pmbuilder_$(Get-Random)"
$RepoUrl    = "https://github.com/matheusbrramos/ProductFlow_Claude_V4.git"

Write-Host ""
Write-Host "PM Builder — Instalador" -ForegroundColor Cyan
Write-Host "Pasta do projeto: $ProjectDir" -ForegroundColor Gray
Write-Host ""

# Verifica Claude Code CLI
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Claude Code CLI nao encontrado." -ForegroundColor Red
    Write-Host "       Instale com: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verifica Python
$python = if (Get-Command python -ErrorAction SilentlyContinue) { "python" }
          elseif (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
          else { $null }

if (-not $python) {
    Write-Host "[ERRO] Python 3 nao encontrado." -ForegroundColor Red
    Write-Host "       Instale em: https://python.org/downloads" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verifica Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Git nao encontrado." -ForegroundColor Red
    Write-Host "       Instale em: https://gitforwindows.org" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "[1/3] Baixando PM Builder..." -ForegroundColor White
git clone --quiet $RepoUrl $TempDir
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao baixar. Verifique sua conexao." -ForegroundColor Red
    exit 1
}

Write-Host "[2/3] Instalando na pasta atual..." -ForegroundColor White

# Cria estrutura de pastas
New-Item -ItemType Directory -Force -Path "$ProjectDir\scripts\lib" | Out-Null
New-Item -ItemType Directory -Force -Path "$ProjectDir\docs"         | Out-Null

# Copia arquivo principal
Copy-Item "$TempDir\start.sh" "$ProjectDir\" -Force

# Copia scripts
$scripts = @("research.sh","prd.sh","blueprint.sh","codegen.sh","review.sh","docs.sh")
foreach ($s in $scripts) {
    if (Test-Path "$TempDir\scripts\$s") {
        Copy-Item "$TempDir\scripts\$s" "$ProjectDir\scripts\" -Force
    }
}

# Copia libs Python
$libs = @("scan_project.py","todo_manager.py","extract_context.py")
foreach ($l in $libs) {
    if (Test-Path "$TempDir\scripts\lib\$l") {
        Copy-Item "$TempDir\scripts\lib\$l" "$ProjectDir\scripts\lib\" -Force
    }
}

# Copia templates (apenas se ainda nao existirem)
if (Test-Path "$TempDir\templates\CLAUDE.md") {
    if (-not (Test-Path "$ProjectDir\CLAUDE.md")) {
        Copy-Item "$TempDir\templates\CLAUDE.md" "$ProjectDir\"
    }
}
if (Test-Path "$TempDir\templates\agents.md") {
    if (-not (Test-Path "$ProjectDir\agents.md")) {
        Copy-Item "$TempDir\templates\agents.md" "$ProjectDir\"
    }
}

Write-Host "[3/3] Limpando arquivos temporarios..." -ForegroundColor White
Remove-Item $TempDir -Recurse -Force

Write-Host ""
Write-Host "Instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Para comecar, abra o Git Bash nesta pasta e rode:" -ForegroundColor Cyan
Write-Host "   bash start.sh" -ForegroundColor White
Write-Host ""
