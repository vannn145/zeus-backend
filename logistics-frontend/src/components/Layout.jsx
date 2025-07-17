import { useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '@/contexts/AuthContext'
import { useTheme } from '@/contexts/ThemeContext'
import { Button } from '@/components/ui/button'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import {
  Truck,
  LayoutDashboard,
  Users,
  Building2,
  Package,
  UserCheck,
  Warehouse,
  MapPin,
  DollarSign,
  BarChart3,
  Menu,
  Sun,
  Moon,
  LogOut,
  Settings,
  User,
} from 'lucide-react'

const navigation = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    name: 'Usuários',
    href: '/users',
    icon: Users,
  },
  {
    name: 'Empresas',
    href: '/companies',
    icon: Building2,
  },
  {
    name: 'Produtos',
    href: '/products',
    icon: Package,
  },
  {
    name: 'Fornecedores',
    href: '/suppliers',
    icon: UserCheck,
  },
  {
    name: 'Inventário',
    href: '/inventory',
    icon: Warehouse,
  },
  {
    name: 'Transporte',
    href: '/transport',
    icon: MapPin,
  },
  {
    name: 'Financeiro',
    href: '/financial',
    icon: DollarSign,
  },
  {
    name: 'Analytics',
    href: '/analytics',
    icon: BarChart3,
  },
]

function NavigationItem({ item, isActive, onClick }) {
  const Icon = item.icon
  
  return (
    <Button
      variant={isActive ? 'secondary' : 'ghost'}
      className={`w-full justify-start ${isActive ? 'bg-secondary' : ''}`}
      onClick={onClick}
    >
      <Icon className="h-4 w-4 mr-3" />
      {item.name}
    </Button>
  )
}

function Sidebar({ className = '' }) {
  const location = useLocation()
  const navigate = useNavigate()

  return (
    <div className={`pb-12 ${className}`}>
      <div className="space-y-4 py-4">
        <div className="px-3 py-2">
          <div className="flex items-center mb-6">
            <div className="bg-primary rounded-lg p-2 mr-3">
              <Truck className="h-6 w-6 text-primary-foreground" />
            </div>
            <div>
              <h2 className="text-lg font-semibold">Gestão Logística</h2>
              <p className="text-xs text-muted-foreground">Sistema Integrado</p>
            </div>
          </div>
          
          <div className="space-y-1">
            {navigation.map((item) => (
              <NavigationItem
                key={item.name}
                item={item}
                isActive={location.pathname === item.href}
                onClick={() => navigate(item.href)}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function Header() {
  const { user, logout } = useAuth()
  const { theme, toggleTheme } = useTheme()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  const handleLogout = async () => {
    await logout()
  }

  const getUserInitials = (user) => {
    if (!user) return 'U'
    return `${user.first_name?.[0] || ''}${user.last_name?.[0] || ''}`.toUpperCase()
  }

  return (
    <header className="sticky top-0 z-40 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-14 items-center">
        {/* Mobile menu button */}
        <Sheet open={isMobileMenuOpen} onOpenChange={setIsMobileMenuOpen}>
          <SheetTrigger asChild>
            <Button
              variant="ghost"
              className="mr-2 px-0 text-base hover:bg-transparent focus-visible:bg-transparent focus-visible:ring-0 focus-visible:ring-offset-0 md:hidden"
            >
              <Menu className="h-6 w-6" />
              <span className="sr-only">Toggle Menu</span>
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="pr-0">
            <Sidebar />
          </SheetContent>
        </Sheet>

        {/* Logo for mobile */}
        <div className="flex items-center md:hidden">
          <div className="bg-primary rounded-lg p-1 mr-2">
            <Truck className="h-4 w-4 text-primary-foreground" />
          </div>
          <span className="font-semibold">Gestão Logística</span>
        </div>

        <div className="flex flex-1 items-center justify-between space-x-2 md:justify-end">
          <div className="w-full flex-1 md:w-auto md:flex-none">
            {/* Breadcrumb ou título da página pode ir aqui */}
          </div>
          
          <div className="flex items-center space-x-2">
            {/* Theme toggle */}
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleTheme}
            >
              {theme === 'light' ? (
                <Moon className="h-4 w-4" />
              ) : (
                <Sun className="h-4 w-4" />
              )}
            </Button>

            {/* User menu */}
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="relative h-8 w-8 rounded-full">
                  <Avatar className="h-8 w-8">
                    <AvatarFallback className="text-xs">
                      {getUserInitials(user)}
                    </AvatarFallback>
                  </Avatar>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent className="w-56" align="end" forceMount>
                <DropdownMenuLabel className="font-normal">
                  <div className="flex flex-col space-y-1">
                    <p className="text-sm font-medium leading-none">
                      {user?.first_name} {user?.last_name}
                    </p>
                    <p className="text-xs leading-none text-muted-foreground">
                      {user?.email}
                    </p>
                  </div>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem>
                  <User className="mr-2 h-4 w-4" />
                  <span>Perfil</span>
                </DropdownMenuItem>
                <DropdownMenuItem>
                  <Settings className="mr-2 h-4 w-4" />
                  <span>Configurações</span>
                </DropdownMenuItem>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleLogout}>
                  <LogOut className="mr-2 h-4 w-4" />
                  <span>Sair</span>
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </div>
      </div>
    </header>
  )
}

export default function Layout() {
  return (
    <div className="min-h-screen bg-background">
      <div className="flex">
        {/* Desktop sidebar */}
        <div className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
          <div className="flex-1 flex flex-col min-h-0 border-r bg-background">
            <Sidebar />
          </div>
        </div>

        {/* Main content */}
        <div className="flex flex-col flex-1 md:pl-64">
          <Header />
          <main className="flex-1">
            <div className="py-6">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
                <Outlet />
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  )
}

