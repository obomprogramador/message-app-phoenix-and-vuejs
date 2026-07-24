# Backend - Message App

API REST + WebSocket em Elixir/Phoenix.

## Como levantar (standalone)

```bash
# Instalar deps e configurar banco
mix setup

# Rodar o servidor (porta 4000)
mix phx.server
```

O comando `mix setup` executa `deps.get`, cria o banco, roda migrations e seeds automaticamente.

### Comandos uteis

```bash
# Rodar testes com coverage
MIX_ENV=test mix coveralls

# Rodar testes
MIX_ENV=test mix test

# Recriar banco do zero
mix ecto.reset

# Compilar sem warnings
mix compile --warnings-as-errors

# Lint (Credo)
mix credo

# Tipos (Dialyzer)
mix dialyzer
```

### Variaveis de ambiente

| Variavel | Padrao | Descricao |
|---|---|---|
| `PGHOST` | `localhost` | Host do PostgreSQL |
| `DATABASE_URL` | - | URL completa do banco (producao) |
| `SECRET_KEY_BASE` | - | Chave secreta do Phoenix (producao) |
| `PORT` | `4000` | Porta do servidor |

## Arquitetura

### Paradigma funcional

O projeto foi projetado para obedecer o maximo o paradigma funcional oferecido pela linguagem Elixir, sem a complexidade do OOP. Algumas decisoes:

- **Sem classes nem heranca**: modulos Elixir sao funcoes puras organizadas por contexto (`Contacts`, `Messages`, `Groups`). Cada contexto e um namespace isolado, nao uma classe.
- **Imutabilidade por padrao**: dados nao sao alterados em lugar nenhum. Transformacoes criam novos maps/structs via pipe operator (`|>`).
- **Pattern matching em vez de if/else**: erros, condicoes e encaminhamento sao feitos via `case`, `with` e clausulas de funcao, nao por excecoes ou condicionais aninhadas.
- **Recursao em vez de loops**: paginacao e processamento de listas usam recursao e `Enum`/`Stream`, nao for/while.
- **Atoms e tuples para resultado**: erros retornam `{:error, :not_found}` ou `{:error, :already_linked}`, nao excecoes. Sucesso retorna `{:ok, valor}`.
- **Pipe operator**: fluxo de dados de cima pra baixo, sem variaveis intermediarias.

### Principios aplicados

- **SOLID**: responsabilidade unica por funcao, inversao de dependencia via `action_fallback`, acoplamento fraco entre contextos.
- **Big O notation**: operacoes criticas foram pensadas para manter complexidade controlada:
  - Busca por ID: **O(1)** via `Repo.get/2` (chave primaria).
  - Listagem com paginacao: **O(n)** onde n = `per_page` (nunca carrega tudo).
  - Busca por nickname: **O(1)** com indice unico no banco.
  - Link/unlink: **O(1)** por operacao (delete direto por PK composta).
  - Mensagens de conversa: **O(n)** com ORDER BY e LIMIT, sem subqueries correlated.

### Contextos (bounded contexts)

```
lib/message_app/
  contacts/       -> Contact, ContactLink, Contacts (business logic)
  messages/       -> Message, Messages (business logic)
  groups/         -> Group, GroupMember, GroupMessage, Groups (business logic)
```

### Camadas

```
Router -> Controller -> Context -> Repo -> PostgreSQL
                         |
                    Channel (WebSocket)
```

- **Router**: define rotas REST (`/api/contacts`, `/api/messages`, `/api/groups`).
- **Controller**: valida input, delega para Context, renderiza JSON.
- **Context**: logica de negocio (link, unlink, enviar mensagem).
- **Repo**: acesso a banco via Ecto.
- **Channel**: tempo real via Phoenix Channels (`messages:*`, `group:*`).

## Coverage

Coverage minimo exigido: **80%**.

```bash
MIX_ENV=test mix coveralls
```

Resultado atual: ~84.5%.
