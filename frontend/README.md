# Frontend - Message App

Scaffold do frontend com Vue 3, TypeScript e Tailwind CSS, servido via nginx em Docker.

## Stack

| Tecnologia | Versão | Descrição |
|---|---|---|
| Vue.js | 3.5 | Framework reativo |
| TypeScript | 5.8 | Tipagem estática |
| Tailwind CSS | 4.3 | CSS utility-first |
| Pinia | 4.0 | Gerenciamento de estado (Composition API style) |
| Phoenix Channels | 1.8 | WebSocket para mensagens em tempo real |
| Vite | 6.3 | Build tool e dev server |
| nginx | 1.27 | Servidor web e proxy reverso |
| Node.js | 22 | Runtime para build (Alpine) |

## Estrutura

```
frontend/
├── Dockerfile            # Build multi-stage (node + nginx)
├── nginx.conf            # Configuração HTTP/HTTPS
├── package.json          # Dependências e scripts
├── vite.config.ts        # Configuração do Vite + Tailwind
├── tsconfig.json         # Configuração TypeScript
├── certs/                # Certificados SSL autoassinados (gitignore)
│   ├── cert.pem
│   └── key.pem
└── src/
    ├── main.ts           # Entry point (Pinia + Router)
    ├── App.vue           # Componente raiz (<router-view />)
    ├── assets/
    │   ├── main.css      # Import do Tailwind
    │   ├── shared.css    # Estilos compartilhados (@apply)
    │   └── variables.css # CSS custom properties (design tokens)
    ├── router/
    │   └── index.ts      # Vue Router com navigation guard
    ├── pages/
    │   └── ChatPage.vue  # Orquestrador principal da SPA
    ├── types/            # Tipos de domínio (Contact, Message, Conversation)
    ├── api/              # Camada de API (HTTP client, mock fallback, transformers)
    ├── stores/           # Pinia stores (7 stores, Composition API style)
    ├── composables/      # Lógica reutilizável (9 composables, estilo Hooks)
    ├── services/
    │   └── socket.ts     # Phoenix Socket + Channel management
    ├── components/
    │   ├── atoms/        # Elementos básicos (6 componentes)
    │   ├── molecules/    # Composições de atoms (6 componentes)
    │   └── organisms/    # UI complexa (10 componentes)
    ├── constants/        # Textos estáticos (empty states)
    ├── data/             # Contatos mockados
    └── utils/            # Utilitários de formatação
```

## Como subir apenas o frontend

### Via Docker (recomendado)

```bash
# Na raiz do projeto
docker compose up -d --build frontend
```

| Protocolo | URL |
|---|---|
| HTTP | http://localhost:8080 |
| HTTPS | https://localhost:8443 |

> O HTTPS usa certificado autoassinado. O browser vai mostrar aviso — clique em "Avançado" → "Prosseguir".

### Local (desenvolvimento)

```bash
cd frontend
npm install
npm run dev
```

Acesse http://localhost:5173

## Scripts npm

| Comando | Descrição |
|---|---|
| `npm run dev` | Dev server com hot reload |
| `npm run build` | Type-check + build para produção |
| `npm run build-only` | Build sem type-check |
| `npm run type-check` | Verificação de tipos |
| `npm run preview` | Visualizar build de produção |

## Dockerfile (multi-stage)

**Build stage** (`node:22-alpine`):
- Instala dependências com `npm ci`
- Executa `npm run build` (type-check + vite build)

**Runner stage** (`nginx:1.27-alpine`):
- Copia os arquivos buildados de `dist/` para `/usr/share/nginx/html`
- Copia `nginx.conf` e certificados SSL
- Expõe portas 8080 (HTTP) e 443 (HTTPS)

## nginx.conf

- **Porta 8080**: Servidor SPA com `try_files` para Vue Router
- **Porta 443**: Mesma config + SSL com certificado autoassinado
- Cache de 1 ano para assets estáticos (js, css, imagens, fontes)
- Gzip habilitado

## Certificados SSL

Gerados localmente com OpenSSL (não commitados):

```bash
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -subj "/CN=localhost"
```

## Portas

| Porta | Protocolo | Serviço |
|---|---|---|
| 8080 | HTTP | nginx (SPA) |
| 8443 | HTTPS | nginx (SPA + SSL) |

---

## Padrões e Técnicas

### Atomic Design

O projeto segue Atomic Design, dividindo componentes em três camadas:

- **Atoms** — Elementos básicos, sem lógica de negócio. Exemplos: `Avatar`, `Button`, `Icon`, `SearchInput`.
- **Molecules** — Compõem atoms, ainda apresentacionais. Exemplos: `ContactItem`, `MessageBubble`, `MessageHeader`.
- **Organisms** — UI complexa, orquestra molecules. Exemplos: `LeftSidebar`, `MessagePanel`, `ContactsModal`.

Cada componente vive em sua pasta com o CSS Module separado:

```
components/atoms/Button/
├── Button.vue
└── css/Button.module.css
```

### Styled Component Like (CSS Modules + Tailwind)

Por estar usando Tailwind, o CSS fica em arquivos separados (`.module.css`), não junto do componente. Cada módulo usa `@apply` do Tailwind v4 para compor classes utility:

```css
/* Button.module.css */
@reference "tailwindcss";

.button {
  @apply rounded-lg cursor-pointer transition-opacity inline-flex items-center justify-center
         disabled:opacity-50 disabled:cursor-not-allowed;
}

.primary {
  @apply bg-black text-white border-none;
}
```

Variáveis de tema ficam em `variables.css` como CSS custom properties:

```css
/* variables.css */
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #f5f5f5;
  --accent-green: #00a884;
  --border-radius-md: 8px;
}
```

### Pinia (Composition API Style)

Pinia substitui o VueX. Todos os stores usam a sintaxe Composition API (`defineStore` com função), não Options API. Cada store compõe composables internamente:

```ts
// stores/contacts.ts
export const useContactsStore = defineStore('contacts', () => {
  const contacts = ref<Contact[]>([])
  const activeContactId = ref<string | undefined>(undefined)

  const { loading, error, withError } = useLoading()       // composable
  const pagination = usePagination({ initialPerPage: 20 }) // composable

  const activeContact = computed<Contact | null>(() => {
    return contacts.value.find((c) => c.id === activeContactId.value) ?? null
  })

  async function fetchContacts() {
    return withError(async () => {
      const response = await contactsApi.list(defaultContactId.value, {
        page: pagination.page.value,
        per_page: pagination.perPage.value,
      })
      contacts.value = toContactViewModelArray(response.data)
      if (response.meta) pagination.updateMeta(response.meta)
    })
  }

  return { contacts, activeContactId, activeContact, fetchContacts, pagination /* ... */ }
})
```

**Stores do projeto (7):** `contacts`, `conversations`, `groups`, `contactsModal`, `groupModal`, `messageSearch`, `newContactPopup`.

### Emit (Event Driven)

Técnica extraída do Godot. O emit é hierarchical — só propaga para o pai. O `ChatPage.vue` atua como orquestrador central, conectando todos os stores:

```
Store (estado + ações)
  ↓ props
ChatPage.vue (orquestrador)
  ↓ props
Organism → Molecule → Atom
  ↑ emit events
ChatPage.vue → store action
```

Exemplo do ChatPage conectando emit ao store:

```vue
<!-- ChatPage.vue -->
<LeftSidebar
  :contacts="sidebarItems"
  :search-query="searchQuery"
  @update:search-query="searchQuery = $event"
  @select="handleSelectItem($event)"
  @contacts="contactsModalStore.openModal()"
  @load-more="contactsStore.loadMoreContacts()"
/>
```

Componentes filhos nunca acessam stores diretamente — recebem props e emitem eventos. O ChatPage é o único que importa todos os stores.

Pinia está preparado para aceitar Event Driven completo (propagação global) caso necessário no futuro.

### Composables (Hooks do VueJS)

Composables são a resposta do VueJS aos Hooks do ReactJS — funções reutilizáveis que encapsulam lógica reativa. O projeto tem 9 composables:

| Composable | Função |
|---|---|
| `useLoading` | Wrapper de loading/error para operações async |
| `usePagination` | Lógica de paginação reutilizável (page, meta, hasNext, loadMore) |
| `useApi` | Wrapper genérico com data/loading/error para qualquer função de API |
| `useInfiniteScroll` | Scroll infinito com throttle (carregar mais contatos/mensagens) |
| `useSocket` | Gerenciamento do Phoenix Socket com estado reativo |
| `useRealtimeMessages` | Orquestra channels, parsing de mensagens e updates nos stores |
| `useChatSearch` | Highlight de termos de busca dentro de mensagens |
| `useErrorHandler` | Toast/estado de erro centralizado |
| `useKeydown` | Listener global de teclado com lifecycle automático |

Exemplo do `useLoading` — encapsula start/stop/withError:

```ts
// composables/useLoading.ts
export function useLoading() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function withError<T>(fn: () => Promise<T>): Promise<T> {
    loading.value = true
    error.value = null
    try {
      return await fn()
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erro desconhecido'
      throw e
    } finally {
      loading.value = false
    }
  }

  return { loading, error, start: () => { loading.value = true }, stop: () => { loading.value = false }, withError }
}
```

Exemplo do `useInfiniteScroll` — detecta quando o usuário chegou no final/início da lista:

```ts
// composables/useInfiniteScroll.ts
export function useInfiniteScroll(
  containerRef: Ref<HTMLElement | null>,
  callback: () => void | Promise<void>,
  options: { threshold?: number; direction?: 'bottom' | 'top' } = {},
) {
  const { threshold = 200, direction = 'bottom' } = options
  const isLoadingMore = ref(false)

  function checkScroll() {
    const el = containerRef.value
    if (!el || isLoadingMore.value) return

    const atEdge = direction === 'bottom'
      ? el.scrollTop + el.clientHeight >= el.scrollHeight - threshold
      : el.scrollTop <= threshold

    if (atEdge) {
      isLoadingMore.value = true
      Promise.resolve(callback()).finally(() => { isLoadingMore.value = false })
    }
  }
  // ... lifecycle: mount/unmount com throttle de 300ms
}
```

### TypeScript Strict

Todos os arquivos usam `lang="ts"`. Props usam `interface Props` + `defineProps<Props>()`. Emits usam a sintaxe tipada:

```ts
// Atoms tipados — sem validação runtime, tudo compile-time
interface Props {
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
})

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()
```

Hierarquia de erros tipados:

```ts
// api/errors.ts
export class ApiError extends Error {
  constructor(public status: number, public message: string, public body?: unknown) { ... }
}
export class ValidationError extends ApiError { /* 422, details: Record<string, string[]> */ }
export class NotFoundError extends ApiError { /* 404 */ }
export class NetworkError extends ApiError { /* status: 0 */ }
```

### API Layer com Transformers e Mock Fallback

A aplicação funciona totalmente offline. O health check determina se a API está disponível:

```ts
// api/client.ts — HTTP client usando fetch (sem axios)
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api'

async function request<T>(options: RequestOptions): Promise<ApiResponse<T>> {
  const response = await fetch(url.toString(), config)
  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new ApiError(response.status, error.error?.message || 'Erro desconhecido', error)
  }
  return response.json()
}

// Mock fallback — se API não está disponível, usa dados mockados
function mockRoute<T>(mockFn: () => Promise<ApiResponse<T>>) {
  return async () => {
    if (apiAvailable === false) return mockFn()
    throw new NetworkError()
  }
}
```

Transformers convertem snake_case da API Phoenix para camelCase do ViewModel:

```ts
// api/transformers.ts
export function toContactViewModel(api: ContactResponse): Contact {
  return {
    id: api.id,
    name: api.name,
    nickName: api.nickname,                    // nickname → nickName
    avatarUrl: api.avatar_url ?? undefined,    // avatar_url → avatarUrl
    isOnline: api.is_online,                   // is_online → isOnline
    lastMessage: api.last_message?.content ?? '',
  }
}
```

### Real-time com Phoenix Channels

WebSocket usando a lib `phoenix`. Topics: `messages:{contactId}` (diretas) e `group:{groupId}` (grupos). Reconnect com backoff exponencial (`min(tries * 2s, 30s)`):

```ts
// services/socket.ts
function createSocket(contactId: string): Socket {
  return new Socket(buildSocketUrl(), {
    params: { contact_id: contactId },
    reconnectAfter: (tries) => Math.min(tries * 2_000, 30_000),
  })
}
```

O composable `useRealtimeMessages` orquestra o lifecycle dos channels — join/leave automático baseado na conversa ativa, reconexão de todos os channels ao reconectar o socket.

### Router com Navigation Guard

```ts
// router/index.ts
router.beforeEach(async (to) => {
  if (to.params.contactId) return true  // Já tem contato na URL
  await checkApiAvailability()
  const contactsStore = useContactsStore()
  const contactId = await contactsStore.fetchDefaultContact()
  if (contactId) return { name: 'chat', params: { contactId } }
  return true
})
```

O app sempre redireciona para um contato específico — a raiz `/` é apenas um mecanismo de redirect.

---

ReactJS:

Larga experiência com ReactJS e posso dizer que a aplicação do Atomic Design deixa qualquer projeto conciso e coeso, facilitando muito a evolução gradativa e rápida do projeto. Todos sabemos que o VueJS pegou as melhores práticas do ReactJS e Angular, o que o torna um framework extremamente bem pensado.

Pinia é a alternativa ao Redux/MobX do ReactJS. Com a sintaxe Composition API, a transição é natural — os composables são equivalentes aos Hooks.

A experiência com AI auxiliou muito na curva de aprendizado do VueJS. Por ser TypeScript, a transposição de conhecimento do ReactJS foi quase instantânea, sem necessidade de aprender uma nova linguagem.

Comparação rápida entre os componentes:

| Conceito | ReactJS | VueJS |
|---|---|---|
| Estado global | Redux/MobX/Context | Pinia |
| Lógica reutilizável | Hooks (`useState`, `useEffect`) | Composables (`ref`, `computed`, `watch`) |
| Componente | JSX + `export default function` | `<script setup>` + `<template>` |
| Props typing | `interface Props` + TypeScript | `interface Props` + `defineProps<T>()` |
| Eventos | `onClick` + callback props | `@click` + `defineEmits<T>()` |
| CSS | styled-components / CSS Modules | CSS Modules + Tailwind `@apply` |
| Routing | React Router | Vue Router |
