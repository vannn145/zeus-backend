import { Warehouse, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function InventoryPage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Inventário</h1>
          <p className="text-muted-foreground">
            Controle de estoque e movimentações
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Nova Movimentação
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Warehouse className="h-5 w-5 mr-2" />
            Módulo de Inventário
          </CardTitle>
          <CardDescription>
            Esta funcionalidade está em desenvolvimento
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            O módulo de inventário incluirá controle de saldos, movimentações,
            endereçamento, FIFO/FEFO, inventário cíclico e alertas de vencimento.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

