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