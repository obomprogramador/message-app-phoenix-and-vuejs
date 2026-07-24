export class ApiError extends Error {
  constructor(
    public status: number,
    public message: string,
    public body?: unknown,
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export class ValidationError extends ApiError {
  constructor(message: string, public details: Record<string, string[]>) {
    super(422, message)
    this.name = 'ValidationError'
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string) {
    super(404, `${resource} nao encontrado`)
    this.name = 'NotFoundError'
  }
}

export class UnauthorizedError extends ApiError {
  constructor() {
    super(401, 'Nao autorizado')
    this.name = 'UnauthorizedError'
  }
}

export class ForbiddenError extends ApiError {
  constructor() {
    super(403, 'Acesso negado')
    this.name = 'ForbiddenError'
  }
}

export class ConflictError extends ApiError {
  constructor(message: string) {
    super(409, message)
    this.name = 'ConflictError'
  }
}

export class NetworkError extends ApiError {
  constructor() {
    super(0, 'Erro de conexao com o servidor')
    this.name = 'NetworkError'
  }
}

export function parseApiError(error: unknown): ApiError {
  if (error instanceof ApiError) {
    return error
  }

  if (error instanceof TypeError && error.message.includes('fetch')) {
    return new NetworkError()
  }

  return new ApiError(500, 'Erro interno do servidor')
}
