# Guia para Desenvolvedores

Referência técnica para uso avançado, customização e extensão do PM Builder.

## Usando scripts individuais

Cada script é independente e pode ser chamado diretamente sem passar pelo `start.sh`.

```bash
# Pesquisa técnica antes de começar
bash scripts/research.sh "padrões de autenticação OAuth2 com refresh token"

# Gerar PRD a partir de uma descrição
bash scripts/prd.sh "API de notificações com suporte a email, SMS e push"

# Gerar blueprint a partir de um prd.md existente
bash scripts/blueprint.sh

# Implementar próximo item do todo.md
bash scripts/codegen.sh

# Implementar todos os itens com pausa entre fases
bash scripts/codegen.sh --all

# Implementar item específico pelo índice
bash scripts/codegen.sh --item 2

# Revisar pasta ou arquivo
bash scripts/review.sh src/
bash scripts/review.sh src/auth.py

# Revisão profunda com escalada para Opus (críticos detectados)
bash scripts/review.sh src/ --deep

# Gerar documentação
bash scripts/docs.sh . --type readme
bash scripts/docs.sh src/api/ --type api
bash scripts/docs.sh src/utils.py --type inline
```

## Variável de ambiente PROJECT_ROOT

Por padrão, os scripts usam o diretório atual. Para apontar para outro diretório:

```bash
PROJECT_ROOT=/outro/projeto bash scripts/codegen.sh
```

## Usando as libs Python diretamente

### scan_project.py

```bash
# Saída em texto (padrão)
python3 scripts/lib/scan_project.py --task "autenticação"

# Saída em JSON para processar programaticamente
python3 scripts/lib/scan_project.py --task "autenticação" --format json

# Especificar raiz do projeto
python3 scripts/lib/scan_project.py --root /outro/projeto --task "billing"
```

### todo_manager.py

```bash
# Próximo item pendente
python3 scripts/lib/todo_manager.py next

# Listar todos os itens com status
python3 scripts/lib/todo_manager.py list

# Ver progresso percentual
python3 scripts/lib/todo_manager.py progress

# Marcar item como concluído
python3 scripts/lib/todo_manager.py done --index 3
```

### extract_context.py

```bash
# Contexto completo para uma tarefa (CLAUDE.md + agents.md + blueprint atual + prd relevante)
python3 scripts/lib/extract_context.py --task "autenticação" --phase "Fase 01: Setup"

# Só a seção do blueprint para uma fase
python3 scripts/lib/extract_context.py --phase "Fase 02: Core" --output blueprint

# Só a seção relevante do PRD
python3 scripts/lib/extract_context.py --task "billing" --output prd
```

## Customizando modelos

Os modelos são definidos diretamente nos scripts. Para alterar:

| Script | Variável / linha | Padrão |
|---|---|---|
| `research.sh` | `--model claude-haiku-4-5-20251001` (triagem) | Haiku |
| `research.sh` | `--model claude-sonnet-4-6` (pesquisa) | Sonnet |
| `prd.sh` | `--model claude-opus-4-6` | Opus |
| `blueprint.sh` | `--model claude-sonnet-4-6` (blueprint) | Sonnet |
| `blueprint.sh` | `--model claude-haiku-4-5-20251001` (todo) | Haiku |
| `codegen.sh` | `--model claude-sonnet-4-6` | Sonnet |
| `review.sh` | `--model claude-sonnet-4-6` (padrão) | Sonnet |
| `review.sh` | `--model claude-opus-4-6` (--deep + críticos) | Opus |
| `docs.sh` | `--model claude-sonnet-4-6` | Sonnet |

## Estrutura do todo.md

O `todo.md` é o estado persistente do projeto. Formato:

```markdown
# To-Do

## Fase 01: Setup
- [x] Inicializar projeto com estrutura de pastas
- [x] Configurar variáveis de ambiente
- [ ] Criar banco de dados e migrations

## Fase 02: Core
- [ ] Implementar endpoint de autenticação
- [ ] Adicionar middleware de validação
```

O `todo_manager.py` gerencia esse arquivo — não edite manualmente a não ser para adicionar fases.

## Adicionando novos tipos de documentação

No `docs.sh`, o bloco `case "$DOC_TYPE"` controla os tipos disponíveis.
Para adicionar um novo tipo:

```bash
changelog)
  PROMPT="Gere um CHANGELOG.md baseado nos commits e no código abaixo..."
  OUTPUT_FILE="$ROOT/CHANGELOG.md"
  ;;
```

## agents.md como memória do projeto

O `agents.md` é atualizado automaticamente pelo `review.sh` após cada revisão.
Você também pode adicionar lições manualmente:

```markdown
## 2025-01-15 — src/auth/jwt.py
**Problema:** Token expira sem notificar o cliente
**Causa:** Middleware não trata 401 com refresh automático
**Correção:** Adicionar interceptor no cliente HTTP
**Prevenção:** Todo endpoint autenticado deve ter teste de token expirado
```

Em sessões futuras, todos os agentes leem esse arquivo e evitam repetir o erro.

## Integrando com CI/CD

O `review.sh` retorna código de saída 0 se aprovado, 1 se há problemas críticos:

```yaml
# .github/workflows/review.yml
- name: Review com PM Builder
  run: bash scripts/review.sh src/
  # Falha o CI se houver problemas críticos não resolvidos
```

## Contribuindo com melhorias

Veja [CONTRIBUTING.md](../CONTRIBUTING.md) para diretrizes de contribuição.
