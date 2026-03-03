#!/bin/bash
# research.sh — Pesquisa técnica com triagem Haiku + Sonnet
# Uso: bash scripts/research.sh "tema a pesquisar"

set -e

TOPIC="${1:-}"
ROOT="${PROJECT_ROOT:-$(pwd)}"
RESEARCH_FILE="$ROOT/research.md"
AGENTS_FILE="$ROOT/agents.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ -z "$TOPIC" ]; then
  echo -e "${BOLD}Uso:${RESET} bash scripts/research.sh \"tema a pesquisar\""
  exit 1
fi

echo ""
echo -e "${BOLD}Pesquisando:${RESET} $TOPIC"
echo ""

# ── Haiku verifica se o tema já está documentado ──────────────────
if [ -f "$RESEARCH_FILE" ] || [ -f "$AGENTS_FILE" ]; then
  EXISTING_CONTEXT=""
  [ -f "$RESEARCH_FILE" ] && EXISTING_CONTEXT="$EXISTING_CONTEXT
$(cat "$RESEARCH_FILE" | head -80)"
  [ -f "$AGENTS_FILE" ] && EXISTING_CONTEXT="$EXISTING_CONTEXT
$(cat "$AGENTS_FILE" | head -40)"

  ALREADY_COVERED=$(echo "$EXISTING_CONTEXT" | claude \
    --model claude-haiku-4-5-20251001 \
    --print \
    --max-tokens 80 \
    -p "O tema abaixo já está documentado nos arquivos existentes? Responda apenas: SIM ou NAO.

TEMA: $TOPIC

ARQUIVOS EXISTENTES:
$EXISTING_CONTEXT")

  if echo "$ALREADY_COVERED" | grep -qi "^SIM"; then
    echo -e "${DIM}Tema já documentado nos arquivos existentes. Nenhuma nova pesquisa necessária.${RESET}"
    echo ""
    echo -e "${DIM}Para ver o conteúdo existente: cat research.md${RESET}"
    exit 0
  fi
fi

# ── Sonnet realiza a pesquisa ──────────────────────────────────────
echo -e "${YELLOW}[1/2]${RESET} Pesquisando com Sonnet..."

RESEARCH_CONTENT=$(claude \
  --model claude-sonnet-4-6 \
  --print \
  --max-tokens 2000 \
  -p "Você é um engenheiro sênior fazendo pesquisa técnica.
Pesquise o tema abaixo com foco prático — o que o dev precisa saber para implementar.

TEMA: $TOPIC

ESTRUTURA DA RESPOSTA:
## $TOPIC

### O que é
[Definição concisa]

### Quando usar
[Casos de uso reais]

### Como implementar
[Passos práticos, código de exemplo quando relevante]

### Armadilhas comuns
[O que evitar, erros típicos]

### Referências
[Links ou padrões relevantes]

---
Resposta focada no essencial. Sem redundância.")

# ── Salva ou atualiza research.md ─────────────────────────────────
echo -e "${YELLOW}[2/2]${RESET} Salvando pesquisa..."

if [ ! -f "$RESEARCH_FILE" ]; then
  cat > "$RESEARCH_FILE" << HEADER
# research.md — Base de Conhecimento Técnico

> Gerado automaticamente. Atualizado pelo research.sh.

HEADER
fi

# Adiciona nova seção com separador e data
{
  echo ""
  echo "---"
  echo "> Pesquisado em: $(date '+%d/%m/%Y')"
  echo ""
  echo "$RESEARCH_CONTENT"
} >> "$RESEARCH_FILE"

echo ""
echo -e "${GREEN}✓${RESET} Pesquisa salva em ${CYAN}research.md${RESET}"
echo ""
