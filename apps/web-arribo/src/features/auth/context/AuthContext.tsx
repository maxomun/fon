import { createContext } from 'react'
import type {
  LoginCredentials,
  UserProfile,
} from '@/features/auth/types/auth.types'

export interface AuthContextValue {
  user: UserProfile | null
  isAuthenticated: boolean
  isLoading: boolean
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)
