#!/bin/bash
# blueprint.sh — Gera plano técnico com Sonnet + todo.md com Haiku
# Uso: bash scripts/blueprint.sh

set -e

ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$SCRIPTS_DIR/scripts/lib"
PRD_FILE="$ROOT/prd.md"
BLUEPRINT_FILE="$ROOT/blueprint.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
RESEARCH_FILE="$ROOT/research.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ ! -f "$PRD_FILE" ]; then
  echo -e "${BOLD}Erro:${RESET} prd.md não encontrado."
  echo -e "${DIM}Crie o PRD primeiro: bash scripts/prd.sh \"descrição\"${RESET}"
  exit 1
fi

echo ""
echo -e "${BOLD}Gerando blueprint técnico...${RESET}"
echo -e "${DIM}Modelo: Sonnet (plano técnico com prompts por fase)${RESET}"
echo ""

# ── Monta contexto via Python (zero tokens) ───────────────────────
PROJECT_CONTEXT=""
if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/scan_project.py" ]; then
  PROJECT_CONTEXT=$(python3 "$LIB/scan_project.py" --root "$ROOT" 2>/dev/null || echo "")
fi

EXTRA_CONTEXT=""
[ -f "$CLAUDE_MD" ] && EXTRA_CONTEXT="$EXTRA_CONTEXT
$(cat "$CLAUDE_MD" | head -50)"
[ -f "$RESEARCH_FILE" ] && EXTRA_CONTEXT="$EXTRA_CONTEXT
$(cat "$RESEARCH_FILE" | head -60)"

PRD_CONTENT=$(cat "$PRD_FILE")

# ── Sonnet gera o blueprint ────────────────────────────────────────
echo -e "${YELLOW}[1/2]${RESET} Gerando blueprint com Sonnet..."

claude \
  --model claude-sonnet-4-6 \
  --print \
  --max-tokens 5000 \
  -p "Você é um engenheiro de software sênior.
Crie um blueprint técnico detalhado para implementar o PRD abaixo.

IMPORTANTE:
- Cada fase deve ter um prompt claro que o codegen.sh vai passar ao modelo
- Fases em ordem lógica de implementação (setup antes de features)
- Cada tarefa deve ser autocontida e implementável em uma sessão
- Stack deve ser a mais simples possível para o V1

$EXTRA_CONTEXT

$PROJECT_CONTEXT

PRD:
$PRD_CONTENT

ESTRUTURA OBRIGATÓRIA:

# Blueprint Técnico

## Stack
[Tecnologias escolhidas e justificativa — priorize simplicidade]

## Arquitetura
[Diagrama em texto da estrutura de arquivos e componentes principais]

## Fases de Implementação

### Fase 1: [Nome]
**Objetivo:** [O que esta fase entrega]
**Prompt de implementação:**
\`\`\`
[Prompt completo que o codegen vai usar para Sonnet implementar esta fase]
\`\`\`
**Critério de conclusão:** [Como saber que está pronto]

### Fase 2: [Nome]
[repetir estrutura...]

[Continue para todas as fases necessárias]

## Dependências Externas
[Pacotes, APIs, serviços necessários]

## Variáveis de Ambiente
[Todas as envs necessárias com descrição]" > "$BLUEPRINT_FILE"

echo -e "${GREEN}✓${RESET} Blueprint salvo"

# ── Haiku extrai todo.md do blueprint ─────────────────────────────
echo -e "${YELLOW}[2/2]${RESET} Extraindo checklist com Haiku..."

BLUEPRINT_CONTENT=$(cat "$BLUEPRINT_FILE")

claude \
  --model claude-haiku-4-5-20251001 \
  --print \
  --max-tokens 1500 \
  -p "Extraia do blueprint abaixo um todo.md com checklist de implementação.

FORMATO OBRIGATÓRIO (siga exatamente):
# todo.md

## Fase 1: [nome exato da fase 1 do blueprint]
- [ ] [tarefa 1 da fase 1]
- [ ] [tarefa 2 da fase 1]

## Fase 2: [nome exato da fase 2]
- [ ] [tarefa 1 da fase 2]

[Continue para todas as fases]

REGRAS:
- Use [ ] para pendente, [x] para concluído
- Cada tarefa deve ser ação concreta e verificável
- Uma tarefa por linha
- Não adicione comentários ou texto extra fora do formato

BLUEPRINT:
$BLUEPRINT_CONTENT" > "$ROOT/todo.md"

echo -e "${GREEN}✓${RESET} todo.md gerado"
echo ""
echo -e "${BOLD}Blueprint e checklist prontos!${RESET}"
echo ""
echo -e "  ${CYAN}blueprint.md${RESET} — plano técnico detalhado"
echo -e "  ${CYAN}todo.md${RESET}      — checklist de implementação"
echo ""
echo -e "${DIM}Próximo passo: bash scripts/codegen.sh${RESET}"
echo ""
