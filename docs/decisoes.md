# ADR-0001: Usar PostgreSQL como único banco de dados
Status: aceita
Data: 2026-10-15

## Contexto
O sistema precisa de três garantias:
1. Quando duas mensagens do mesmo cliente chegam ao mesmo tempo, elas
   devem ser processadas em ordem, nunca juntas.
2. A mesma mensagem do WhatsApp não pode gerar duas respostas, mesmo
   que o WhatsApp a reenvie.
3. Se o servidor cair no meio do processamento de uma mensagem, nada
   deve ficar gravado pela metade.
Além disso, os dados são fortemente ligados entre si (usuário, fluxo,
atendimento, mensagem), e o fluxo do bot precisa ser guardado como um
formato flexível (JSON), mas ainda ser consultável.

## Decisão
Usar PostgreSQL como único banco de dados do projeto, sem um segundo
banco NoSQL.

## Alternativas consideradas
- MySQL: também é relacional e atenderia aos relacionamentos entre as
  tabelas. Ponto a favor dele: é mais simples e teria sido suficiente
  se o projeto não precisasse de índice sobre dados dentro de um JSON.
  Ponto contra: o MySQL guarda JSON como texto e não permite indexar
  campos dentro dele, enquanto o PostgreSQL tem o tipo jsonb, que
  permite indexar e consultar dentro do JSON. Isso importa porque o
  fluxo do bot (D1) e as variáveis coletadas (D2) são guardados como
  JSON. O MySQL também guarda UUID como texto (CHAR(36)), enquanto no
  PostgreSQL é um tipo nativo, mais eficiente para buscas.
- MongoDB (NoSQL): seria natural para o JSON do fluxo, mas os dados do
  projeto são fortemente relacionados (usuário → fluxo → atendimento
  → mensagem), e eu precisaria de transações e de restrições de
  integridade entre essas tabelas, o que é mais natural num banco
  relacional.

## Consequências
Positivo: um único banco atende tanto aos dados relacionais (usuários,
atendimentos, mensagens) quanto ao JSON do fluxo, com o tipo jsonb.
Isso simplifica o `docker compose`: só um serviço de banco.

Limite: não tenho ainda a certeza do desempenho do PostgreSQL com
grande volume de mensagens (milhões de linhas), porque não testei.

Eu reconsideraria esta decisão se, medindo o sistema, encontrasse um
gargalo real de escrita ou leitura que um ajuste de índices não
resolvesse, e aí avaliaria separar o histórico de mensagens para outro
armazenamento.



# ADR-0002: Grafo do fluxo guardado como jsonb, não em tabelas
Status: aceita
Data: 2026-10-20

## Contexto
O fluxo (D1) é um grafo de blocos e ligações, editado visualmente e
lido pelo motor a cada mensagem. É preciso decidir onde ele mora: uma
coluna jsonb com o grafo inteiro, ou tabelas separadas de blocos e
ligações (uma linha por bloco, uma por ligação).

## Decisão
Guardar o grafo inteiro como jsonb em flow_versions.definition.

## Alternativas consideradas
- Tabelas de blocos e ligações: permitiria consultas como "quantos
  fluxos usam o bloco X", mas o motor e o editor sempre leem e
  escrevem o grafo inteiro de uma vez, nunca um bloco isolado — então
  a tabela separada não traz ganho de consulta na v1, só mais joins.

## Consequências
Simplifica o motor e o editor: uma leitura, uma escrita.
Limite: o banco não valida a estrutura do grafo (um único início, sem
bloco solto); essa validação fica inteiramente no código.
Reconsideraria se precisasse consultar ou alterar blocos
individualmente sem carregar o fluxo inteiro.


# ADR-0003: Fila de envio (outbox) separada da tabela messages
Status: aceita
Data: 2026-10-20

## Contexto
Mensagens de saída pelo WhatsApp precisam de retentativa com espera
crescente e podem falhar e ser reenviadas. O histórico de mensagens
(messages) deve registrar fielmente o que foi dito.

## Decisão
Manter o controle de envio (status, tentativas, próximo horário,
erro) em uma tabela outbox própria, referenciando messages.

## Alternativas consideradas
- Colunas de status de envio dentro da própria messages: mais simples,
  mas mistura "o que foi dito" (histórico, não muda) com "o trabalho
  de entregar" (muda várias vezes), dificultando a leitura e podendo
  sujar o histórico com dados que servem só à entrega.

## Consequências
Histórico fica limpo e estável; a fila pode ser consultada e indexada
por status sem tocar em messages.
Custo: uma tabela a mais e uma junção a mais ao montar o detalhe do
atendimento.


# ADR-0004: Estado do atendimento calculado, não armazenado
Status: aceita
Data: 2026-10-20

## Contexto
Um atendimento pode estar concluído, em andamento ou expirado (sem
resposta do cliente há mais de 24 horas). É preciso decidir se esse
estado fica gravado numa coluna ou é calculado a partir de outros
dados.

## Decisão
Não guardar uma coluna de status. Calcular na hora de exibir, a partir
de finished_at e de last_customer_message_at comparados ao relógio
atual.

## Alternativas consideradas
- Coluna de status gravada: exigiria uma rotina periódica para marcar
  atendimentos como expirados, trazendo de volta a necessidade de um
  agendador, que foi cortado da v1.

## Consequências
Sem rotina em segundo plano; o painel sempre mostra o estado correto
no momento da consulta.
Custo: toda consulta que filtra por estado precisa repetir essa conta
(ex.: WHERE finished_at IS NULL AND last_customer_message_at < agora
- 24h), em vez de um simples WHERE status = 'expired'.


# ADR-0005: user_id repetido (denormalizado) em conversations
Status: aceita
Data: 2026-10-20

## Contexto
conversations já se liga a contact_id, e contacts já tem user_id. A
pergunta é se conversations também deveria guardar user_id
diretamente, ou buscar o dono sempre através de contacts.

## Decisão
Repetir user_id em conversations.

## Alternativas consideradas
- Buscar o dono via contact_id → contacts.user_id: evita duplicar o
  dado, mas obriga a juntar duas tabelas (join) toda vez que o painel
  lista os atendimentos de um usuário, que é a consulta mais comum do
  sistema.

## Consequências
A lista do painel (a consulta mais frequente) fica mais simples e
rápida, sem join.
Risco: as duas colunas podem ficar inconsistentes entre si. Mitigação:
usar uma chave estrangeira composta (contact_id, user_id) apontando
para uma chave única (id, user_id) em contacts, em vez de só confiar
em teste automatizado — assim o próprio banco recusa um conversations
cujo user_id não bata com o do contato.


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


# ADR-0007: Row-Level Security adiada para depois da v1
Status: aceita
Data: 2026-10-20

## Contexto
H5 exige que um usuário nunca acesse dados de outro. Isso pode ser
garantido só pela aplicação (sempre filtrando por user_id nas
consultas, com testes) ou reforçado pelo próprio PostgreSQL, com Row-
Level Security (RLS), que recusa linhas de outro usuário mesmo que o
código esqueça o filtro.

## Decisão
Na v1, confiar apenas na aplicação (filtro consistente por user_id em
toda consulta, coberto por testes). Avaliar RLS depois.

## Alternativas consideradas
- RLS desde o início: proteção mais forte, no próprio banco, mas
  costuma exigir configuração adicional com o Prisma e aumenta a
  complexidade antes de o motor básico estar funcionando.

## Consequências
V1 mais simples de configurar.
Risco aceito: um esquecimento de filtro no código vira uma falha de
segurança real. Mitigação: teste automatizado específico para H5 em
toda rota que devolve dados do usuário.
Reconsideraria ao preparar o sistema para dados reais de terceiros.


# ADR-0008: Autenticação entre Next.js e Express via JWT em cookie
Status: aceita (com pontos de implementação a resolver no M1)
Data: 2026-10-23

## Contexto
Next.js e Express são processos separados (ADR-0006), sem domínio
compartilhado natural entre si. O dono do comércio faz login uma vez
e precisa que toda chamada do Next.js ao Express prove que ele está
autenticado, sem repetir login a cada ação.

## Decisão
Autenticação via JWT, gerado pelo Express no login. O token é
guardado em um cookie controlado pelo Next.js, e enviado
explicitamente em cada requisição ao Express (nunca dependendo do
navegador mandar o cookie sozinho por trás das cenas).

A verificação de login acontece sempre no **servidor do Next.js**,
antes de qualquer página chegar ao navegador: o código React que roda
no cliente nunca precisa ler o token diretamente. Por isso, o cookie
é configurado com:

```javascript
res.cookie('token', jwt, {
  httpOnly: true,   // o JavaScript do navegador nunca lê o cookie
  secure: true,     // só é enviado por HTTPS (em produção)
  sameSite: 'lax'   // não é enviado em requisições vindas de outros sites
});
```

- **`httpOnly: true`** — como nenhuma verificação de login acontece
  no navegador, não há motivo para o JavaScript do cliente conseguir
  ler o cookie. Isso protege o token mesmo num cenário de XSS: ainda
  que um script malicioso seja injetado na página, ele não consegue
  acessar `document.cookie` para roubar o token.
- **`secure: true`** — sempre ativo em produção, já que o sistema
  roda em HTTPS. Em desenvolvimento local sem HTTPS, pode ficar
  desativado.
- **`sameSite: 'lax'`** — protege contra a maioria dos ataques CSRF,
  sem quebrar o uso normal da aplicação entre os dois domínios/portas
  do Next.js e do Express.

## Alternativas consideradas
- Sessão com cookie automático do navegador (modelo clássico,
  stateful): mais simples de configurar quando frontend e backend
  dividem o mesmo domínio, mas Next.js e Express rodam em
  portas/domínios diferentes, o que complica os atributos do cookie
  entre eles.
- JWT guardado em `localStorage`: mais simples de implementar no
  cliente, mas não funciona no lado do servidor do Next.js (server-
  side rendering), que é parte do que o Next.js oferece.
- JWT guardado em memória (variável comum, sem persistência):
  mais seguro contra roubo via XSS, mas perde o token a cada
  atualização de página, exigindo um refresh token para recuperar —
  complexidade desnecessária para o tamanho deste projeto.
- Backend salvando o JWT em cookie no próprio domínio do Express,
  sem o frontend precisar reenviá-lo: evita o envio manual, mas abre
  risco de CSRF (uma requisição disparada por outro site aproveitaria
  o cookie enviado automaticamente pelo navegador), exigindo uma
  camada extra de proteção (token CSRF) que o envio manual já evita
  por natureza.
- `httpOnly: false` (token legível pelo JavaScript do navegador):
  consideraria só se alguma funcionalidade exigisse o React do
  cliente lendo o token diretamente, o que não é o caso aqui — toda
  verificação de login passa pelo servidor do Next.js.

## Consequências
Next.js controla explicitamente quando envia o token, reduzindo risco
de CSRF sem precisar de uma camada adicional de proteção.

O token fica protegido mesmo num cenário de XSS, porque o JavaScript
do navegador nunca tem acesso a ele (`httpOnly`).

Como o JWT já é assinado por natureza, não é necessário assinar o
cookie por cima — essa camada do vídeo-fonte era para informação que
não estivesse já num formato assinado, o que não é o nosso caso.

Limite aceito: se, no futuro, alguma tela precisar que o React do
cliente leia o token diretamente (por exemplo, para atualizar algo na
tela sem recarregar a página), será necessário reabrir esta decisão.

## Pontos de implementação a resolver no M1 (não mudam esta decisão)
- **Expiração e renovação:** o JWT expira. Decidir se, ao expirar, o
  usuário simplesmente perde a sessão e loga de novo (mais simples,
  escolha inicial para a v1), ou se existe renovação automática via
  refresh token (mais complexo, adiado por ora).
- **CORS:** o Express precisa aceitar requisições vindas do domínio
  do Next.js, com `credentials` habilitado, para o cookie atravessar
  entre os dois processos. Configurar ao montar a API.

Reconsideraria esta ADR se o Next.js e o Express passassem a rodar
sob o mesmo domínio em produção (nesse caso, sessão simples voltaria
a ser uma opção mais direta).