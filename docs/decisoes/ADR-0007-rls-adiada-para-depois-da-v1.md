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