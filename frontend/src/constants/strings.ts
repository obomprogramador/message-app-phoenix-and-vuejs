// Isso pode evoluir para i18n no futuro

export const PLACEHOLDERS = {
  SEARCH: 'Pesquisar...',
  SEARCH_CONVERSATION: 'Pesquisar ou comecar nova conversa',
  MESSAGE_INPUT: 'Digite sua mensagem...',
  SEARCH_MESSAGE: 'Pesquisar mensagem...',
} as const

export const EMPTY_STATES = {
  NO_CONTACTS: 'Voce nao tem contatos, adicione novos contatos.',
  SELECT_CONVERSATION: 'Selecione uma conversa para comecar',
} as const

export const ARIA_LABELS = {
  CLOSE_SEARCH: 'Fechar busca',
  PREVIOUS_RESULT: 'Resultado anterior',
  NEXT_RESULT: 'Proximo resultado',
  SEARCH_MESSAGES: 'Buscar mensagens',
} as const

export const CONTACTS_MODAL = {
  TITLE: 'Contatos',
  ADD_BUTTON: 'Adicionar',
  SEARCH_PLACEHOLDER: 'Pesquisar contatos...',
  DELETE_ARIA: 'Excluir contato',
  EMPTY_STATE: 'Nenhum contato encontrado',
} as const

export const NEW_CONTACT_POPUP = {
  TITLE: 'Adicionar Contato',
  DESCRIPTION: 'Informar o @nickName que deseja adicionar',
  USER_LABEL: 'Usuário',
  INPUT_PREFIX: '@',
  INPUT_PLACEHOLDER: 'nickName',
  ADD_BUTTON: 'Adicionar',
  SUCCESS_TITLE: 'Contato adicionado',
  SUCCESS_SUBTITLE: (name: string, nickName: string) =>
    `${name} (${nickName}) entrou na sua lista.`,
  ERROR_TITLE: 'Usuário não encontrado',
  ERROR_SUBTITLE: (nickName: string) =>
    `Nenhum usuario com ${nickName} foi encontrado`,
} as const

export const GROUP_MODAL = {
  TITLE: 'Novo Grupo',
  SELECTION_LABEL: (count: number, max: number) => `${count} de ${max} contatos selecionados`,
  GROUP_NAME_LABEL: 'Nome do grupo',
  GROUP_NAME_PLACEHOLDER: 'Digite o nome do grupo...',
  CONTACTS_LABEL: 'Seus Contatos',
  SEARCH_PLACEHOLDER: 'Pesquisar contatos...',
  CANCEL_BUTTON: 'Cancelar',
  CREATE_BUTTON: 'Criar Grupo',
  CREATING_BUTTON: 'Criando...',
  MAX_SELECTED: 'Limite de contatos atingido',
} as const

export const LOADING = {
  FETCHING_CONTACTS: 'Carregando contatos...',
  FETCHING_MESSAGES: 'Carregando mensagens...',
  SENDING: 'Enviando...',
  SEARCHING: 'Buscando...',
  CREATING: 'Criando...',
  DELETING: 'Excluindo...',
} as const

export const ERRORS = {
  NETWORK: 'Verifique sua conexao com o internet',
  GENERIC: 'Ocorreu um erro inesperado',
  FAILED_TO_LOAD: 'Falha ao carregar dados',
  FAILED_TO_SAVE: 'Falha ao salvar',
  FAILED_TO_DELETE: 'Falha ao excluir',
  FAILED_TO_SEND: 'Falha ao enviar mensagem',
  CONTACT_NOT_FOUND: 'Contato nao encontrado',
} as const
