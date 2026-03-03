# Guia para Product Managers

Este guia é para você que tem uma ideia de produto mas não sabe programar.
Sem jargão técnico — promessa.

## O que você vai conseguir fazer

Ao final deste guia, você vai conseguir:
- Transformar uma ideia em software funcionando
- Acompanhar o progresso da implementação
- Retomar o projeto a qualquer momento de onde parou
- Criar novas features sem depender de um desenvolvedor para começar

## Antes de começar

Você precisa ter o **Claude Code** instalado no seu computador.
Se ainda não tem, peça para alguém do time técnico instalar — é um único comando.

Depois, instale o PM Builder no seu projeto:
```bash
bash install.sh /caminho/da/sua/pasta
```

Pronto. É a última coisa técnica que você vai precisar fazer.

## Iniciando o assistente

Abra o terminal na pasta do seu projeto e digite:
```bash
bash start.sh
```

Uma tela de boas-vindas vai aparecer e o assistente vai fazer a primeira pergunta.

## A entrevista

O assistente vai fazer no máximo 8 perguntas, uma por vez.
Não existe resposta errada — quanto mais detalhes você der, melhor o resultado.

**Dicas para responder bem:**

- Pense no problema, não na solução. Em vez de "quero um formulário web", diga "nosso time perde 2 horas por semana aprovando despesas por email"
- Se não souber responder algo, diga. O assistente adapta as próximas perguntas
- Você pode escrever quanto quiser — respostas longas são bem-vindas
- Se quiser parar antes de 8 perguntas, escreva "pronto"

**Exemplos de boas respostas:**

❌ "Quero um sistema de aprovação"

✅ "Hoje quando alguém precisa aprovar uma despesa, manda um email para o gestor, que às vezes demora dias para responder, e aí a pessoa não sabe se pode comprar ou não. Já perdemos fornecedores por causa disso."

## O que acontece depois

Quando a entrevista terminar, você vai ver:

1. **Um resumo** do que foi entendido — leia e confirme se está correto
2. **Um plano** com as etapas de implementação
3. **A opção de iniciar** agora ou depois

Se escolher iniciar, o sistema vai começar a gerar o código automaticamente.
Você pode acompanhar o progresso no terminal.

## Retomando um projeto

Se precisar fechar o computador no meio do caminho, não tem problema.
Na próxima vez, é só rodar:

```bash
bash start.sh --continue
```

O assistente vai mostrar onde você parou e continuar de lá.

## Acompanhando o progresso

Para ver o status atual do projeto a qualquer momento:
```bash
bash start.sh --continue
```

Escolha a opção "Ver todo o progresso" para ver uma lista de tudo que já foi feito e o que falta.

## Criando uma nova feature

Quando o projeto estiver pronto e você quiser adicionar algo novo:
```bash
bash start.sh
```

O assistente vai detectar que já existe um projeto e vai perguntar se você quer criar uma nova feature.

## Perguntas frequentes

**O código gerado funciona de verdade?**
Sim. O sistema usa dados reais e APIs reais, não simulações.

**Posso mudar algo depois que o código for gerado?**
Sim. Mostre as alterações para o seu time técnico — o código gerado é um ponto de partida, não um produto final imutável.

**E se a entrevista não capturar tudo que eu precisava?**
Você pode rodar o assistente novamente para uma nova feature, ou pedir para o time técnico ajustar o `prd.md` que foi gerado.

**Quanto tempo leva?**
A entrevista leva de 5 a 15 minutos. A implementação depende da complexidade — de 20 minutos a algumas horas.

## Suporte

Se algo não funcionar como esperado, abra uma issue no repositório ou fale com seu time técnico mostrando a mensagem de erro.
