# install.ps1
# Instala o sistema de agentes no projeto atual.
# Uso: .\install.ps1 [-Project "caminho\do\projeto"]

param(
    [string]$Project = (Get-Location).Path
)

$SystemDir = $PSScriptRoot

Write-Host ""
Write-Host "Instalando sistema de agentes em: $Project" -ForegroundColor Cyan
Write-Host "-----------------------------------" -ForegroundColor DarkGray

# Verifica dependencias
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: Claude Code CLI nao encontrado." -ForegroundColor Red
    Write-Host "Instale com: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command python -ErrorAction SilentlyContinue) -and
    -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: Python 3 nao encontrado. Instale em https://python.org" -ForegroundColor Red
    exit 1
}

# Cria estrutura no projeto
New-Item -ItemType Directory -Force -Path "$Project\scripts\lib" | Out-Null
New-Item -ItemType Directory -Force -Path "$Project\docs"         | Out-Null

# Copia helper principal
if (Test-Path "$SystemDir\start.sh") {
    Copy-Item "$SystemDir\start.sh" "$Project\" -Force
} else {
    Write-Host "[ERRO] start.sh nao encontrado em: $SystemDir" -ForegroundColor Red
    exit 1
}

# Copia scripts
$scripts = @("research.sh","prd.sh","blueprint.sh","codegen.sh","review.sh","docs.sh")
$scriptsCopied = 0
foreach ($s in $scripts) {
    if (Test-Path "$SystemDir\scripts\$s") {
        Copy-Item "$SystemDir\scripts\$s" "$Project\scripts\" -Force
        $scriptsCopied++
    } else {
        Write-Host "[AVISO] Script nao encontrado: $s" -ForegroundColor Yellow
    }
}

# Copia libs Python
$libs = @("scan_project.py","todo_manager.py","extract_context.py")
$libsCopied = 0
foreach ($l in $libs) {
    if (Test-Path "$SystemDir\scripts\lib\$l") {
        Copy-Item "$SystemDir\scripts\lib\$l" "$Project\scripts\lib\" -Force
        $libsCopied++
    } else {
        Write-Host "[AVISO] Lib nao encontrada: $l" -ForegroundColor Yellow
    }
}

# Copia templates se nao existirem
if (Test-Path "$SystemDir\templates\CLAUDE.md") {
    if (-not (Test-Path "$Project\CLAUDE.md")) { Copy-Item "$SystemDir\templates\CLAUDE.md" "$Project\" }
} else {
    Write-Host "[AVISO] Template CLAUDE.md nao encontrado." -ForegroundColor Yellow
}
if (Test-Path "$SystemDir\templates\agents.md") {
    if (-not (Test-Path "$Project\agents.md")) { Copy-Item "$SystemDir\templates\agents.md" "$Project\" }
} else {
    Write-Host "[AVISO] Template agents.md nao encontrado." -ForegroundColor Yellow
}

# Valida instalacao
if ($scriptsCopied -eq 0 -or $libsCopied -eq 0) {
    Write-Host ""
    Write-Host "[ERRO] Instalacao incompleta!" -ForegroundColor Red
    Write-Host "  scripts copiados: $scriptsCopied/6" -ForegroundColor Yellow
    Write-Host "  libs copiadas:    $libsCopied/3" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Instalado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "-----------------------------------" -ForegroundColor DarkGray
Write-Host "PARA COMECAR:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   bash start.sh" -ForegroundColor White
Write-Host ""
Write-Host "   O assistente vai te guiar por tudo." -ForegroundColor Gray
Write-Host "   Nao precisa saber de tecnologia!" -ForegroundColor Gray
Write-Host "-----------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "FLUXO MANUAL (para devs):" -ForegroundColor Cyan
Write-Host ""
Write-Host "  bash scripts/research.sh 'tema relevante'"
Write-Host "  bash scripts/prd.sh 'descricao do produto'"
Write-Host "  bash scripts/blueprint.sh"
Write-Host "  bash scripts/codegen.sh [--all]"
Write-Host "  bash scripts/review.sh ."
Write-Host "  bash scripts/docs.sh . --type readme"
Write-Host ""
Write-Host "-----------------------------------" -ForegroundColor DarkGray
Write-Host "Modelos utilizados:"
Write-Host "  Haiku  -> entrevista, triagem, todo.md  (minimo custo)"
Write-Host "  Sonnet -> blueprint, codegen, review    (padrao)"
Write-Host "  Opus   -> PRD                           (cirurgico)"
Write-Host "-----------------------------------" -ForegroundColor DarkGray
Write-Host ""
