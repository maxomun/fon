export interface LoginCredentials {
  email: string
  password: string
}

export interface AuthTokens {
  access_token: string
  token_type: string
  expires_at: string
  expires_in: number
  refresh_token: string
  refresh_expires_at: string
}

export interface UserRole {
  codigo: string
  descripcion: string
  esadmin: boolean
}

export interface UserProfile {
  id: number
  email: string
  username: string
  lenguaje: string
  empresa_id: number | null
  empresa: string | null
  roles: UserRole[]
  persona: {
    nombres: string
    apellido_paterno: string
    apellido_materno: string
    nombre_completo: string
  } | null
}

export interface LoginResponse extends AuthTokens {
  success: boolean
  message: string
}

export interface MeResponse {
  success: boolean
  user: UserProfile
}
