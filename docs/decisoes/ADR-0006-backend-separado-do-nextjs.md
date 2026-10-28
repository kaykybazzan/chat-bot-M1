
# ADR-0006: Back-end em processo separado do Next.js
Status: aceita
Data: 2026-10-20

## Contexto
O sistema precisa de um worker rodando continuamente (fila de envio,
outbox) e de conexões de webhook recebendo eventos a qualquer momento.
É preciso decidir se isso roda dentro das rotas de API do Next.js ou
em um servidor Node separado.

## Decisão
Back-end em um processo Express separado do Next.js, responsável pela
API, pelos webhooks e pelo worker. O Next.js cuida só do editor
visual, do simulador e do painel (front-end), falando com o Express
por HTTP.

## Alternativas consideradas
- Dentro do Next.js: um único projeto para subir, mas rotas de API do
  Next.js são pensadas para requisições curtas, não para um worker de
  longa duração processando uma fila continuamente. Também mistura a
  responsabilidade de servir páginas com a de processar mensagens,
  dificultando testar e entender cada parte isoladamente.
- Fastify: alternativa ao Express, mais recente e com desempenho um
  pouco melhor em benchmarks (não verificado por mim agora), mas eu já
  tenho mais familiaridade com Express, o que reduz risco de atraso no
  projeto.

## Consequências
Separa claramente "site e editor" (Next.js) de "motor e fila"
(Express): cada processo tem uma responsabilidade, o que facilita
testar, depurar e entender cada parte isoladamente.
Custo: mais uma peça no docker-compose e mais uma camada de deploy;
o front-end precisa chamar uma API externa em vez de rotas internas
do Next.js, exigindo cuidado com CORS e autenticação entre os dois.