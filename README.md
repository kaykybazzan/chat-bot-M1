# [nome do projeto]

Construtor visual de chatbot para WhatsApp. O dono de um pequeno
comércio monta, sem programar, um fluxo de atendimento automático
(horários, preços, dúvidas comuns) que roda de verdade no WhatsApp
dos clientes.

> Projeto de estudo. Não resolve uma dor de mercado validada — o
> objetivo é aprender construindo o que ferramentas como Zapier,
> n8n e Typebot fazem por dentro: motor de execução com estado,
> filas, retentativas, idempotência e um editor visual.

## Status

🚧 Em desenvolvimento. Ainda na fase de documentação e modelagem,
antes do código do motor.

- [x] PRD
- [x] Modelagem do banco de dados
- [x] Arquitetura
- [x] Decisões técnicas (ADRs)
- [ ] M1 — motor de conversa + simulador
- [ ] M2 — editor visual + painel
- [ ] M3 — canal WhatsApp
- [ ] M4 — Docker, CI, demo

## Stack

- **Frontend:** Next.js, TypeScript
- **Backend:** Express, TypeScript
- **Banco de dados:** PostgreSQL, Prisma
- **Canal:** WhatsApp Cloud API (Meta)

## Documentação

- [PRD](docs/prd.md) — o problema, o escopo, os critérios de pronto
- [Banco de dados](docs/banco-de-dados.md) — modelagem e diagrama
- [Arquitetura](docs/arquitetura.md) — as peças do sistema e os
  fluxos principais
- [Decisões técnicas](docs/decisoes/) — uma ADR por decisão
  importante, com o porquê e as alternativas consideradas

## Como rodar

_Em breve — o projeto ainda não tem código executável._

## Por que este projeto

Documentei o processo completo, do levantamento de requisitos à
primeira linha de código, porque uma parte do que eu queria aprender
aqui era justamente isso: pensar a arquitetura e as regras de negócio
antes de programar, mesmo usando IA para acelerar partes do
desenvolvimento.