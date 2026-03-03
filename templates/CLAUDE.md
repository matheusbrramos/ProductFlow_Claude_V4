# CLAUDE.md

## Projeto
**Nome:** [Nome do projeto]
**Descrição:** [Descrição em 1 frase]
**Tipo:** [webapp | api | automacao | integracao | mobile]
**Usuários:** [Quem vai usar]
**Status:** Em desenvolvimento

## Stack
> Será definida pelo blueprint. Priorize simplicidade para V1.

## Fluxo de Desenvolvimento (Agentes)

Este projeto usa um sistema de agentes com scripts shell.

| Etapa | Script | Quando usar |
|---|---|---|
| 1. Pesquisa | `bash scripts/research.sh "tema"` | Antes de algo novo |
| 2. PRD | `bash scripts/prd.sh "descrição"` | Uma vez por feature |
| 3. Blueprint | `bash scripts/blueprint.sh` | Após o PRD |
| 4. Codegen | `bash scripts/codegen.sh` | Para implementar |
| 5. Revisão | `bash scripts/review.sh .` | Após cada fase |
| 6. Docs | `bash scripts/docs.sh . --type readme` | Ao finalizar |

### Como iniciar uma sessão
- Se `todo.md` existe e tem itens pendentes → continue com `bash scripts/codegen.sh`
- Se `prd.md` existe mas `blueprint.md` não → rode `bash scripts/blueprint.sh`
- Se nada existe → rode `bash start.sh`

### Regras dos agentes
- Nunca pule etapas do fluxo
- Verifique `todo.md` para saber o estado atual
- Atualize `agents.md` ao descobrir padrões ou erros
- Use `python3 scripts/lib/todo_manager.py progress` para ver andamento
- Linguagem com o PM: sempre em português, sem jargão técnico
- Ao apresentar resultados ao PM: explique o que foi feito em linguagem simples
