import { MapPin, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function TransportPage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Transporte</h1>
          <p className="text-muted-foreground">
            Gestão de entregas e transportadoras
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Nova Expedição
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <MapPin className="h-5 w-5 mr-2" />
            Módulo de Transporte
          </CardTitle>
          <CardDescription>
            Esta funcionalidade está em desenvolvimento
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            O módulo de transporte incluirá planejamento de rotas, gestão de
            transportadoras, controle de fretes, rastreamento e geração de CTE/MDF-e.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

