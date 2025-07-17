import { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Users,
  Package,
  Truck,
  DollarSign,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  Clock,
  BarChart3,
} from 'lucide-react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts'

// Dados mockados para demonstração
const mockData = {
  stats: [
    {
      title: 'Total de Usuários',
      value: '1,234',
      change: '+12%',
      trend: 'up',
      icon: Users,
    },
    {
      title: 'Produtos Ativos',
      value: '5,678',
      change: '+5%',
      trend: 'up',
      icon: Package,
    },
    {
      title: 'Entregas Hoje',
      value: '89',
      change: '-3%',
      trend: 'down',
      icon: Truck,
    },
    {
      title: 'Receita Mensal',
      value: 'R$ 45.2K',
      change: '+18%',
      trend: 'up',
      icon: DollarSign,
    },
  ],
  recentOrders: [
    { id: 'PO-001', supplier: 'Fornecedor ABC', status: 'pending', value: 'R$ 1.250,00' },
    { id: 'PO-002', supplier: 'Fornecedor XYZ', status: 'completed', value: 'R$ 890,00' },
    { id: 'PO-003', supplier: 'Fornecedor 123', status: 'processing', value: 'R$ 2.100,00' },
    { id: 'PO-004', supplier: 'Fornecedor DEF', status: 'completed', value: 'R$ 750,00' },
  ],
  alerts: [
    { type: 'warning', message: '15 produtos com estoque baixo', time: '2 horas atrás' },
    { type: 'error', message: '3 entregas atrasadas', time: '4 horas atrás' },
    { type: 'success', message: 'Inventário mensal concluído', time: '1 dia atrás' },
  ],
  chartData: [
    { name: 'Jan', vendas: 4000, entregas: 2400 },
    { name: 'Fev', vendas: 3000, entregas: 1398 },
    { name: 'Mar', vendas: 2000, entregas: 9800 },
    { name: 'Abr', vendas: 2780, entregas: 3908 },
    { name: 'Mai', vendas: 1890, entregas: 4800 },
    { name: 'Jun', vendas: 2390, entregas: 3800 },
  ],
}

function StatCard({ stat }) {
  const Icon = stat.icon
  const isPositive = stat.trend === 'up'

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium">{stat.title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{stat.value}</div>
        <div className="flex items-center text-xs text-muted-foreground">
          {isPositive ? (
            <TrendingUp className="h-3 w-3 mr-1 text-green-500" />
          ) : (
            <TrendingDown className="h-3 w-3 mr-1 text-red-500" />
          )}
          <span className={isPositive ? 'text-green-500' : 'text-red-500'}>
            {stat.change}
          </span>
          <span className="ml-1">em relação ao mês anterior</span>
        </div>
      </CardContent>
    </Card>
  )
}

function AlertItem({ alert }) {
  const getIcon = (type) => {
    switch (type) {
      case 'warning':
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />
      case 'error':
        return <AlertTriangle className="h-4 w-4 text-red-500" />
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      default:
        return <Clock className="h-4 w-4 text-blue-500" />
    }
  }

  return (
    <div className="flex items-start space-x-3 p-3 rounded-lg hover:bg-muted/50">
      {getIcon(alert.type)}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium">{alert.message}</p>
        <p className="text-xs text-muted-foreground">{alert.time}</p>
      </div>
    </div>
  )
}

function OrderStatusBadge({ status }) {
  const variants = {
    pending: 'secondary',
    processing: 'default',
    completed: 'success',
    cancelled: 'destructive',
  }

  const labels = {
    pending: 'Pendente',
    processing: 'Processando',
    completed: 'Concluído',
    cancelled: 'Cancelado',
  }

  return (
    <Badge variant={variants[status] || 'default'}>
      {labels[status] || status}
    </Badge>
  )
}

export default function DashboardPage() {
  const { user } = useAuth()
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Simular carregamento de dados
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 1000)

    return () => clearTimeout(timer)
  }, [])

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
          <p className="mt-2 text-muted-foreground">Carregando dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          Bem-vindo de volta, {user?.first_name}! Aqui está um resumo das suas operações logísticas.
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {mockData.stats.map((stat, index) => (
          <StatCard key={index} stat={stat} />
        ))}
      </div>

      {/* Charts and Tables */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-7">
        {/* Chart */}
        <Card className="col-span-4">
          <CardHeader>
            <CardTitle>Visão Geral</CardTitle>
            <CardDescription>
              Vendas e entregas dos últimos 6 meses
            </CardDescription>
          </CardHeader>
          <CardContent className="pl-2">
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={mockData.chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Line 
                  type="monotone" 
                  dataKey="vendas" 
                  stroke="#8884d8" 
                  strokeWidth={2}
                  name="Vendas"
                />
                <Line 
                  type="monotone" 
                  dataKey="entregas" 
                  stroke="#82ca9d" 
                  strokeWidth={2}
                  name="Entregas"
                />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        {/* Recent Orders */}
        <Card className="col-span-3">
          <CardHeader>
            <CardTitle>Pedidos Recentes</CardTitle>
            <CardDescription>
              Últimos pedidos de compra processados
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {mockData.recentOrders.map((order) => (
                <div key={order.id} className="flex items-center justify-between">
                  <div className="space-y-1">
                    <p className="text-sm font-medium">{order.id}</p>
                    <p className="text-xs text-muted-foreground">{order.supplier}</p>
                  </div>
                  <div className="text-right space-y-1">
                    <OrderStatusBadge status={order.status} />
                    <p className="text-xs font-medium">{order.value}</p>
                  </div>
                </div>
              ))}
            </div>
            <Button variant="outline" className="w-full mt-4">
              Ver todos os pedidos
            </Button>
          </CardContent>
        </Card>
      </div>

      {/* Alerts and Quick Actions */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Alerts */}
        <Card>
          <CardHeader>
            <CardTitle>Alertas e Notificações</CardTitle>
            <CardDescription>
              Acompanhe eventos importantes do sistema
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {mockData.alerts.map((alert, index) => (
                <AlertItem key={index} alert={alert} />
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle>Ações Rápidas</CardTitle>
            <CardDescription>
              Acesse rapidamente as funcionalidades mais usadas
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              <Button variant="outline" className="h-20 flex flex-col">
                <Package className="h-6 w-6 mb-2" />
                <span className="text-xs">Novo Produto</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col">
                <Users className="h-6 w-6 mb-2" />
                <span className="text-xs">Novo Fornecedor</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col">
                <Truck className="h-6 w-6 mb-2" />
                <span className="text-xs">Nova Entrega</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col">
                <BarChart3 className="h-6 w-6 mb-2" />
                <span className="text-xs">Relatórios</span>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

