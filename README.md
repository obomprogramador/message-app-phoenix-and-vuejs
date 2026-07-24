# Message App

Aplicacao de mensagens com Phoenix + Vue 3.

## Pre-requisitos

- Docker
- Docker Compose

## Como levantar

1. Copie o arquivo de variaveis de ambiente:

```bash
cp .env.example .env
```

2. Suba todos os servicos:

```bash
docker compose up --build
```

O `SECRET_KEY_BASE` e gerado automaticamente pelo container na primeira execucao.

## Servicos

| Servico | Container | URL |
|---|---|---|
| Frontend | message_app_frontend | http://localhost:8080 |
| Backend | message_app_backend | http://localhost:4000 |
| PostgreSQL | message_app_database | localhost:5432 |

## Ordem de subida

1. PostgreSQL inicia e passa no healthcheck
2. Backend aguarda o PostgreSQL, roda migrations e inicia o servidor
3. Frontend inicia o nginx

## Como testar conversas

O frontend usa a URL `http://localhost:8080/<contact_id>` para abrir uma conversa. Para descobrir os IDs dos usuarios de teste, veja o log do backend:

```bash
docker compose logs backend | grep "Para testar"
```

A saida sera algo como:

```
   Para testar conversas, acesse:
   http://localhost:8080/016f8678-6039-42c5-aa0a-4986151f8bcd  (@usuario.1)
   http://localhost:8080/aaf53095-c16b-4c96-9fcd-3a0da3ce606b  (@usuario.2)
   http://localhost:8080/0366bdf4-114c-41f6-ab65-b0a5096fc571  (@usuario.3)
```

Copie qualquer URL e abra no navegador. Os 3 usuarios ja possuem contatos vinculados e mensagens de exemplo entre si.

## Comandos uteis

```bash
# Subir em background
docker compose up -d --build

# Parar todos os servicos
docker compose down

# Parar e limpar volumes (apaga dados do banco)
docker compose down -v

# Ver logs de um servico
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f postgres

# Rodar testes com coverage (backend)
docker compose exec -e MIX_ENV=test backend mix coveralls

# Ver IDs para testar conversas
docker compose logs backend | grep "Para testar"
```
