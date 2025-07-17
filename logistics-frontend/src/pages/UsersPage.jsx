import { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Plus, Search, Filter, MoreHorizontal, Edit, Trash2 } from 'lucide-react'
import LoadingSpinner from '@/components/LoadingSpinner'

// Dados mockados para demonstração
const mockUsers = [
  {
    id: '1',
    username: 'admin',
    email: 'admin@logistics.com',
    first_name: 'Administrador',
    last_name: 'Sistema',
    is_active: true,
    created_at: '2025-01-01T00:00:00Z',
    roles: ['admin']
  },
  {
    id: '2',
    username: 'manager1',
    email: 'manager@logistics.com',
    first_name: 'João',
    last_name: 'Silva',
    is_active: true,
    created_at: '2025-01-02T00:00:00Z',
    roles: ['manager']
  },
  {
    id: '3',
    username: 'operator1',
    email: 'operator@logistics.com',
    first_name: 'Maria',
    last_name: 'Santos',
    is_active: true,
    created_at: '2025-01-03T00:00:00Z',
    roles: ['operator']
  },
]

function UserRow({ user }) {
  const getUserInitials = (user) => {
    return `${user.first_name?.[0] || ''}${user.last_name?.[0] || ''}`.toUpperCase()
  }

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('pt-BR')
  }

  return (
    <TableRow>
      <TableCell>
        <div className="flex items-center space-x-3">
          <Avatar className="h-8 w-8">
            <AvatarFallback className="text-xs">
              {getUserInitials(user)}
            </AvatarFallback>
          </Avatar>
          <div>
            <div className="font-medium">{user.first_name} {user.last_name}</div>
            <div className="text-sm text-muted-foreground">@{user.username}</div>
          </div>
        </div>
      </TableCell>
      <TableCell>{user.email}</TableCell>
      <TableCell>
        <div className="flex flex-wrap gap-1">
          {user.roles.map((role) => (
            <Badge key={role} variant="secondary" className="text-xs">
              {role}
            </Badge>
          ))}
        </div>
      </TableCell>
      <TableCell>
        <Badge variant={user.is_active ? 'success' : 'secondary'}>
          {user.is_active ? 'Ativo' : 'Inativo'}
        </Badge>
      </TableCell>
      <TableCell>{formatDate(user.created_at)}</TableCell>
      <TableCell>
        <div className="flex items-center space-x-2">
          <Button variant="ghost" size="sm">
            <Edit className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="sm">
            <Trash2 className="h-4 w-4" />
          </Button>
          <Button variant="ghost" size="sm">
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </div>
      </TableCell>
    </TableRow>
  )
}

export default function UsersPage() {
  const { apiRequest } = useAuth()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    // Simular carregamento de dados
    // Em uma implementação real, faria a requisição para a API
    const timer = setTimeout(() => {
      setUsers(mockUsers)
      setLoading(false)
    }, 1000)

    return () => clearTimeout(timer)
  }, [])

  const filteredUsers = users.filter(user =>
    user.first_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.last_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.username.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Usuários</h1>
          <p className="text-muted-foreground">
            Gerencie usuários e suas permissões no sistema
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Novo Usuário
        </Button>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Filtros</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex space-x-4">
            <div className="flex-1">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar usuários..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Button variant="outline">
              <Filter className="h-4 w-4 mr-2" />
              Filtros
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>Lista de Usuários</CardTitle>
          <CardDescription>
            {filteredUsers.length} usuário(s) encontrado(s)
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Usuário</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Perfis</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Criado em</TableHead>
                <TableHead>Ações</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredUsers.map((user) => (
                <UserRow key={user.id} user={user} />
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}

