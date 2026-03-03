# Changelog

Todas as mudanças relevantes do PM Builder são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

## [1.0.0] — 2025

### Adicionado
- `start.sh` — assistente PM com entrevista socrática em português
- `scripts/research.sh` — pesquisa com Haiku (triagem) + Sonnet (análise)
- `scripts/prd.sh` — geração de PRD com Opus
- `scripts/blueprint.sh` — blueprint técnico com Sonnet + extração de todo.md com Haiku
- `scripts/codegen.sh` — implementação iterativa via todo.md com contexto cirúrgico
- `scripts/review.sh` — revisão com Sonnet, escalada para Opus com `--deep`
- `scripts/docs.sh` — documentação em três formatos (readme, api, inline)
- `scripts/lib/scan_project.py` — scan local de projeto (zero tokens)
- `scripts/lib/extract_context.py` — extração cirúrgica de contexto por fase (zero tokens)
- `scripts/lib/todo_manager.py` — gerenciamento de estado persistente (zero tokens)
- `install.sh` — instalador para projetos existentes
- Templates de `CLAUDE.md` e `agents.md`
- Documentação: guia PM, guia dev, estratégia de tokens
