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