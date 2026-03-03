#!/bin/bash
# install.sh
# Instala o sistema de agentes no projeto atual.
# Uso: bash install.sh [caminho-do-projeto]

set -e

PROJECT="${1:-$(pwd)}"
SYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Instalando sistema de agentes em: $PROJECT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verifica dependências
command -v claude >/dev/null 2>&1 || { echo "Erro: Claude Code CLI não encontrado. Instale com: npm install -g @anthropic-ai/claude-code"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Erro: Python 3 necessário"; exit 1; }

# Cria estrutura no projeto
mkdir -p "$PROJECT/scripts/lib"
mkdir -p "$PROJECT/docs"

# Copia helper principal
cp "$SYSTEM_DIR/start.sh" "$PROJECT/"
chmod +x "$PROJECT/start.sh"

# Copia scripts
cp "$SYSTEM_DIR/scripts/research.sh"   "$PROJECT/scripts/"
cp "$SYSTEM_DIR/scripts/prd.sh"        "$PROJECT/scripts/"
cp "$SYSTEM_DIR/scripts/blueprint.sh"  "$PROJECT/scripts/"
cp "$SYSTEM_DIR/scripts/codegen.sh"    "$PROJECT/scripts/"
cp "$SYSTEM_DIR/scripts/review.sh"     "$PROJECT/scripts/"
cp "$SYSTEM_DIR/scripts/docs.sh"       "$PROJECT/scripts/"

# Copia libs Python
cp "$SYSTEM_DIR/scripts/lib/scan_project.py"    "$PROJECT/scripts/lib/"
cp "$SYSTEM_DIR/scripts/lib/todo_manager.py"    "$PROJECT/scripts/lib/"
cp "$SYSTEM_DIR/scripts/lib/extract_context.py" "$PROJECT/scripts/lib/"

# Torna executáveis
chmod +x "$PROJECT/scripts/"*.sh

# Cria templates se não existirem
[ ! -f "$PROJECT/CLAUDE.md" ] && cp "$SYSTEM_DIR/templates/CLAUDE.md" "$PROJECT/"
[ ! -f "$PROJECT/agents.md" ] && cp "$SYSTEM_DIR/templates/agents.md" "$PROJECT/"

echo ""
echo "✓ Instalado com sucesso!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 PARA COMEÇAR:"
echo ""
echo "   bash start.sh"
echo ""
echo "   O assistente vai te guiar por tudo."
echo "   Não precisa saber de tecnologia!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 FLUXO MANUAL (para devs):"
echo ""
echo "  ./scripts/research.sh 'tema relevante'"
echo "  ./scripts/prd.sh 'descrição do produto'"
echo "  ./scripts/blueprint.sh"
echo "  ./scripts/codegen.sh [--all]"
echo "  ./scripts/review.sh ."
echo "  ./scripts/docs.sh . --type readme"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Modelos utilizados:"
echo "  Haiku  → entrevista, triagem, todo.md  (mínimo custo)"
echo "  Sonnet → blueprint, codegen, review    (padrão)"
echo "  Opus   → PRD                           (cirúrgico)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
