import { Loader2 } from 'lucide-react'

export default function LoadingSpinner({ size = 'default', className = '' }) {
  const sizeClasses = {
    sm: 'h-4 w-4',
    default: 'h-8 w-8',
    lg: 'h-12 w-12',
  }

  return (
    <div className={`flex items-center justify-center ${className}`}>
      <Loader2 className={`animate-spin ${sizeClasses[size]}`} />
    </div>
  )
}

// Componente para tela cheia de loading
export function FullScreenLoader() {
  return (
    <div className="fixed inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="flex flex-col items-center space-y-4">
        <LoadingSpinner size="lg" />
        <p className="text-muted-foreground">Carregando...</p>
      </div>
    </div>
  )
}

