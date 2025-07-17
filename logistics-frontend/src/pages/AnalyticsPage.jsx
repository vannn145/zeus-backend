import { BarChart3, TrendingUp } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function AnalyticsPage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Analytics</h1>
          <p className="text-muted-foreground">
            Relatórios e indicadores de performance (KPIs)
          </p>
        </div>
        <Button>
          <TrendingUp className="h-4 w-4 mr-2" />
          Novo Relatório
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <BarChart3 className="h-5 w-5 mr-2" />
            Módulo de Analytics
          </CardTitle>
          <CardDescription>
            Esta funcionalidade está em desenvolvimento
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            O módulo de analytics incluirá KPIs como OTIF, SLA de transporte,
            giro de estoque, acuracidade de inventário e dashboards interativos.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

