#!/bin/bash
# docs.sh — Geração de documentação com Sonnet
# Uso:
#   bash scripts/docs.sh . --type readme    # README do projeto
#   bash scripts/docs.sh src/ --type api    # documentação de API
#   bash scripts/docs.sh src/ --type inline # docstrings inline

set -e

TARGET="${1:-.}"
ROOT="${PROJECT_ROOT:-$(pwd)}"
CLAUDE_MD="$ROOT/CLAUDE.md"
PRD_FILE="$ROOT/prd.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

DOC_TYPE="readme"
shift
while [ "$#" -gt 0 ]; do
  case "$1" in
    --type) DOC_TYPE="$2"; shift 2 ;;
    *)      shift ;;
  esac
done

echo ""
echo -e "${BOLD}Gerando documentação:${RESET} $DOC_TYPE"
echo -e "${DIM}Target: $TARGET${RESET}"
echo ""

# ── Coleta código para documentar ────────────────────────────────
CODE_CONTENT=""
if [ -d "$ROOT/$TARGET" ] || [ -d "$TARGET" ]; then
  TARGET_PATH="$ROOT/$TARGET"
  [ -d "$TARGET" ] && TARGET_PATH="$TARGET"
  CODE_CONTENT=$(find "$TARGET_PATH" \
    -type f \
    \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" \
       -o -name "*.jsx" -o -name "*.go" -o -name "*.rs" -o -name "*.sh" \) \
    ! -path "*/node_modules/*" ! -path "*/.git/*" ! -path "*/dist/*" \
    -exec echo "=== {} ===" \; -exec head -80 {} \; 2>/dev/null | head -600)
elif [ -f "$ROOT/$TARGET" ] || [ -f "$TARGET" ]; then
  TARGET_PATH="$ROOT/$TARGET"
  [ -f "$TARGET" ] && TARGET_PATH="$TARGET"
  CODE_CONTENT=$(cat "$TARGET_PATH")
fi

# ── Contexto do projeto ───────────────────────────────────────────
PROJECT_CONTEXT=""
[ -f "$CLAUDE_MD" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
$(cat "$CLAUDE_MD" | head -40)"
[ -f "$PRD_FILE" ] && PROJECT_CONTEXT="$PROJECT_CONTEXT
$(cat "$PRD_FILE" | head -60)"

# ── Gera documentação por tipo ────────────────────────────────────
case "$DOC_TYPE" in

  readme)
    echo -e "${YELLOW}Gerando README.md...${RESET}"
    claude \
      --model claude-sonnet-4-6 \
      --print \
      --max-tokens 3000 \
      -p "Você é um dev sênior escrevendo documentação.
Crie um README.md completo e profissional para este projeto.

$PROJECT_CONTEXT

CÓDIGO DO PROJETO:
$CODE_CONTENT

ESTRUTURA DO README:
# [Nome do Projeto]

> [Tagline de 1 frase]

## O que é
[Descrição clara em 2-3 frases]

## Como usar
[Instalação e uso básico — comandos reais]

## Funcionalidades
[Lista das principais features]

## Requisitos
[Dependências necessárias]

## Contribuindo
[Como contribuir]

Escreva em português. Seja direto e prático." > "$ROOT/README.md"
    echo -e "${GREEN}✓${RESET} README.md gerado"
    ;;

  api)
    echo -e "${YELLOW}Gerando documentação de API...${RESET}"
    claude \
      --model claude-sonnet-4-6 \
      --print \
      --max-tokens 3000 \
      -p "Você é um dev sênior documentando uma API.
Crie documentação técnica clara dos endpoints/funções abaixo.

$PROJECT_CONTEXT

CÓDIGO:
$CODE_CONTENT

Para cada endpoint/função documente:
- Método + rota (para APIs REST)
- Parâmetros (tipo, obrigatório, descrição)
- Resposta (estrutura + exemplos)
- Erros possíveis

Formato Markdown. Código de exemplo quando relevante." > "$ROOT/docs/api.md"
    mkdir -p "$ROOT/docs"
    echo -e "${GREEN}✓${RESET} docs/api.md gerado"
    ;;

  inline)
    if [ -z "$CODE_CONTENT" ]; then
      echo -e "${RED}Erro:${RESET} Nenhum arquivo de código encontrado."
      exit 1
    fi
    echo -e "${YELLOW}Adicionando docstrings inline...${RESET}"
    echo -e "${DIM}Atenção: esta operação sugere modificações. Revise antes de aplicar.${RESET}"
    claude \
      --model claude-sonnet-4-6 \
      --print \
      --max-tokens 4000 \
      -p "Você é um dev sênior adicionando documentação inline.
Adicione docstrings/comentários APENAS onde a lógica não é óbvia.
Não adicione comentários triviais (ex: '# incrementa counter').

CÓDIGO:
$CODE_CONTENT

Retorne o código completo com docstrings adicionadas.
Marque cada arquivo com '=== [caminho] ===' antes do código."
    ;;

  *)
    echo -e "${RED}Tipo desconhecido:${RESET} $DOC_TYPE"
    echo -e "${DIM}Tipos disponíveis: readme, api, inline${RESET}"
    exit 1
    ;;
esac

echo ""
