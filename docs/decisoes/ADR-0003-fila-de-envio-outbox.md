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