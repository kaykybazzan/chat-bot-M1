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