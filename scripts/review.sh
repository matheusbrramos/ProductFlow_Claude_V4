#!/bin/bash
# review.sh — Revisão de código com Sonnet (Opus se --deep + críticos)
# Uso:
#   bash scripts/review.sh .                  # revisão geral (Sonnet)
#   bash scripts/review.sh src/auth/          # pasta específica
#   bash scripts/review.sh src/api.py --deep  # escalada para Opus se críticos

set -e

TARGET="${1:-.}"
ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$SCRIPTS_DIR/scripts/lib"
AGENTS_FILE="$ROOT/agents.md"
CLAUDE_MD="$ROOT/CLAUDE.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

DEEP=false
[ "$2" = "--deep" ] && DEEP=true

# ── Coleta código para revisão ─────────────────────────────────────
echo ""
echo -e "${BOLD}Revisando:${RESET} $TARGET"
echo -e "${DIM}Modelo: Sonnet${RESET}$([ "$DEEP" = true ] && echo -e " ${DIM}(escalada para Opus se críticos encontrados)${RESET}")"
echo ""

CODE_CONTENT=""
if [ -d "$ROOT/$TARGET" ] || [ -d "$TARGET" ]; then
  TARGET_PATH="$ROOT/$TARGET"
  [ -d "$TARGET" ] && TARGET_PATH="$TARGET"
  CODE_CONTENT=$(find "$TARGET_PATH" \
    -type f \
    \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" \
       -o -name "*.jsx" -o -name "*.sh" -o -name "*.go" -o -name "*.rs" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
    -exec echo "=== {} ===" \; -exec head -100 {} \; 2>/dev/null | head -500)
elif [ -f "$ROOT/$TARGET" ] || [ -f "$TARGET" ]; then
  TARGET_PATH="$ROOT/$TARGET"
  [ -f "$TARGET" ] && TARGET_PATH="$TARGET"
  CODE_CONTENT=$(cat "$TARGET_PATH")
else
  echo -e "${RED}Erro:${RESET} Target '$TARGET' não encontrado."
  exit 1
fi

if [ -z "$CODE_CONTENT" ]; then
  echo -e "${DIM}Nenhum arquivo de código encontrado em $TARGET${RESET}"
  exit 0
fi

# ── Contexto adicional ─────────────────────────────────────────────
EXTRA_CONTEXT=""
[ -f "$CLAUDE_MD" ] && EXTRA_CONTEXT="$EXTRA_CONTEXT
$(cat "$CLAUDE_MD" | head -30)"
[ -f "$AGENTS_FILE" ] && EXTRA_CONTEXT="$EXTRA_CONTEXT

Lições aprendidas anteriores:
$(cat "$AGENTS_FILE" | head -40)"

# ── Revisão com Sonnet ─────────────────────────────────────────────
echo -e "${YELLOW}[1/2]${RESET} Analisando código com Sonnet..."

REVIEW=$(claude \
  --model claude-sonnet-4-6 \
  --print \
  --max-tokens 3000 \
  -p "Você é um engenheiro sênior fazendo code review. Analise o código abaixo.

$EXTRA_CONTEXT

CÓDIGO:
$CODE_CONTENT

ESTRUTURA DA REVISÃO:

## Resumo
[2-3 linhas: qualidade geral e principais observações]

## Problemas CRÍTICOS
[Bugs, vulnerabilidades de segurança, falhas de lógica — se não houver, escreva: Nenhum]

## Problemas IMPORTANTES
[Performance, má práticas, código frágil]

## Sugestões
[Melhorias desejáveis mas não urgentes]

## Lições para agents.md
[1-3 padrões ou armadilhas descobertas que devem ser lembradas]

Seja direto. Cite linha/arquivo quando relevante.")

echo "$REVIEW"
echo ""

# ── Escalada para Opus (só se --deep + críticos) ───────────────────
if [ "$DEEP" = true ]; then
  HAS_CRITICAL=$(echo "$REVIEW" | grep -A5 "## Problemas CRÍTICOS" | grep -v "Nenhum" | grep -v "^$" | grep -v "##" | head -1)

  if [ -n "$HAS_CRITICAL" ]; then
    echo -e "${YELLOW}[CRÍTICO]${RESET} Problemas críticos detectados. Escalando para Opus..."
    echo ""

    claude \
      --model claude-opus-4-6 \
      --print \
      --max-tokens 3000 \
      -p "Você é um engenheiro principal fazendo revisão profunda. Foco nos problemas CRÍTICOS identificados.

REVISÃO ANTERIOR (Sonnet):
$REVIEW

CÓDIGO:
$CODE_CONTENT

Analise os problemas críticos em detalhe:
1. Confirme se são realmente críticos
2. Explique a causa raiz
3. Forneça solução específica com código
4. Avalie se há outros problemas críticos não identificados"
  else
    echo -e "${DIM}Nenhum problema crítico — escalada Opus não necessária.${RESET}"
  fi
fi

# ── Atualiza agents.md com lições aprendidas ──────────────────────
echo ""
echo -e "${YELLOW}[2/2]${RESET} Atualizando agents.md..."

LESSONS=$(echo "$REVIEW" | awk '/## Lições para agents.md/,0' | grep -v "^##" | grep -v "^$" | head -5)

if [ -n "$LESSONS" ] && [ -f "$AGENTS_FILE" ]; then
  {
    echo ""
    echo "## Revisão $(date '+%d/%m/%Y') — $TARGET"
    echo "$LESSONS"
  } >> "$AGENTS_FILE"
  echo -e "${GREEN}✓${RESET} agents.md atualizado com lições da revisão"
elif [ -n "$LESSONS" ]; then
  cat > "$AGENTS_FILE" << AGENTSMD
# agents.md — Lições Aprendidas

> Gerado automaticamente pelo review.sh

## Revisão $(date '+%d/%m/%Y') — $TARGET
$LESSONS
AGENTSMD
  echo -e "${GREEN}✓${RESET} agents.md criado com lições da revisão"
fi

echo ""
