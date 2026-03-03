#!/bin/bash
# prd.sh — Gera Product Requirements Document com Opus
# Uso: bash scripts/prd.sh "descrição do produto ou feature"

set -e

DESCRIPTION="${1:-}"
ROOT="${PROJECT_ROOT:-$(pwd)}"
PRD_FILE="$ROOT/prd.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
RESEARCH_FILE="$ROOT/research.md"

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

if [ -z "$DESCRIPTION" ]; then
  echo -e "${BOLD}Uso:${RESET} bash scripts/prd.sh \"descrição do produto\""
  exit 1
fi

echo ""
echo -e "${BOLD}Gerando PRD:${RESET} $DESCRIPTION"
echo -e "${DIM}Modelo: Opus (execução única — qualidade estratégica)${RESET}"
echo ""

# ── Monta contexto ─────────────────────────────────────────────────
CONTEXT=""
[ -f "$CLAUDE_MD" ] && CONTEXT="$CONTEXT
CONTEXTO DO PROJETO:
$(cat "$CLAUDE_MD" | head -60)"

[ -f "$RESEARCH_FILE" ] && CONTEXT="$CONTEXT

PESQUISA TÉCNICA RELEVANTE:
$(cat "$RESEARCH_FILE" | head -100)"

# ── Opus gera o PRD ───────────────────────────────────────────────
echo -e "${YELLOW}Gerando PRD com Opus...${RESET}"
echo -e "${DIM}Isso pode levar alguns segundos...${RESET}"
echo ""

claude \
  --model claude-opus-4-6 \
  --print \
  --max-tokens 4000 \
  -p "Você é um Product Manager sênior. Crie um PRD completo baseado na descrição abaixo.

IMPORTANTE:
- Escreva em português
- Foco em requisitos de negócio claros e testáveis
- Não pressupor stack técnica específica
- V1 deve ser o mínimo que gera valor real

DESCRIÇÃO: $DESCRIPTION

$CONTEXT

ESTRUTURA OBRIGATÓRIA:

# PRD: [Nome do produto]

## Problema
[Dor clara do usuário — na linguagem dele]

## Usuários-alvo
[Perfil detalhado — quem usa, contexto de uso]

## Como resolvem hoje
[Situação atual — workarounds, ferramentas, processos manuais]

## Objetivos do V1
[3-5 objetivos mensuráveis — o que muda na vida do usuário]

## Escopo — O que está dentro do V1
[Funcionalidades incluídas]

## Fora do Escopo no V1
[O que NÃO será feito]

## Requisitos Funcionais
[Numerados, testáveis, em linguagem de negócio]

## Requisitos Não-Funcionais
[Performance, disponibilidade, segurança se relevante]

## Critérios de Sucesso
[Como o PM saberá que o V1 funcionou]

## Riscos
[Top 3 riscos e como mitigar]" > "$PRD_FILE"

echo -e "${GREEN}✓${RESET} PRD salvo em ${CYAN}prd.md${RESET}"
echo ""
echo -e "${DIM}Próximo passo: bash scripts/blueprint.sh${RESET}"
echo ""
