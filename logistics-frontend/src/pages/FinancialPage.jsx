import { DollarSign, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function FinancialPage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Financeiro</h1>
          <p className="text-muted-foreground">
            Controle de custos logísticos e financeiro
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Novo Lançamento
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <DollarSign className="h-5 w-5 mr-2" />
            Módulo Financeiro
          </CardTitle>
          <CardDescription>
            Esta funcionalidade está em desenvolvimento
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            O módulo financeiro incluirá controle de custos por pedido/produto/rota,
            contas a pagar, adiantamentos e classificação contábil.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

