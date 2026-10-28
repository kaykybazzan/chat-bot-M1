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