<img width="1919" height="969" alt="Captura de tela de 2026-07-23 15-46-27" src="https://github.com/user-attachments/assets/247def6f-642d-48f9-a314-3b1936adc64a" />
<img width="1919" height="969" alt="Captura de tela de 2026-07-23 15-46-35" src="https://github.com/user-attachments/assets/3244d860-e369-4244-87d5-ef5c13d05c43" />


# Message App

Aplicacao de mensagens com Phoenix + Vue 3.

[![Backend CI](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/backend.yml/badge.svg)](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/backend.yml)
[![Frontend CI](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/frontend.yml/badge.svg)](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/frontend.yml)
[![Docker Build](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/docker.yml/badge.svg)](https://github.com/obomprogramador/message-app-phoenix-and-vuejs/actions/workflows/docker.yml)

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

## Demo ativa no Render

O projeto esta disponivel em uma demo hospedada no **Render** (plano free).

| Servico | URL |
|---|---|
| Frontend | https://message-app-frontend-w4bu.onrender.com |
| Backend | https://message-app-backend-o3ly.onrender.com |
| Health Check | https://message-app-backend-o3ly.onrender.com/api/health |

### URLs para testar conversas

Abra qualquer uma no navegador:

```
https://message-app-frontend-w4bu.onrender.com/c39296b5-a44f-4b09-9263-ab3ef92e879c  (@usuario.1)
https://message-app-frontend-w4bu.onrender.com/7a114a97-0581-4890-94a3-d7a7e5e5e52c  (@usuario.2)
https://message-app-frontend-w4bu.onrender.com/47c626fb-7bcd-4aca-89cb-ae67264924a9  (@usuario.3)
```

> **Atencao:** O plano free do Render suspende os servicos apos 15 minutos de inatividade.
> Se as URLs acima nao estiverem funcionando, entre em contato com o desenvolvedor
> para reativar o deploy no Render.

## Fluxo de trabalho com Git e Semantic Release

### Branches

```
develop  (instavel, sem protecao)
   |
   | PR (3 aprovacoes obrigatorias)
   v
staging  (protegida, coverage >= 80%)
   |
   | PR (merge direto)
   v
main     (protegida, versao e tags)
```

| Branch | Protecao | Regras |
|---|---|---|
| `develop` | Nenhuma | Branch instavel, commits livres |
| `staging` | Reforcada | PRs vindos de `develop`, 3 aprovacoes, coverage >= 80%, conversacoes resolvidas |
| `main` | Moderada | PRs vindos de `staging`, merge direto (sem aprovacao) |

### Fluxo do dia a dia

```bash
# 1. Crie uma branch a partir de develop
git checkout develop
git pull origin develop
git checkout -b feat/minha-feature

# 2. Faca commits seguindo o padrao conventional commits
git commit -m "feat: add user avatar upload"
git commit -m "fix: correct avatar crop size"
git commit -m "feat: add avatar preview"

# 3. Abra PR de feat/minha-feature -> develop
#    (PR normal, sem restricoes especiais)

# 4. Quando estiver pronto para subir, va de develop -> staging
#    PR de develop -> staging (requer 3 aprovacoes)

# 5. Quando estiver pronto para publicar, va de staging -> main
#    PR de staging -> main (merge direto)
#    Semantic Release detecta os commits, gera versao, CHANGELOG e tag
```

### Conventional Commits

O Semantic Release usa o padrao **Conventional Commits** para decidir qual numero da versao incrementar:

```
<type>: <descricao>

[opcional: corpo com BREAKING CHANGE]
```

| Tipo | Acao na versao | Exemplo |
|---|---|---|
| `feat:` | Minor (`1.0.0` -> `1.1.0`) | `feat: add login with Google` |
| `fix:` | Patch (`1.0.0` -> `1.0.1`) | `fix: correct button alignment` |
| `BREAKING CHANGE` | Major (`1.0.0` -> `2.0.0`) | `feat: rewrite auth\n\nBREAKING CHANGE: new token format` |

Outros tipos como `chore:`, `docs:`, `refactor:`, `style:`, `test:` nao disparam release.

### O que acontece ao mergear em main

1. Semantic Release analisa todos os commits do merge
2. Decide se incrementa **patch**, **minor** ou **major**
3. Atualiza `backend/mix.exs`, `frontend/package.json` e `package-lock.json`
4. Gera/atualiza `CHANGELOG.md`
5. Cria commit de release com `[skip ci]`
6. Cria a tag (ex: `v1.1.0`) e o GitHub Release
```
