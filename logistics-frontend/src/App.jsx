import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { useState, useEffect } from 'react'
import { Toaster } from '@/components/ui/toaster'
import { AuthProvider, useAuth } from '@/contexts/AuthContext'
import { ThemeProvider } from '@/contexts/ThemeContext'
import Layout from '@/components/Layout'
import LoginPage from '@/pages/LoginPage'
import DashboardPage from '@/pages/DashboardPage'
import UsersPage from '@/pages/UsersPage'
import CompaniesPage from '@/pages/CompaniesPage'
import ProductsPage from '@/pages/ProductsPage'
import SuppliersPage from '@/pages/SuppliersPage'
import InventoryPage from '@/pages/InventoryPage'
import TransportPage from '@/pages/TransportPage'
import FinancialPage from '@/pages/FinancialPage'
import AnalyticsPage from '@/pages/AnalyticsPage'
import LoadingSpinner from '@/components/LoadingSpinner'
import './App.css'

// Componente para rotas protegidas
function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  
  if (loading) {
    return <LoadingSpinner />
  }
  
  if (!user) {
    return <Navigate to="/login" replace />
  }
  
  return children
}

// Componente para rotas públicas (redireciona se já logado)
function PublicRoute({ children }) {
  const { user, loading } = useAuth()
  
  if (loading) {
    return <LoadingSpinner />
  }
  
  if (user) {
    return <Navigate to="/dashboard" replace />
  }
  
  return children
}

function AppRoutes() {
  return (
    <Routes>
      {/* Rotas públicas */}
      <Route path="/login" element={
        <PublicRoute>
          <LoginPage />
        </PublicRoute>
      } />
      
      {/* Rotas protegidas */}
      <Route path="/" element={
        <ProtectedRoute>
          <Layout />
        </ProtectedRoute>
      }>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="companies" element={<CompaniesPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="suppliers" element={<SuppliersPage />} />
        <Route path="inventory" element={<InventoryPage />} />
        <Route path="transport" element={<TransportPage />} />
        <Route path="financial" element={<FinancialPage />} />
        <Route path="analytics" element={<AnalyticsPage />} />
      </Route>
      
      {/* Rota 404 */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <div className="min-h-screen bg-background">
            <AppRoutes />
            <Toaster />
          </div>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App

