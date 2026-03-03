# PM Builder — AI Agent System for Claude Code 🚀

> **Transforme ideias em software. Sem precisar saber programar.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-blue.svg)](https://claude.ai/code)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20PowerShell-green.svg)](https://www.gnu.org/software/bash/)
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Models](https://img.shields.io/badge/Models-Haiku%20%7C%20Sonnet%20%7C%20Opus-purple.svg)](https://anthropic.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./CONTRIBUTING.md)

Sistema de agentes orquestrados para Claude Code CLI com otimização de tokens por camadas.
Desenhado para transformar **gerentes de produto em builders** — do zero ao código, guiado por entrevista em linguagem natural.

---

## Navegação Rápida

- [Início em 2 minutos](#início-em-2-minutos)
- [Para quem é isso](#para-quem-é-isso)
- [Como funciona](#como-funciona)
- [Arquitetura de modelos](#arquitetura-de-modelos)
- [Estratégia de economia de tokens](#estratégia-de-economia-de-tokens)
- [Scripts disponíveis](#scripts-disponíveis)
- [Fluxo completo](#fluxo-completo)
- [Instalação](#instalação)
- [Documentação](#documentação)
- [Contribuindo](#contribuindo)

---

## Início em 2 Minutos

**Windows (PowerShell):**
```powershell
# 1. Clone e instale
git clone https://github.com/matheusbrramos/ProductFlow_Claude_V4.git
.\ProductFlow_Claude_V4\install.ps1 -Project "C:\caminho\do\projeto"

# 2. Inicie
cd C:\caminho\do\projeto
bash start.sh
```

**macOS / Linux:**
```bash
# 1. Clone e instale
git clone https://github.com/matheusbrramos/ProductFlow_Claude_V4.git
bash ProductFlow_Claude_V4/install.sh /caminho/do/projeto

# 2. Inicie
cd /caminho/do/projeto
bash start.sh
```

O assistente faz o resto. Uma pergunta por vez, em português.

---

## Para Quem é Isso

### Para Gerentes de Produto (PM Builder)

Você tem uma ideia mas não sabe programar. O `start.sh` conduz uma entrevista socrática e transforma sua visão em PRD, blueprint técnico, checklist de implementação e código — sem você precisar abrir um arquivo de configuração.

### Para Desenvolvedores

Você quer um pipeline estruturado com múltiplos modelos, economia de tokens por camadas e estado persistente entre sessões. Cada script é independente e pode ser chamado diretamente.

---

## Como Funciona

### O Assistente (Para PMs)

```
bash start.sh
```

```
╔════════════════════════════════════════════╗
║        PM Builder — Assistente de Ideias   ║
╚════════════════════════════════════════════╝

Olá! Vou te ajudar a transformar sua ideia em realidade.
Não precisa saber de tecnologia.

Em uma frase: qual problema você quer resolver?

  → Nosso time perde horas aprovando despesas por email

Qual é o maior problema nesse processo hoje — 
demora, erros ou falta de visibilidade?

  → ...
```

Ao final da entrevista (máx. 8 perguntas), o sistema gera automaticamente:

| Artefato | Conteúdo |
|---|---|
| `CLAUDE.md` | Contexto do projeto para os agentes |
| `prd.md` | Requisitos do produto em linguagem de negócio |
| `blueprint.md` | Plano técnico com prompts por fase |
| `todo.md` | Checklist de implementação com estado persistente |
| `agents.md` | Base de conhecimento acumulada do projeto |

E então inicia a implementação.

### Detecção de Estado Automática

O `start.sh` detecta onde você está e age de acordo:

| Estado do projeto | O que o assistente faz |
|---|---|
| Projeto novo | Inicia entrevista socrática |
| Entrevista salva (`.interview_context.md`) | Oferece retomar ou recomeçar |
| PRD pronto, sem blueprint | Gera blueprint direto |
| Em andamento (`todo.md` com pendências) | Mostra progresso e continua |

---

## Arquitetura de Modelos

O sistema distribui o trabalho entre modelos de acordo com custo e complexidade da tarefa:

| Modelo | Onde é usado | Justificativa |
|---|---|---|
| **Python** | Scan de projeto, extração de contexto, estado do todo | Zero tokens — processamento local puro |
| **Haiku** | Entrevista PM, triagem de pesquisa, extração do todo.md | Máxima economia — tarefas de classificação e extração simples |
| **Sonnet** | Blueprint, codegen, review, docs | Padrão — 90% do trabalho técnico, ótimo custo-benefício |
| **Opus** | PRD | Cirúrgico — execução única por feature, qualidade estratégica justifica o custo |

### Escalada Condicional

O `review.sh` escala para Opus **somente** quando duas condições são simultâneas:
1. Sonnet identificou problemas **CRÍTICOS** no código
2. Flag `--deep` foi explicitamente passada

Em todos os outros casos, Sonnet revisa.

---

## Estratégia de Economia de Tokens

### Camada 0 — Python (Zero tokens)

Três scripts locais eliminam chamadas desnecessárias ao modelo:

- **`scan_project.py`** — varre estrutura de arquivos, git, dependências e arquivos-chave
- **`extract_context.py`** — extrai do blueprint **apenas a seção da fase atual**, nunca o documento inteiro
- **`todo_manager.py`** — gerencia estado entre sessões sem LLM

### Camada 1 — Haiku (Mínimo custo)

- Conduz toda a entrevista PM (8 perguntas + avaliações de suficiência)
- Verifica se pesquisa já existe antes de acionar o Sonnet
- Extrai e formata o `todo.md` a partir do blueprint

### Camada 2 — Sonnet (Padrão)

- Recebe contexto **pré-processado** pelo Python — nunca lê documentos inteiros
- Opera com contexto cirúrgico: só o trecho do blueprint da fase atual

### Camada 3 — Opus (Cirúrgico)

- PRD: uma única chamada por feature, contexto estruturado pela entrevista
- Review profundo: somente quando explicitamente solicitado + problemas críticos detectados

### Resultado Prático

O `codegen.sh` nunca lê o PRD inteiro. Lê só o prompt da fase atual do blueprint.  
O `review.sh` nunca lê a spec inteira. Lê só o contrato do que foi implementado.  
O `blueprint.sh` nunca repassa contexto redundante. Python filtra antes de chamar o modelo.

---

## Scripts Disponíveis

### `start.sh` — Ponto de entrada (PMs e devs)

```bash
bash start.sh                     # detecta estado e age automaticamente
bash start.sh "tenho uma ideia"   # começa com contexto inicial
bash start.sh --continue          # retoma projeto em andamento
```

### `scripts/research.sh` — Pesquisa

```bash
bash scripts/research.sh "autenticação JWT"
```

Haiku verifica se o tema já está documentado → Sonnet pesquisa apenas se necessário.

### `scripts/prd.sh` — Product Requirements Document

```bash
bash scripts/prd.sh "sistema de aprovação de despesas"
```

Opus gera PRD completo. Execução única por feature.

### `scripts/blueprint.sh` — Plano técnico

```bash
bash scripts/blueprint.sh
```

Sonnet gera blueprint com prompts por fase + Haiku extrai `todo.md`.

### `scripts/codegen.sh` — Implementação iterativa

```bash
bash scripts/codegen.sh            # próximo item do todo.md
bash scripts/codegen.sh --all      # todos os itens (pausa entre fases)
bash scripts/codegen.sh --item 3   # item específico
```

Loop inteligente: lê o próximo item pendente do `todo.md`, monta contexto mínimo via Python, implementa com Sonnet e marca como concluído.

### `scripts/review.sh` — Revisão de código

```bash
bash scripts/review.sh .                  # revisão geral (Sonnet)
bash scripts/review.sh src/auth/          # pasta específica
bash scripts/review.sh src/api.py --deep  # escalada para Opus
```

Atualiza `agents.md` automaticamente com lições aprendidas após cada revisão.

### `scripts/docs.sh` — Documentação

```bash
bash scripts/docs.sh . --type readme   # README do projeto
bash scripts/docs.sh src/ --type api   # documentação de API
bash scripts/docs.sh src/ --type inline # docstrings inline
```

---

## Fluxo Completo

```
start.sh ──────────────────────────────────────────────────────────
  Detecta estado → Entrevista PM (Haiku) → Gera artefatos → Inicia codegen
      │
      ▼
research.sh          Haiku triagem → Sonnet pesquisa
      │
      ▼
prd.sh               Opus gera PRD (único por feature)
      │
      ▼
blueprint.sh         Sonnet plano técnico + prompts por fase
                     Haiku extrai todo.md
      │
      ▼
codegen.sh ──────────────────────── loop ──────────────────────────
  Python lê próximo item do todo.md
  Python extrai contexto mínimo (só a fase atual do blueprint)
  Sonnet implementa
  Marca como concluído
  Repete até ALL_DONE
      │
      ▼
review.sh            Sonnet revisa → Opus se --deep + críticos
                     Atualiza agents.md com lições
      │
      ▼
docs.sh              Sonnet gera README / API / inline
```

---

## Arquivos Gerados por Projeto

| Arquivo | Gerado por | Propósito |
|---|---|---|
| `CLAUDE.md` | `start.sh` / manual | Contexto base + instruções para agentes |
| `agents.md` | `start.sh` + `review.sh` | Lições aprendidas acumuladas entre sessões |
| `research.md` | `research.sh` | Referências técnicas de pesquisa |
| `prd.md` | `prd.sh` / `start.sh` | Requisitos do produto |
| `blueprint.md` | `blueprint.sh` | Plano técnico detalhado com prompts por fase |
| `todo.md` | `blueprint.sh` | Estado de progresso persistente entre sessões |
| `.interview_context.md` | `start.sh` | Respostas salvas da entrevista PM |

---

## Instalação

### Pré-requisitos

- [Claude Code CLI](https://docs.anthropic.com/claude-code) instalado e autenticado
- Python 3.8+
- **Windows:** PowerShell 5.1+ (já incluso no Windows 10/11) + [Git Bash](https://gitforwindows.org) para executar os scripts
- **macOS/Linux:** Bash nativo

### Instalar no Windows (PowerShell)

```powershell
# Clone o repositório
git clone https://github.com/matheusbrramos/ProductFlow_Claude_V4.git

# Instale em um projeto existente
.\ProductFlow_Claude_V4\install.ps1 -Project "C:\caminho\do\seu\projeto"

# Ou instale em um projeto novo
mkdir meu-projeto
.\ProductFlow_Claude_V4\install.ps1 -Project "meu-projeto"

# Entre no projeto e inicie (via Git Bash ou WSL)
cd meu-projeto
bash start.sh
```

> **Dica Windows:** clique com o botão direito no PowerShell e selecione "Executar como Administrador" se aparecer erro de permissão de execução. Ou rode antes: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### Instalar no macOS / Linux

```bash
# Clone o repositório
git clone https://github.com/matheusbrramos/ProductFlow_Claude_V4.git

# Instale no seu projeto
bash ProductFlow_Claude_V4/install.sh /caminho/do/seu/projeto

# Entre no projeto e inicie
cd /caminho/do/seu/projeto
bash start.sh
```

### Verificar instalação

```bash
# Deve listar os scripts instalados
ls scripts/

# Deve exibir o menu do assistente
bash start.sh
```

---

## Estrutura do Repositório

```
pm-builder/
├── start.sh                     # Ponto de entrada — assistente PM
├── install.sh                   # Instalador — macOS/Linux
├── install.ps1                  # Instalador — Windows (PowerShell)
│
├── scripts/
│   ├── research.sh              # Pesquisa com Haiku + Sonnet
│   ├── prd.sh                   # PRD com Opus
│   ├── blueprint.sh             # Blueprint + todo.md com Sonnet + Haiku
│   ├── codegen.sh               # Implementação iterativa com Sonnet
│   ├── review.sh                # Revisão com Sonnet / Opus
│   ├── docs.sh                  # Documentação com Sonnet
│   │
│   └── lib/
│       ├── scan_project.py      # Scan local de projeto (zero tokens)
│       ├── extract_context.py   # Extração cirúrgica de contexto (zero tokens)
│       └── todo_manager.py      # Gerenciamento de estado (zero tokens)
│
├── templates/
│   ├── CLAUDE.md                # Template de contexto do projeto
│   └── agents.md                # Template de lições aprendidas
│
└── docs/
    ├── token-strategy.md        # Estratégia detalhada de economia de tokens
    ├── pm-guide.md              # Guia para PMs não técnicos
    └── dev-guide.md             # Guia para desenvolvedores
```

---

## Documentação

- 📖 [Guia para PMs](./docs/pm-guide.md) — Como usar sem conhecimento técnico
- 🔧 [Guia para Devs](./docs/dev-guide.md) — Customização e uso avançado dos scripts
- 💰 [Estratégia de Tokens](./docs/token-strategy.md) — Detalhes de cada decisão de economia
- 🤝 [Como Contribuir](./CONTRIBUTING.md)

---

## Compatibilidade

| Ferramenta | Status | Observação |
|---|---|---|
| Claude Code CLI | ✅ Suporte completo | Referência — otimizado para esta plataforma |
| macOS | ✅ | Testado |
| Linux | ✅ | Testado |
| Windows (nativo) | ✅ | `install.ps1` para instalação + Git Bash para executar scripts |
| Windows (WSL) | ✅ | Suporte completo via WSL2 |

---

## Contribuindo

Contribuições são muito bem-vindas — especialmente:

- Novos templates de entrevista para tipos de produto específicos
- Otimizações de prompt para redução de tokens
- Adaptações para outros CLIs de IA (Gemini CLI, Codex)
- Melhorias no `todo_manager.py` e `extract_context.py`

```bash
# Fork e clone
git clone https://github.com/matheusbrramos/ProductFlow_Claude_V4.git

# Crie sua branch
git checkout -b feature/minha-melhoria

# Commit e PR
git commit -m "feat: descrição da melhoria"
git push origin feature/minha-melhoria
```

Veja [CONTRIBUTING.md](./CONTRIBUTING.md) para diretrizes detalhadas.

---

## Licença

MIT — veja [LICENSE](./LICENSE) para detalhes.

---

## Por que isso importa

O gap entre ter uma ideia e ter software funcionando nunca foi maior. PMs passam semanas escrevendo documentos que devs interpretam de formas diferentes. Devs perdem contexto entre sessões. Tokens são desperdiçados em contexto redundante.

O PM Builder resolve os três problemas: a entrevista socrática captura a intenção antes do PRD, os documentos encadeados garantem que nenhum agente precise "adivinhar" contexto, e o Python elimina tokens desnecessários antes de qualquer chamada ao modelo.

O resultado é um PM que constrói, e um dev que não perde tempo.

---

**[⬆ Voltar ao topo](#pm-builder--ai-agent-system-for-claude-code-)**
