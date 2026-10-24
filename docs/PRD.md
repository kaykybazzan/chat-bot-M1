# PRD — Construtor Visual de Chatbot para WhatsApp

**Versão:** 1 — Rascunho para revisão  
**Data:** 14/10/2026  
**Autor:** Kayky Bazzan  
**Nome do projeto:** A definir

---

## 1. Visão

### 1.1. O que é

Uma plataforma web em que o dono de um pequeno comércio monta, em um editor visual, o fluxo de conversa do atendimento: mensagens, botões, perguntas, condições e, se couber, chamadas a uma URL.

O bot executa esse fluxo com os clientes, primeiro em um simulador de chat na web e depois pelo WhatsApp. Cada conversa fica registrada em um painel que o dono consulta posteriormente.

### 1.2. Usuário-alvo

**Hipótese, ainda sem validação.**

Dono de pequeno comércio local (barbearia, pizzaria, loja) que responde todos os dias às mesmas perguntas — horário, endereço, preços e cardápio — e perde recados quando está ocupado.

### 1.3. Por que o projeto existe

Aprender construindo o que ferramentas maduras já fazem por dentro:

- Máquina de estados por conversa.
- Webhooks.
- Idempotência.
- Concorrência.
- Filas.
- Segurança de integrações.
- Editor de grafos.

Já existem concorrentes gratuitos e consolidados, como o Typebot, que é open source e possui editor visual.

O projeto não pretende substituí-los, e o README deve deixar isso claro.

---

## 2. Objetivos

### 2.1. Aprendizado

- Modelagem de dados e regras de negócio.
- Estado persistente por conversa.
- Webhooks de entrada e saída.
- Desduplicação e concorrência.
- Filas e retentativas.
- Segurança de integrações.
- Testes automatizados.
- Docker e CI.
- Editor de grafos no front-end com Next.js e TypeScript.

### 2.2. Produto

Cada item abaixo deve resultar em um teste ou uma demonstração.

- [ ] Um fluxo montado no editor roda do início ao fim no simulador.
- [ ] A mesma mensagem recebida duas vezes gera apenas uma resposta.
- [ ] Duas mensagens simultâneas da mesma conversa são processadas em ordem.
- [ ] Reiniciar o servidor durante um atendimento não perde o estado.
- [ ] O dono vê no painel o histórico completo e os dados coletados.
- [ ] O mesmo fluxo funciona pelo WhatsApp, com envio e recebimento de mensagens, sujeito à regra de corte da seção 10.

---

## 3. Restrições e suposições

- Um desenvolvedor, com disponibilidade variável e sem prazo rígido. O progresso é medido por marcos (seção 10), não por datas.
- Custo zero, se possível. Para o WhatsApp, utilizar o número de teste da Meta.
- Dados fictícios. Nenhum número de telefone real de terceiros no repositório ou nos testes.
- Sem validação de mercado.
- Regras do WhatsApp que moldam o projeto:
  - Respostas livres somente dentro da janela de 24 horas após a última mensagem do cliente.
  - Mensagens iniciadas pelo negócio exigem modelos aprovados.
  - Preços e regras da Meta mudam e devem ser confirmados na documentação oficial antes de depender deles.
- Se a conta de desenvolvedor da Meta não puder ser criada devido a alguma exigência da plataforma, o simulador mantém o projeto funcional e o canal real fica para depois.

---

## 4. História de ponta a ponta

A v1 é definida pela seguinte história. Se ela funcionar integralmente, sem funcionalidades pendentes, a v1 estará pronta.

1. O dono de uma barbearia fictícia cria uma conta e entra.
2. Monta no editor um fluxo com boas-vindas e um menu com botões:
   - Horários.
   - Preços.
   - Endereço.
   - Deixar recado.
3. Publica o fluxo.
4. Testa no simulador de chat.
5. Um cliente escreve pelo WhatsApp e conversa com o bot.
6. O dono abre o painel e vê o atendimento e o recado deixado.

---

## 5. Histórias de usuário e critérios de aceitação

### H1 — Montar o fluxo

**Como** dono de barbearia, **quero** arrastar blocos e conectá-los para definir o que o bot responde, sem escrever código.

**Critérios de aceitação:**

- Consigo criar, conectar e apagar blocos.
- Um fluxo inválido, sem início ou com blocos soltos, não pode ser publicado.
- Os erros são apresentados com mensagens claras.

### H2 — Testar antes de publicar para clientes

**Como** dono, **quero** conversar com o bot no simulador antes de colocá-lo no WhatsApp.

**Critério de aceitação:**

- O simulador utiliza o mesmo motor do canal real e apresenta o mesmo comportamento.

### H3 — Atender o cliente

**Como** cliente, **quero** escolher uma opção do menu e receber a resposta correta, mesmo que eu demore a responder.

**Critério de aceitação:**

- A conversa continua do ponto em que parou, desde que eu responda em até 24 horas.

### H4 — Ver o que aconteceu

**Como** dono, **quero** abrir um painel e ver quem falou com o bot, o que foi dito e quais recados foram deixados.

**Critérios de aceitação:**

- A lista mostra os atendimentos com estado e data.
- O detalhe mostra o histórico completo e os dados coletados.

### H5 — Isolamento

**Como** usuário, **quero** que ninguém veja meus fluxos ou meus atendimentos.

**Critério de aceitação:**

- Um teste comprova que o usuário A não consegue acessar os dados do usuário B.

---

## 6. Escopo da v1

### 6.1. Essencial — nunca sai

- Conta e login, com cada usuário acessando somente os próprios dados.
- Editor visual com os seguintes blocos:
  - Início.
  - Mensagem.
  - Botões.
  - Perguntar e guardar resposta.
  - Condição.
  - Fim.
- Motor de conversa com estado salvo no banco de dados.
- Simulador de chat na web.
- Painel de atendimentos, com lista e detalhe.

### 6.2. Importante, mas cortável

- Canal WhatsApp, respondendo apenas a quem escreve primeiro.
- Bloco "Chamar URL".
- Publicação que congela a versão do fluxo.

### 6.3. Fora da v1

- Pagamentos.
- IA conversando livremente.
- Mídia (imagens e áudio).
- Múltiplos canais.
- Transferência para atendente humano e resposta pelo painel.
- Envio em massa.
- Mensagens iniciadas pelo negócio.
- Equipes com vários usuários.
- Cofre de segredos.
- Gráficos, métricas, exportação e etiquetas.
- Notificação ao dono quando um novo recado chegar.
- Vários fluxos ativos por conta.

### 6.4. Ordem de corte se o tempo apertar

1. Bloco "Chamar URL".
2. Canal WhatsApp: o projeto é concluído com o simulador.
3. Condição, mantendo somente os botões como mecanismo de ramificação.

---

## 7. Decisões de projeto

### D1 — Fluxo como grafo

Cada bloco aponta para o próximo. Botões e condições criam ramificações.

Ciclos são permitidos, como voltar ao menu, mas existe um limite de blocos executados por mensagem recebida (valor a definir) para impedir laços infinitos.

### D2 — Estado no banco

Cada atendimento guarda o bloco atual e as variáveis coletadas.

Uma nova mensagem do cliente retoma a execução a partir do bloco que estava aguardando uma resposta.

### D3 — Variáveis e condições sem `eval`

Os textos aceitam variáveis no formato `{{nome}}`.

Uma condição é composta por:

- Variável.
- Operador.
- Valor.

Os operadores são predefinidos. Nunca se executa código escrito pelo usuário.

### D4 — Canal como adaptador

O núcleo do motor é independente de HTTP e de banco de dados.

Ele recebe o estado e uma mensagem de entrada normalizada e devolve o novo estado e as mensagens de saída.

O simulador e o WhatsApp implementam a mesma interface.

### D5 — Entrega "pelo menos uma vez"

Mensagens de entrada são desduplicadas pelo identificador fornecido pelo canal.

**Limite conhecido:** se o sistema cair depois de enviar uma mensagem e antes de registrar o envio, a mensagem poderá ser enviada novamente.

Esse comportamento deve ser documentado no README.

### D6 — Uma mensagem por vez por atendimento

Mensagens do mesmo atendimento são processadas em sequência, utilizando bloqueio por atendimento, nunca em paralelo.

### D7 — Fluxo publicado é versionado

Um atendimento em andamento termina utilizando a versão do fluxo com que começou.

Editar o fluxo não quebra conversas abertas.

### D8 — Um fluxo ativo por conta na v1

Cada conta pode ter apenas um fluxo ativo na primeira versão.

### D9 — Atendimento e estados

Um atendimento é uma conversa entre um cliente e o bot.

Uma nova mensagem continua o atendimento existente se ele ainda não terminou e a última mensagem do cliente foi recebida há menos de 24 horas. Caso contrário, começa um novo atendimento, do início do fluxo.

#### Estados do atendimento

| Estado | Descrição |
|---|---|
| Concluída | O fluxo chegou ao bloco de fim. |
| Em andamento | O fluxo não terminou e o cliente respondeu nas últimas 24 horas. |
| Expirada | O fluxo não terminou e passaram-se mais de 24 horas sem resposta do cliente. |

O estado é calculado no momento da exibição, com base em duas informações:

- Se o fluxo terminou.
- Quando ocorreu a última mensagem do cliente.

Não é necessária uma rotina agendada.

O sistema sabe há quanto tempo o cliente não responde, mas não sabe se ele desistiu. Por isso, o estado se chama "expirada", e não "abandonada".

O limite de 24 horas é fixo na v1.

**Limite conhecido:** se o cliente responder após 24 horas, o atendimento recomeça do zero.

---

## 8. Requisitos funcionais

| Funcionalidade | Como funciona | Comportamento em caso de falha |
|---|---|---|
| Conta e login | Cadastro, entrada e sessão; cada recurso pertence a um usuário. | Acesso a recurso alheio retorna `404`. |
| Editor visual | Biblioteca de grafos pronta; lê e escreve o JSON do fluxo. | Fluxo inválido não pode ser publicado. |
| Validação do fluxo | Um único início; sem blocos soltos; todo caminho chega a um fim; botões dentro do limite do canal, a confirmar na documentação da Meta. | Erro aponta o bloco problemático. |
| Motor de conversa | Executa blocos até precisar de resposta do cliente e salva o estado. | Limite de blocos interrompe o laço e registra o erro. |
| Simulador web | Chat que usa o mesmo motor e a mesma interface de canal. | Não aplicável. |
| Canal WhatsApp | Webhook com verificação de assinatura e envio pela API. | Assinatura inválida retorna `401`; falha de envio gera retentativa com espera crescente. |
| Fila de saída | Mensagens enviadas por um worker, com fila em uma tabela do PostgreSQL. | Reserva vencida devolve o trabalho à fila. |
| Painel — lista | Todos os clientes que escreveram, do mais recente ao mais antigo, com origem (WhatsApp ou simulador), estado, data da última mensagem e indicação de recado. Inclui filtros por estado e por "tem recado". | Não aplicável. |
| Painel — detalhe | Histórico completo das mensagens do cliente e do bot, em ordem cronológica, com horário e indicação de como foram enviadas; inclui resumo dos dados coletados. | Não aplicável. |
| Bloco "Chamar URL" (cortável) | Somente HTTPS; bloqueio de endereços internos verificado após resolver o nome; sem seguir redirecionamentos; timeout e limite de tamanho da resposta. | Erro é atribuído a uma variável e o fluxo segue por um ramo de erro. |

---

## 9. Requisitos não funcionais

### 9.1. Segurança

- Verificação da assinatura dos webhooks.
- Senhas armazenadas com hash.
- Autorização testada em todas as rotas.
- Proteção contra SSRF no bloco de URL.
- Segredos armazenados somente em variáveis de ambiente, nunca no repositório.

### 9.2. Confiabilidade

- Nenhum estado crítico pode existir somente em memória.
- Reiniciar o servidor não pode causar perda dos atendimentos.

### 9.3. Observabilidade

- Logs estruturados.
- Histórico de erros por atendimento.

### 9.4. Privacidade

A v1 utiliza somente dados de teste.

O README registra que um uso real exigiria atenção à LGPD e uma política de retenção das conversas.

### 9.5. Testes automatizados

Devem existir testes para:

- Regras do motor.
- Desduplicação.
- Concorrência.
- Retomada de atendimentos.
- Autorização.
- Validação do fluxo.

---

## 10. Marcos e critérios de pronto

### 10.1. Marcos

Os marcos não possuem datas e devem ser executados na ordem abaixo.

#### M0 — Teste de viabilidade do WhatsApp

Enviar e receber uma mensagem pelo número de teste, utilizando código descartável.

Se não for possível, o M3 é retirado do escopo e o projeto segue com o simulador.

#### M1 — Motor e simulador

Implementar o motor e o simulador com o fluxo em JSON, ainda sem editor visual.

Os testes de concorrência, desduplicação e retomada devem passar.

#### M2 — Editor visual e painel

Implementar o editor visual e o painel.

Só começa quando o M1 cumprir todos os critérios.

#### M3 — Canal WhatsApp

Integrar o WhatsApp ao mesmo motor utilizado pelo simulador.

#### M4 — Acabamento

- Docker.
- CI.
- Demonstração.
- README.

### 10.2. Critérios de pronto

- [ ] Testes passando e CI verde.
- [ ] Mensagem duplicada gera somente uma resposta.
- [ ] Mensagens simultâneas são processadas em ordem.
- [ ] O servidor reiniciado retoma o atendimento.
- [ ] Assinatura inválida é recusada.
- [ ] O usuário A não consegue ler os dados do usuário B.
- [ ] Fluxo inválido não pode ser publicado.
- [ ] Laço infinito é interrompido.
- [ ] O estado "expirada" aparece após 24 horas sem resposta.
- [ ] `docker compose up` sobe o sistema do zero.
- [ ] Existe uma demonstração com um fluxo de uma barbearia fictícia, contemplando horários, serviços e preços, endereço e a opção "deixar recado".
- [ ] A documentação está disponível em `docs/`, contendo:
  - PRD.
  - Modelo de banco de dados.
  - Arquitetura.
  - Decisões de arquitetura (ADRs).
  - Problemas e aprendizados.
- [ ] O README explica o que é o projeto, como executá-lo e quais são seus limites conhecidos.

### 10.3. Regra de corte

Se o M3 for inviável, o projeto é concluído com o simulador. Essa limitação deve ser comunicada claramente no README.

---

## 11. Riscos

### 11.1. WhatsApp

**Risco:** configuração da Meta, mudanças nas regras e nos preços e exigências relacionadas à conta.

**Mitigação:** executar o M0 no começo e manter o simulador como plano B.

### 11.2. Editor visual

**Risco:** o editor é parte importante do produto e pode consumir mais tempo do que o previsto.

**Mitigação:** utilizar poucos blocos, uma biblioteca de grafos pronta e desenvolver o motor antes do editor.

### 11.3. Concorrência de mercado

**Risco:** existência de concorrentes maduros e gratuitos.

**Mitigação:** assumir e documentar o objetivo de aprendizado no README.

### 11.4. Crescimento do escopo

**Risco:** inclusão contínua de funcionalidades que comprometem a conclusão da v1.

**Mitigação:** respeitar a ordem de corte e a lista de funcionalidades fora da v1.

---

## 12. Em aberto

- [ ] Nome do projeto.
- [ ] Exemplo de demonstração: a barbearia fictícia serve?
- [ ] Valor do limite de blocos por mensagem.
- [ ] Back-end separado do Next.js ou implementado dentro dele. Essa deve ser a primeira decisão de arquitetura, registrada em uma ADR.

---

## 13. Próximos documentos

Depois deste PRD, produzir os seguintes documentos:

1. Modelo de banco de dados, que deve ser desenhado antes do M1.
2. Arquitetura de uma página.
3. Primeiras ADRs (Architecture Decision Records).
4. Esqueleto do README.