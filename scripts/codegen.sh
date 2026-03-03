#!/bin/bash
# codegen.sh — Implementação iterativa com Sonnet
# Uso:
#   bash scripts/codegen.sh            # próximo item do todo.md
#   bash scripts/codegen.sh --all      # todos os itens (pausa entre fases)
#   bash scripts/codegen.sh --item 3   # item específico pelo índice

set -e

ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$SCRIPTS_DIR/scripts/lib"
TODO_FILE="$ROOT/todo.md"
BLUEPRINT_FILE="$ROOT/blueprint.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
AGENTS_FILE="$ROOT/agents.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

MODE="next"
ITEM_INDEX=""

# Parse args
while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)  MODE="all";  shift ;;
    --item) MODE="item"; ITEM_INDEX="$2"; shift 2 ;;
    *)      shift ;;
  esac
done

# ── Verifica pré-requisitos ────────────────────────────────────────
if [ ! -f "$TODO_FILE" ]; then
  echo -e "${RED}Erro:${RESET} todo.md não encontrado."
  echo -e "${DIM}Crie o blueprint primeiro: bash scripts/blueprint.sh${RESET}"
  exit 1
fi

if [ ! -f "$BLUEPRINT_FILE" ]; then
  echo -e "${RED}Erro:${RESET} blueprint.md não encontrado."
  echo -e "${DIM}Crie o blueprint primeiro: bash scripts/blueprint.sh${RESET}"
  exit 1
fi

# ── Monta contexto base (via Python se disponível) ─────────────────
build_context() {
  local TASK="$1"
  local PHASE="$2"
  local CONTEXT=""

  # CLAUDE.md (truncado)
  if [ -f "$CLAUDE_MD" ]; then
    CONTEXT="$CONTEXT
## Contexto do Projeto
$(cat "$CLAUDE_MD" | head -40)"
  fi

  # agents.md (truncado)
  if [ -f "$AGENTS_FILE" ]; then
    CONTEXT="$CONTEXT

## Lições Aprendidas
$(cat "$AGENTS_FILE" | head -30)"
  fi

  # Seção do blueprint da fase atual (via Python se disponível)
  if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/extract_context.py" ]; then
    PHASE_CONTEXT=$(python3 "$LIB/extract_context.py" \
      --blueprint "$BLUEPRINT_FILE" \
      --phase "$PHASE" \
      --root "$ROOT" 2>/dev/null || echo "")
    [ -n "$PHASE_CONTEXT" ] && CONTEXT="$CONTEXT

## Plano da Fase Atual
$PHASE_CONTEXT"
  else
    # Fallback: grep da seção do blueprint
    PHASE_CONTENT=$(awk "/^### $PHASE/,/^### /" "$BLUEPRINT_FILE" 2>/dev/null | head -40 || echo "")
    [ -n "$PHASE_CONTENT" ] && CONTEXT="$CONTEXT

## Plano da Fase Atual
$PHASE_CONTENT"
  fi

  echo "$CONTEXT"
}

# ── Implementa um item ─────────────────────────────────────────────
implement_item() {
  local TASK="$1"
  local PHASE="$2"
  local INDEX="$3"

  echo ""
  echo -e "${BOLD}Implementando:${RESET} $TASK"
  echo -e "${DIM}Fase: $PHASE${RESET}"
  echo ""

  CONTEXT=$(build_context "$TASK" "$PHASE")

  # Scan do projeto (via Python se disponível)
  PROJECT_SCAN=""
  if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/scan_project.py" ]; then
    PROJECT_SCAN=$(python3 "$LIB/scan_project.py" --root "$ROOT" --task "$TASK" 2>/dev/null || echo "")
  fi

  # Sonnet implementa
  claude \
    --model claude-sonnet-4-6 \
    --print \
    -p "Você é um engenheiro de software. Implemente a tarefa abaixo.

TAREFA: $TASK
FASE: $PHASE

$CONTEXT

$PROJECT_SCAN

INSTRUÇÕES:
- Escreva o código completo, não apenas snippets
- Crie ou modifique os arquivos necessários
- Siga os padrões já estabelecidos no projeto
- Adicione comentários apenas onde a lógica não for óbvia
- Código funcional — evite TODOs no V1
- Ao final, liste os arquivos criados/modificados" \
    --output-format text

  # Marca como concluído no todo.md
  if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/todo_manager.py" ]; then
    python3 "$LIB/todo_manager.py" complete --root "$ROOT" --index "$INDEX" 2>/dev/null || true
  else
    # Fallback: sed para marcar o item
    sed -i "0,/- \[ \] $(echo "$TASK" | sed 's/[[\.*^$()+?{|]/\\&/g')/{s/- \[ \]/- [x]/}" "$TODO_FILE" 2>/dev/null || true
  fi

  echo ""
  echo -e "${GREEN}✓${RESET} Tarefa concluída e marcada no todo.md"
}

# ── Modo: próximo item ─────────────────────────────────────────────
if [ "$MODE" = "next" ] || [ "$MODE" = "item" ]; then
  if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/todo_manager.py" ]; then
    if [ "$MODE" = "item" ]; then
      NEXT=$(python3 "$LIB/todo_manager.py" get --root "$ROOT" --index "$ITEM_INDEX" 2>/dev/null || echo "")
    else
      NEXT=$(python3 "$LIB/todo_manager.py" next --root "$ROOT" 2>/dev/null || echo "")
    fi
    TASK=$(echo "$NEXT" | grep "^TASK:" | sed 's/^TASK: //')
    PHASE=$(echo "$NEXT" | grep "^PHASE:" | sed 's/^PHASE: //')
    INDEX=$(echo "$NEXT" | grep "^INDEX:" | sed 's/^INDEX: //')
  else
    # Fallback: lê o primeiro [ ] do todo.md
    NEXT_LINE=$(grep -n "- \[ \]" "$TODO_FILE" | head -1)
    INDEX=$(echo "$NEXT_LINE" | cut -d: -f1)
    TASK=$(echo "$NEXT_LINE" | sed 's/.*- \[ \] //')
    PHASE=$(awk "NR<$INDEX && /^## /" "$TODO_FILE" | tail -1 | sed 's/^## //')
  fi

  if [ -z "$TASK" ]; then
    echo ""
    echo -e "${GREEN}${BOLD}Todos os itens do todo.md foram concluídos!${RESET}"
    echo ""
    echo -e "${DIM}Próximos passos:${RESET}"
    echo -e "  • Revisar: ${CYAN}bash scripts/review.sh .${RESET}"
    echo -e "  • Documentar: ${CYAN}bash scripts/docs.sh . --type readme${RESET}"
    exit 0
  fi

  implement_item "$TASK" "$PHASE" "$INDEX"

# ── Modo: todos os itens ───────────────────────────────────────────
elif [ "$MODE" = "all" ]; then
  CURRENT_PHASE=""

  while true; do
    if command -v python3 >/dev/null 2>&1 && [ -f "$LIB/todo_manager.py" ]; then
      NEXT=$(python3 "$LIB/todo_manager.py" next --root "$ROOT" 2>/dev/null || echo "ALL_DONE")
    else
      NEXT_LINE=$(grep -n "- \[ \]" "$TODO_FILE" | head -1)
      if [ -z "$NEXT_LINE" ]; then
        NEXT="ALL_DONE"
      else
        INDEX=$(echo "$NEXT_LINE" | cut -d: -f1)
        TASK=$(echo "$NEXT_LINE" | sed 's/.*- \[ \] //')
        PHASE=$(awk "NR<$INDEX && /^## /" "$TODO_FILE" | tail -1 | sed 's/^## //')
        NEXT="TASK: $TASK
PHASE: $PHASE
INDEX: $INDEX"
      fi
    fi

    if echo "$NEXT" | grep -q "ALL_DONE"; then
      echo ""
      echo -e "${GREEN}${BOLD}Implementacao concluida!${RESET}"
      echo ""
      echo -e "${DIM}Próximos passos:${RESET}"
      echo -e "  • Revisar: ${CYAN}bash scripts/review.sh .${RESET}"
      echo -e "  • Documentar: ${CYAN}bash scripts/docs.sh . --type readme${RESET}"
      break
    fi

    TASK=$(echo "$NEXT" | grep "^TASK:" | sed 's/^TASK: //')
    PHASE=$(echo "$NEXT" | grep "^PHASE:" | sed 's/^PHASE: //')
    INDEX=$(echo "$NEXT" | grep "^INDEX:" | sed 's/^INDEX: //')

    # Pausa entre fases
    if [ -n "$PHASE" ] && [ "$PHASE" != "$CURRENT_PHASE" ]; then
      if [ -n "$CURRENT_PHASE" ]; then
        echo ""
        echo -e "${DIM}Fase anterior concluida. Pressione Enter para iniciar: ${BOLD}$PHASE${RESET}"
        read -r
      fi
      echo ""
      echo -e "${BOLD}=== Iniciando Fase: $PHASE ===${RESET}"
      CURRENT_PHASE="$PHASE"
    fi

    implement_item "$TASK" "$PHASE" "$INDEX"
  done
fi
