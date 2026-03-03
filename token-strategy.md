# Estratégia de Economia de Tokens

Documentação das decisões de arquitetura para minimizar custo de tokens
sem comprometer qualidade.

## Princípio central

> O modelo caro só entra quando o trabalho barato já filtrou, estruturou e compactou o contexto.

## Camadas de processamento

### Camada 0 — Python (Zero tokens)

Tudo que é determinístico é processado localmente antes de qualquer chamada ao modelo.

**scan_project.py**
- Varre estrutura de diretórios (ignora node_modules, .git, dist, etc.)
- Lê apenas o topo de arquivos grandes (máx. 120 linhas)
- Faz grep por keywords da tarefa para identificar arquivos relevantes
- Extrai contexto git (branch atual, 5 últimos commits)
- Resultado: contexto estruturado entregue ao modelo, não descoberto por ele

**extract_context.py**
- Extrai do `blueprint.md` apenas a seção da fase atual via regex
- Nunca passa o blueprint inteiro para o modelo — apenas o trecho relevante
- Extrai do `prd.md` apenas a seção relacionada à keyword da tarefa
- Monta contexto composto: CLAUDE.md + agents.md + seção do blueprint + seção do PRD
- Economia direta: um blueprint de 4000 tokens → modelo recebe ~800 tokens da fase atual

**todo_manager.py**
- Lê, escreve e atualiza o `todo.md` sem LLM
- Entrega ao codegen apenas: fase, índice, task text, progresso
- Nenhum token gasto para "saber onde o projeto está"

### Camada 1 — Haiku (Mínimo custo)

Tarefas de classificação, triagem e extração simples onde respostas longas não agregam valor.

| Tarefa | Por que Haiku resolve |
|---|---|
| Conduzir entrevista PM (8 perguntas) | Perguntas curtas e focadas — não exige raciocínio complexo |
| Avaliar suficiência de contexto | Classificação binária (SIM/NAO + motivo) |
| Verificar se pesquisa já existe | Grep semântico simples no contexto |
| Extrair metadados do projeto (nome, tipo) | Extração estruturada em JSON |
| Gerar e formatar todo.md | Transformação de formato — blueprint → checklist |

**Custo da entrevista completa com Haiku:**
- 8 perguntas × ~200 tokens = ~1600 tokens
- 2 avaliações de suficiência × ~100 tokens = ~200 tokens
- Total: ~1800 tokens — menos que uma única chamada ao Opus para o mesmo contexto

### Camada 2 — Sonnet (Padrão)

90% do trabalho técnico. Recebe contexto pré-processado — nunca documentos inteiros.

**codegen.sh:** recebe apenas o prompt da fase atual do blueprint (extraído pelo Python), não o blueprint completo.

**review.sh:** recebe apenas o código do arquivo/pasta especificada, não o projeto inteiro.

**blueprint.sh:** recebe o PRD completo (necessário) + contexto do projeto (pré-filtrado pelo scan_project.py).

**docs.sh:** recebe apenas o código do target + contexto compacto do extract_context.py.

### Camada 3 — Opus (Cirúrgico)

Duas situações únicas onde o custo é justificado pela qualidade da saída:

**PRD (prd.sh)**
- Execução única por feature — não rotineira
- O PRD ruim contamina todo o pipeline downstream
- Contexto chega estruturado pela entrevista — Opus não precisa explorar, só sintetizar
- Trade-off: custo maior em uma chamada, economia em todas as chamadas subsequentes (codegen recebe contratos claros)

**Review profundo (--deep)**
- Só ativado explicitamente com a flag `--deep`
- Só aciona Opus se Sonnet já identificou problemas CRÍTICOS (grep na saída)
- Caso de uso: bug persistente que Sonnet não está conseguindo diagnosticar

## Exemplo de economia real

### Sem PM Builder (fluxo ingênuo)
```
Dev abre projeto → Sonnet explora estrutura (2000 tokens)
Dev pede codegen → Sonnet lê PRD inteiro (3000 tokens) + blueprint (4000 tokens)
Dev pede review → Sonnet lê todo o código (5000 tokens)
Total por sessão: ~14.000 tokens só de contexto
```

### Com PM Builder
```
scan_project.py monta contexto (0 tokens)
extract_context.py extrai fase atual do blueprint (0 tokens)
Sonnet recebe contexto compacto: CLAUDE.md (500) + agents.md (300) + fase (800) = 1600 tokens
Total por sessão: ~1.600 tokens de contexto
```

Redução de ~88% no contexto por chamada de codegen.

## Padrões que aumentam tokens (evitar)

- Passar o PRD inteiro para o codegen — use extract_context.py
- Passar o blueprint inteiro para a review — passe só o código revisado
- Usar Sonnet/Opus para verificar se um arquivo existe — use Python
- Pedir ao modelo para explorar a estrutura do projeto — use scan_project.py
- Repetir CLAUDE.md e agents.md em cada chamada sem truncar — aplique o limite de 800/600 chars definido em extract_context.py
