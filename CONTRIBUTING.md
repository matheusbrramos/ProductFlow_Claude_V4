# Contribuindo com o PM Builder

Obrigado pelo interesse em contribuir! Este guia explica como participar.

## Tipos de contribuição bem-vindos

- **Novos templates de entrevista** — perguntas específicas para tipos de produto (SaaS, marketplace, automação interna)
- **Otimizações de prompt** — redução de tokens mantendo qualidade
- **Adaptações para outros CLIs** — Gemini CLI, Codex, Cursor
- **Scripts Python** — melhorias no scan, extração de contexto e todo manager
- **Correções de bugs** — especialmente em compatibilidade de SO
- **Documentação** — guias para casos de uso específicos

## Processo

1. **Abra uma issue** antes de começar trabalho significativo — alinha expectativas
2. **Fork** o repositório
3. **Crie uma branch** descritiva: `feature/entrevista-saas`, `fix/windows-paths`, `docs/guia-pm`
4. **Commit** com mensagens claras seguindo [Conventional Commits](https://conventionalcommits.org):
   - `feat:` nova funcionalidade
   - `fix:` correção de bug
   - `docs:` documentação
   - `refactor:` refatoração sem mudança de comportamento
   - `perf:` melhoria de performance / economia de tokens
5. **Teste** em pelo menos um projeto real antes do PR
6. **Abra o PR** descrevendo o problema que resolve e como testar

## Princípios do projeto

- **Economia de tokens primeiro** — toda mudança deve justificar seu custo em tokens
- **Python para o que é determinístico** — se não precisa de LLM, não usa LLM
- **Haiku para triagem** — classificação e extração simples nunca usam modelos maiores
- **Opus cirúrgico** — apenas PRD e review crítico com `--deep`
- **Português para PMs** — toda comunicação com o usuário final em português

## Rodando localmente

```bash
git clone https://github.com/seu-usuario/pm-builder.git
cd pm-builder

# Crie um projeto de teste
mkdir /tmp/teste-pm
bash install.sh /tmp/teste-pm
cd /tmp/teste-pm

# Teste o fluxo completo
bash start.sh "quero criar um sistema de cadastro"
```

## Dúvidas

Abra uma [discussion](../../discussions) ou uma issue com a tag `question`.
