# Banco de dados

Modelo de dados do construtor visual de chatbot para WhatsApp,
em PostgreSQL. Ver `docs/prd.md` para o contexto do produto e
`docs/decisoes/` para o raciocínio por trás de cada escolha.

## Diagrama

[Diagrama do banco (PDF)](./documentos/banco-de-dados.pdf)

## Tabelas

### users
O dono do comércio, quem cria conta e faz login no sistema.

### flows
O fluxo de conversa ("o bot") de cada usuário. Na v1, cada usuário
tem no máximo um fluxo (ADR-0005 referencia esta regra; decisão
registrada como D8 no PRD).

### flow_versions
Cada versão publicada (ou em rascunho) de um fluxo. O grafo de
blocos e ligações fica guardado como JSON na coluna `definition`
(ADR-0002). Versionar permite editar o fluxo sem quebrar conversas
que já estão em andamento numa versão anterior.

### channels
De onde vêm as mensagens: o número de teste do WhatsApp ou o
simulador interno. Liga um identificador externo (o número) ao
usuário dono dele.

### contacts
Os clientes que conversam com o bot. Cada contato pertence a um
usuário específico, porque o mesmo número de telefone pode falar
com bots de donos diferentes.

### conversations
Cada atendimento entre um cliente e o bot: em que bloco do fluxo
ele está, quais dados já foram coletados, quando começou e quando
(se) terminou. O estado de "em andamento", "concluída" ou
"expirada" não é uma coluna — é calculado a partir de
`finished_at` e `last_customer_message_at` (ADR-0004).

### messages
O histórico de mensagens trocadas, do cliente e do bot, em ordem,
com horário. Não muda depois de criado.

### outbox
Fila de envio das mensagens de saída, com controle de tentativas e
reenvio. Separada de `messages` porque representa o *trabalho de
entregar*, que muda várias vezes, enquanto `messages` representa
*o que foi dito*, que não muda (ADR-0003).

## Restrições importantes

- **Mensagem duplicada é impedida pelo banco.** `messages.external_id`
  tem um índice único, então a mesma mensagem do WhatsApp recebida
  duas vezes nunca gera duas respostas.
- **Só uma versão publicada por fluxo por vez.** Um índice único
  parcial em `flow_versions` garante isso (ver nota da seção
  seguinte sobre limite do diagrama).
- **Isolamento entre usuários.** Uma chave estrangeira composta
  garante que uma conversa (`conversations.contact_id`,
  `conversations.user_id`) só pode apontar para um contato que
  realmente pertence àquele mesmo usuário (ADR-0005). Isso impede,
  a nível de banco, que um atendimento fique associado ao dono
  errado.
- **Um fluxo por conta na v1.** `flows.user_id` é único.

## Limite conhecido

Os índices únicos parciais (com condição `WHERE`) não têm
representação nativa no DBML, a linguagem do dbdiagram.io. Eles
aparecem só como anotação no diagrama. A versão real, em SQL, será
escrita quando o `schema.prisma` for criado, no início do M1.

## Decisões relacionadas

- ADR-0001 — PostgreSQL como único banco
- ADR-0002 — Grafo do fluxo em jsonb
- ADR-0003 — Fila de envio separada das mensagens
- ADR-0004 — Estado do atendimento calculado, não armazenado
- ADR-0005 — user_id repetido em conversations, com chave composta
- ADR-0007 — Row-Level Security adiada para depois da v1