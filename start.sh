#!/bin/bash
# start.sh — PM Builder Helper
# Entrevista socrática em português que transforma uma ideia vaga
# em contexto completo para o fluxo de agentes.
# 
# Uso:
#   bash start.sh                    # inicia do zero
#   bash start.sh "tenho uma ideia"  # com contexto inicial
#   bash start.sh --continue         # retoma projeto existente

set -e

ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB="$SCRIPTS_DIR/scripts/lib"
CONTEXT_FILE="$ROOT/.interview_context.md"
CLAUDE_MD="$ROOT/CLAUDE.md"
PRD_FILE="$ROOT/prd.md"
TODO_FILE="$ROOT/todo.md"

# ── Cores para melhor UX no terminal ──────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ── Detecta estado do projeto ──────────────────────────────────────
detect_state() {
  if [ "$1" = "--continue" ]; then
    echo "continue"
  elif [ -f "$TODO_FILE" ] && grep -q "\[ \]" "$TODO_FILE" 2>/dev/null; then
    echo "in_progress"
  elif [ -f "$PRD_FILE" ] && [ ! -f "$ROOT/blueprint.md" ]; then
    echo "has_prd"
  elif [ -f "$CLAUDE_MD" ] && grep -q "\[Nome do projeto\]" "$CLAUDE_MD" 2>/dev/null; then
    echo "fresh"
  elif [ -f "$CONTEXT_FILE" ]; then
    echo "has_context"
  else
    echo "fresh"
  fi
}

# ── Boas-vindas ────────────────────────────────────────────────────
show_welcome() {
  clear
  echo ""
  echo -e "${BOLD}╔════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║        PM Builder — Assistente de Ideias   ║${RESET}"
  echo -e "${BOLD}╚════════════════════════════════════════════╝${RESET}"
  echo ""
}

# ── Retoma projeto em andamento ────────────────────────────────────
resume_project() {
  show_welcome
  echo -e "${GREEN}✓ Projeto em andamento encontrado!${RESET}"
  echo ""

  PROGRESS=$(python3 "$LIB/todo_manager.py" progress --root "$ROOT" 2>/dev/null || echo "0/0")
  NEXT=$(python3 "$LIB/todo_manager.py" next --root "$ROOT" 2>/dev/null || echo "")
  NEXT_TASK=$(echo "$NEXT" | grep "^TASK:" | sed 's/^TASK: //' || echo "")
  NEXT_PHASE=$(echo "$NEXT" | grep "^PHASE:" | sed 's/^PHASE: //' || echo "")

  echo -e "  Progresso atual: ${BOLD}$PROGRESS${RESET}"
  [ -n "$NEXT_PHASE" ] && echo -e "  Próxima fase:   ${BOLD}$NEXT_PHASE${RESET}"
  [ -n "$NEXT_TASK" ]  && echo -e "  Próxima tarefa: ${CYAN}$NEXT_TASK${RESET}"
  echo ""
  echo -e "${DIM}O que você quer fazer?${RESET}"
  echo "  1) Continuar de onde parou (próximo item do todo)"
  echo "  2) Ver todo o progresso"
  echo "  3) Revisar o código gerado até agora"
  echo "  4) Começar uma nova feature"
  echo ""
  printf "  Escolha [1-4]: "
  read -r CHOICE

  case "$CHOICE" in
    1) 
      echo ""
      echo -e "${BOLD}→ Retomando implementação...${RESET}"
      bash "$SCRIPTS_DIR/scripts/codegen.sh"
      ;;
    2)
      echo ""
      python3 "$LIB/todo_manager.py" list --root "$ROOT"
      echo ""
      echo -e "${DIM}Pressione Enter para continuar...${RESET}"
      read -r
      resume_project
      ;;
    3)
      echo ""
      bash "$SCRIPTS_DIR/scripts/review.sh" .
      ;;
    4)
      IDEA=""
      run_interview
      ;;
    *)
      resume_project
      ;;
  esac
}

# ── Entrevista socrática ───────────────────────────────────────────
run_interview() {
  show_welcome

  echo -e "${BOLD}Olá! Vou te ajudar a transformar sua ideia em realidade.${RESET}"
  echo ""
  echo -e "${DIM}Não precisa saber de tecnologia — só me conta o que você quer resolver.${RESET}"
  echo -e "${DIM}Farei uma pergunta por vez para entender bem antes de começarmos.${RESET}"
  echo ""
  echo -e "  ${DIM}(Digite 'pronto' quando quiser gerar o projeto | 'sair' para cancelar)${RESET}"
  echo ""

  # Contexto inicial passado como argumento
  INITIAL_IDEA="${1:-}"
  
  if [ -n "$INITIAL_IDEA" ]; then
    echo -e "${CYAN}Sua ideia inicial:${RESET} $INITIAL_IDEA"
    echo ""
    ACCUMULATED_CONTEXT="Ideia inicial do PM: $INITIAL_IDEA"
  else
    echo -e "${BOLD}Em uma frase: qual problema você quer resolver ou o que quer criar?${RESET}"
    echo ""
    printf "  → "
    read -r INITIAL_IDEA
    echo ""
    ACCUMULATED_CONTEXT="Ideia inicial do PM: $INITIAL_IDEA"
  fi

  # Salva contexto inicial
  echo "# Contexto da Entrevista" > "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  echo "## Ideia Inicial" >> "$CONTEXT_FILE"
  echo "$INITIAL_IDEA" >> "$CONTEXT_FILE"
  echo "" >> "$CONTEXT_FILE"
  echo "## Respostas" >> "$CONTEXT_FILE"

  QUESTION_COUNT=0
  MAX_QUESTIONS=8

  # Loop de perguntas
  while [ "$QUESTION_COUNT" -lt "$MAX_QUESTIONS" ]; do
    QUESTION_COUNT=$((QUESTION_COUNT + 1))
    
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    # Haiku gera a próxima pergunta baseada no contexto acumulado
    NEXT_QUESTION=$(claude \
      --model claude-haiku-4-5-20251001 \
      --print \
      --max-tokens 200 \
      -p "Você é um assistente que ajuda gerentes de produto a clarificar ideias.
Seu estilo: amigável, direto, sem jargão técnico. Foco em negócio e usuário.

Baseado no contexto abaixo, faça A PRÓXIMA pergunta mais importante.
APENAS UMA pergunta. Curta. Em português.

Prioridade das perguntas (nesta ordem, pule as já respondidas):
1. Quem são os usuários e qual dor exata eles têm?
2. Como esse problema é resolvido hoje (manualmente/outra ferramenta)?
3. Qual seria o resultado de sucesso — o que muda na vida do usuário?
4. Qual o escopo mínimo para validar a ideia (V1)?
5. Existem restrições importantes (prazo, orçamento, integrações necessárias)?
6. Qual a frequência de uso esperada?
7. Há dados ou sistemas existentes que precisam se conectar?
8. Quem vai usar primeiro — time interno ou clientes externos?

CONTEXTO ACUMULADO:
$ACCUMULATED_CONTEXT

Retorne APENAS a pergunta, sem introdução, sem numeração.")

    echo -e "${BOLD}$NEXT_QUESTION${RESET}"
    echo ""
    printf "  → "
    read -r ANSWER

    # Verifica comandos especiais
    if echo "$ANSWER" | grep -qi "^pronto\|^gerar\|^continuar\|^ok\|^sim$"; then
      break
    fi
    if echo "$ANSWER" | grep -qi "^sair\|^cancelar\|^exit"; then
      echo ""
      echo "Entrevista cancelada. Seu progresso foi salvo em .interview_context.md"
      exit 0
    fi

    # Acumula contexto
    ACCUMULATED_CONTEXT="$ACCUMULATED_CONTEXT

Pergunta $QUESTION_COUNT: $NEXT_QUESTION
Resposta: $ANSWER"

    # Salva no arquivo
    echo "### P$QUESTION_COUNT: $NEXT_QUESTION" >> "$CONTEXT_FILE"
    echo "**R:** $ANSWER" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"

    # A cada 4 perguntas, Haiku avalia se já tem contexto suficiente
    if [ "$QUESTION_COUNT" -eq 4 ] || [ "$QUESTION_COUNT" -eq 6 ]; then
      SUFFICIENT=$(echo "$ACCUMULATED_CONTEXT" | claude \
        --model claude-haiku-4-5-20251001 \
        --print \
        --max-tokens 50 \
        -p "O contexto abaixo é suficiente para criar um PRD detalhado? Responda apenas: SIM ou NAO e em uma frase o motivo.

$ACCUMULATED_CONTEXT")
      
      if echo "$SUFFICIENT" | grep -qi "^SIM"; then
        echo ""
        echo -e "${DIM}$SUFFICIENT${RESET}"
        echo ""
        echo -e "${BOLD}Acho que já temos o suficiente para começar!${RESET}"
        echo -e "  Quer adicionar mais algum detalhe ou podemos gerar o projeto? ${DIM}(Enter para gerar / continue digitando)${RESET}"
        printf "  → "
        read -r EXTRA
        if [ -z "$EXTRA" ] || echo "$EXTRA" | grep -qi "^sim\|^gerar\|^pronto\|^ok"; then
          break
        fi
        ACCUMULATED_CONTEXT="$ACCUMULATED_CONTEXT

Detalhe adicional: $EXTRA"
      fi
    fi
  done

  # Gera todos os artefatos
  generate_all "$ACCUMULATED_CONTEXT"
}

# ── Geração de todos os artefatos ─────────────────────────────────
generate_all() {
  local CONTEXT="$1"

  echo ""
  echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "${BOLD}Perfeito! Agora vou organizar tudo e preparar seu projeto.${RESET}"
  echo -e "${DIM}Isso leva alguns minutos — pode tomar um café ☕${RESET}"
  echo ""

  # ── Passo 1: CLAUDE.md ──────────────────────────────────────────
  echo -e "  ${YELLOW}[1/5]${RESET} Criando contexto do projeto..."

  PROJECT_META=$(claude \
    --model claude-haiku-4-5-20251001 \
    --print \
    --max-tokens 400 \
    -p "Baseado no contexto abaixo, extraia em JSON simples:
{
  \"nome\": \"nome curto do projeto (2-4 palavras, sem espaços especiais)\",
  \"descricao\": \"descrição em 1 frase clara\",
  \"tipo\": \"webapp | api | automacao | integracao | mobile\",
  \"usuarios\": \"quem vai usar\"
}

CONTEXTO:
$CONTEXT

Retorne APENAS o JSON, sem markdown.")

  PROJECT_NAME=$(echo "$PROJECT_META" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('nome','meu-projeto'))" 2>/dev/null || echo "meu-projeto")
  PROJECT_DESC=$(echo "$PROJECT_META" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('descricao',''))" 2>/dev/null || echo "")
  PROJECT_TYPE=$(echo "$PROJECT_META" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tipo','webapp'))" 2>/dev/null || echo "webapp")
  PROJECT_USERS=$(echo "$PROJECT_META" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usuarios',''))" 2>/dev/null || echo "")

  # Gera CLAUDE.md
  cat > "$CLAUDE_MD" << CLAUDEMD
# CLAUDE.md

## Projeto
**Nome:** $PROJECT_NAME
**Descrição:** $PROJECT_DESC
**Tipo:** $PROJECT_TYPE
**Usuários:** $PROJECT_USERS
**Status:** Em desenvolvimento

## Stack
> Será definida pelo blueprint. Priorize simplicidade para V1.

## Fluxo de Desenvolvimento (Agentes)

Este projeto usa um sistema de agentes com scripts shell.

| Etapa | Script | Quando usar |
|---|---|---|
| 1. Pesquisa | \`bash scripts/research.sh "tema"\` | Antes de algo novo |
| 2. PRD | \`bash scripts/prd.sh "descrição"\` | Uma vez por feature |
| 3. Blueprint | \`bash scripts/blueprint.sh\` | Após o PRD |
| 4. Codegen | \`bash scripts/codegen.sh\` | Para implementar |
| 5. Revisão | \`bash scripts/review.sh .\` | Após cada fase |
| 6. Docs | \`bash scripts/docs.sh . --type readme\` | Ao finalizar |

### Como iniciar uma sessão
- Se \`todo.md\` existe e tem itens pendentes → continue com \`bash scripts/codegen.sh\`
- Se \`prd.md\` existe mas \`blueprint.md\` não → rode \`bash scripts/blueprint.sh\`
- Se nada existe → rode \`bash start.sh\`

### Regras dos agentes
- Nunca pule etapas do fluxo
- Verifique \`todo.md\` para saber o estado atual
- Atualize \`agents.md\` ao descobrir padrões ou erros
- Use \`python3 scripts/lib/todo_manager.py progress\` para ver andamento
- Linguagem com o PM: sempre em português, sem jargão técnico
- Ao apresentar resultados ao PM: explique o que foi feito em linguagem simples

## Contexto da Entrevista
> Origem desta especificação: entrevista com o PM em $(date '+%d/%m/%Y')
CLAUDEMD

  echo -e "  ${GREEN}✓${RESET} CLAUDE.md criado"

  # ── Passo 2: PRD ───────────────────────────────────────────────
  echo -e "  ${YELLOW}[2/5]${RESET} Gerando PRD (requisitos do produto)..."

  claude \
    --model claude-opus-4-6 \
    --print \
    --max-tokens 3000 \
    -p "Você é um Product Manager sênior. Crie um PRD completo baseado na entrevista abaixo.

IMPORTANTE: O PM não é técnico. Escreva requisitos claros de negócio.
Traduza necessidades de negócio em requisitos — sem pressupor stack técnica.

ESTRUTURA OBRIGATÓRIA:
# PRD: $PROJECT_NAME

## Problema
[Dor clara do usuário — na linguagem dele]

## Quem são os usuários
[Perfil detalhado]

## Como resolvem hoje
[Situação atual — workarounds, ferramentas, processos manuais]

## Objetivos do V1
[3-5 objetivos mensuráveis — o que muda na vida do usuário]

## Escopo — V1 (Mínimo que gera valor)
[O que está DENTRO]

## Fora do Escopo agora
[O que NÃO será feito no V1]

## Requisitos Funcionais
[O que o sistema deve fazer — numerados, testáveis, em linguagem de negócio]

## Requisitos Não-Funcionais
[Performance esperada, disponibilidade, segurança se relevante]

## Critérios de Sucesso
[Como o PM saberá que o V1 funcionou]

## Riscos
[Top 3 riscos e como mitigar]

CONTEXTO DA ENTREVISTA:
$CONTEXT" > "$PRD_FILE"

  echo -e "  ${GREEN}✓${RESET} PRD gerado"

  # ── Passo 3: Blueprint ─────────────────────────────────────────
  echo -e "  ${YELLOW}[3/5]${RESET} Criando blueprint técnico..."
  bash "$SCRIPTS_DIR/scripts/blueprint.sh" 2>/dev/null
  echo -e "  ${GREEN}✓${RESET} Blueprint e todo.md criados"

  # ── Passo 4: agents.md ─────────────────────────────────────────
  echo -e "  ${YELLOW}[4/5]${RESET} Inicializando base de conhecimento..."
  cat > "$ROOT/agents.md" << AGENTSMD
# agents.md — Lições Aprendidas

> Gerado em: $(date '+%d/%m/%Y')
> Atualizado automaticamente pelo review.sh

## Contexto do Projeto
- Projeto: $PROJECT_NAME
- Tipo: $PROJECT_TYPE
- Usuários-alvo: $PROJECT_USERS
- PM não técnico — mantenha comunicação em português simples

## Regras Críticas
- Sempre usar variáveis de ambiente para credenciais (nunca hardcode)
- Nunca commitar arquivos .env
- Priorizar simplicidade — V1 deve funcionar antes de otimizar
- Testar com dados reais, não mocks

## Não Fazer
- Adicionar features fora do escopo do PRD sem consultar o PM
- Criar complexidade desnecessária no V1
- Usar tecnologias que o time não conhece sem justificativa clara
AGENTSMD

  echo -e "  ${GREEN}✓${RESET} agents.md inicializado"

  # ── Passo 5: Resumo para o PM ──────────────────────────────────
  echo -e "  ${YELLOW}[5/5]${RESET} Preparando resumo..."

  PM_SUMMARY=$(claude \
    --model claude-haiku-4-5-20251001 \
    --print \
    --max-tokens 500 \
    -p "Baseado no PRD abaixo, escreva um resumo CURTO para o PM (não técnico).
Em português. Tom amigável e animado. Máximo 8 linhas.
Explique: o que foi entendido, o que será construído no V1, e quantas etapas tem o plano.
Sem jargão técnico. Sem mencionar arquivos ou scripts.

PRD:
$(cat $PRD_FILE | head -60)")

  echo ""
  echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "${BOLD}✅ Projeto preparado!${RESET}"
  echo ""
  echo "$PM_SUMMARY"
  echo ""

  # Mostra progresso do todo
  echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "${BOLD}Plano de implementação:${RESET}"
  python3 "$LIB/todo_manager.py" list --root "$ROOT" 2>/dev/null || true
  echo ""
  echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "${BOLD}Pronto para começar a construir?${RESET}"
  echo ""
  echo "  1) Sim, iniciar agora!"
  echo "  2) Quero revisar o plano antes"
  echo "  3) Deixa pra depois"
  echo ""
  printf "  Escolha [1-3]: "
  read -r START_CHOICE

  case "$START_CHOICE" in
    1)
      echo ""
      echo -e "${BOLD}Iniciando implementação...${RESET}"
      echo -e "${DIM}Vou te avisar ao final de cada etapa.${RESET}"
      echo ""
      bash "$SCRIPTS_DIR/scripts/codegen.sh" --all
      
      echo ""
      echo -e "${GREEN}${BOLD}🎉 Primeira fase concluída!${RESET}"
      echo ""
      echo "  O código foi gerado. Próximos passos:"
      echo "  • Revise o que foi criado: ${DIM}bash scripts/review.sh .${RESET}"
      echo "  • Continue implementando: ${DIM}bash scripts/codegen.sh${RESET}"
      echo "  • Volte aqui quando quiser: ${DIM}bash start.sh --continue${RESET}"
      ;;
    2)
      echo ""
      echo -e "${BOLD}Arquivos criados:${RESET}"
      echo -e "  📋 ${CYAN}prd.md${RESET}       — requisitos do produto"
      echo -e "  🗺️  ${CYAN}blueprint.md${RESET} — plano técnico detalhado"
      echo -e "  ✅ ${CYAN}todo.md${RESET}      — checklist de implementação"
      echo -e "  📖 ${CYAN}CLAUDE.md${RESET}    — contexto do projeto"
      echo ""
      echo -e "${DIM}Quando estiver pronto: bash scripts/codegen.sh${RESET}"
      ;;
    3)
      echo ""
      echo -e "Tudo salvo! Quando voltar, rode: ${CYAN}bash start.sh --continue${RESET}"
      ;;
  esac

  echo ""
}

# ── Entry point ────────────────────────────────────────────────────
STATE=$(detect_state "$1")
INITIAL_IDEA="${1:-}"

case "$STATE" in
  in_progress)
    resume_project
    ;;
  has_prd)
    show_welcome
    echo -e "${GREEN}✓ PRD encontrado. Gerando blueprint...${RESET}"
    echo ""
    bash "$SCRIPTS_DIR/scripts/blueprint.sh"
    ;;
  has_context)
    show_welcome
    echo -e "${YELLOW}Encontrei uma entrevista anterior salva.${RESET}"
    echo ""
    echo "  1) Continuar entrevista anterior"
    echo "  2) Começar do zero"
    echo ""
    printf "  Escolha [1-2]: "
    read -r RESUME_CHOICE
    if [ "$RESUME_CHOICE" = "1" ]; then
      SAVED_CONTEXT=$(cat "$CONTEXT_FILE")
      generate_all "$SAVED_CONTEXT"
    else
      rm -f "$CONTEXT_FILE"
      run_interview ""
    fi
    ;;
  fresh|*)
    run_interview "$INITIAL_IDEA"
    ;;
esac
