import { useToast } from '@/hooks/use-toast'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { X, CheckCircle, AlertTriangle, Info } from 'lucide-react'

function Toast({ toast, onDismiss }) {
  const getIcon = (variant) => {
    switch (variant) {
      case 'success':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case 'destructive':
        return <AlertTriangle className="h-4 w-4 text-red-500" />
      case 'warning':
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />
      default:
        return <Info className="h-4 w-4 text-blue-500" />
    }
  }

  const getVariantStyles = (variant) => {
    switch (variant) {
      case 'success':
        return 'border-green-200 bg-green-50 text-green-800'
      case 'destructive':
        return 'border-red-200 bg-red-50 text-red-800'
      case 'warning':
        return 'border-yellow-200 bg-yellow-50 text-yellow-800'
      default:
        return 'border-blue-200 bg-blue-50 text-blue-800'
    }
  }

  return (
    <div className={`relative rounded-lg border p-4 shadow-lg ${getVariantStyles(toast.variant)} animate-in slide-in-from-right-full`}>
      <div className="flex items-start space-x-3">
        {getIcon(toast.variant)}
        <div className="flex-1 min-w-0">
          {toast.title && (
            <div className="font-medium text-sm">{toast.title}</div>
          )}
          {toast.description && (
            <div className="text-sm opacity-90 mt-1">{toast.description}</div>
          )}
        </div>
        <Button
          variant="ghost"
          size="sm"
          className="h-6 w-6 p-0 opacity-70 hover:opacity-100"
          onClick={() => onDismiss(toast.id)}
        >
          <X className="h-3 w-3" />
        </Button>
      </div>
    </div>
  )
}

export function Toaster() {
  const { toasts, dismiss } = useToast()

  if (toasts.length === 0) return null

  return (
    <div className="fixed top-0 right-0 z-50 w-full max-w-sm p-4 space-y-2">
      {toasts.map((toast) => (
        <Toast key={toast.id} toast={toast} onDismiss={dismiss} />
      ))}
    </div>
  )
}

