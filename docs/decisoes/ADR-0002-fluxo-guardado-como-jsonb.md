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