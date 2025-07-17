import { Package, Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function ProductsPage() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Produtos</h1>
          <p className="text-muted-foreground">
            Gerencie catálogo de produtos e variações
          </p>
        </div>
        <Button>
          <Plus className="h-4 w-4 mr-2" />
          Novo Produto
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Package className="h-5 w-5 mr-2" />
            Módulo de Produtos
          </CardTitle>
          <CardDescription>
            Esta funcionalidade está em desenvolvimento
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            O módulo de produtos permitirá gerenciar o catálogo completo,
            incluindo SKUs, categorias, variações, dimensões e controle de lotes.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

