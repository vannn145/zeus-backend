import { createContext, useContext, useState, useEffect } from 'react'
import { useToast } from '@/hooks/use-toast'

const AuthContext = createContext({})

const API_BASE_URL = 'http://localhost:5000/api'

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const { toast } = useToast()

  // Função para fazer requisições autenticadas
  const apiRequest = async (endpoint, options = {}) => {
    const token = localStorage.getItem('access_token')
    
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      ...options,
    }

    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, config)
      
      if (response.status === 401) {
        // Token expirado, tentar renovar
        const refreshed = await refreshToken()
        if (refreshed) {
          // Tentar novamente com novo token
          config.headers.Authorization = `Bearer ${localStorage.getItem('access_token')}`
          return await fetch(`${API_BASE_URL}${endpoint}`, config)
        } else {
          // Não foi possível renovar, fazer logout
          logout()
          throw new Error('Sessão expirada')
        }
      }

      return response
    } catch (error) {
      console.error('API Request Error:', error)
      throw error
    }
  }

  // Função de login
  const login = async (username, password) => {
    try {
      setLoading(true)
      
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.message || 'Erro ao fazer login')
      }

      // Salvar tokens
      localStorage.setItem('access_token', data.access_token)
      localStorage.setItem('refresh_token', data.refresh_token)
      
      // Definir usuário
      setUser(data.user)

      toast({
        title: 'Login realizado com sucesso',
        description: `Bem-vindo, ${data.user.first_name}!`,
      })

      return { success: true }
    } catch (error) {
      console.error('Login error:', error)
      toast({
        title: 'Erro no login',
        description: error.message,
        variant: 'destructive',
      })
      return { success: false, error: error.message }
    } finally {
      setLoading(false)
    }
  }

  // Função de logout
  const logout = async () => {
    try {
      // Tentar fazer logout no servidor
      await apiRequest('/auth/logout', { method: 'POST' })
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      // Limpar dados locais
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      setUser(null)
      
      toast({
        title: 'Logout realizado',
        description: 'Você foi desconectado com sucesso',
      })
    }
  }

  // Função para renovar token
  const refreshToken = async () => {
    try {
      const refreshToken = localStorage.getItem('refresh_token')
      if (!refreshToken) return false

      const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${refreshToken}`,
        },
      })

      if (!response.ok) return false

      const data = await response.json()
      localStorage.setItem('access_token', data.access_token)
      
      return true
    } catch (error) {
      console.error('Token refresh error:', error)
      return false
    }
  }

  // Função para obter dados do usuário atual
  const getCurrentUser = async () => {
    try {
      const response = await apiRequest('/auth/me')
      
      if (!response.ok) {
        throw new Error('Erro ao obter dados do usuário')
      }

      const data = await response.json()
      setUser(data.user)
      
      return data.user
    } catch (error) {
      console.error('Get current user error:', error)
      logout()
      return null
    }
  }

  // Verificar se há token salvo ao inicializar
  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('access_token')
      
      if (token) {
        try {
          await getCurrentUser()
        } catch (error) {
          console.error('Auth initialization error:', error)
          logout()
        }
      }
      
      setLoading(false)
    }

    initAuth()
  }, [])

  // Função para alterar senha
  const changePassword = async (currentPassword, newPassword) => {
    try {
      const response = await apiRequest('/auth/change-password', {
        method: 'POST',
        body: JSON.stringify({
          current_password: currentPassword,
          new_password: newPassword,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.message || 'Erro ao alterar senha')
      }

      toast({
        title: 'Senha alterada',
        description: 'Sua senha foi alterada com sucesso',
      })

      return { success: true }
    } catch (error) {
      console.error('Change password error:', error)
      toast({
        title: 'Erro ao alterar senha',
        description: error.message,
        variant: 'destructive',
      })
      return { success: false, error: error.message }
    }
  }

  const value = {
    user,
    loading,
    login,
    logout,
    changePassword,
    apiRequest,
    getCurrentUser,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

