import { Building2, Globe2, ShieldCheck } from 'lucide-react'
import { AppLayout } from '@/components/layout/AppLayout'
import { Badge } from '@/components/ui/shadcn/badge'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/shadcn/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/shadcn/tabs'
import { useAuth } from '@/features/auth/hooks/useAuth'
import {
  displayUserName,
  formatRoles,
  getEmpresasAdministrables,
  hasAccesoGlobal,
} from '@/features/auth/utils/roles'

export function DashboardPage() {
  const { user } = useAuth()
  const empresasAdministrables = getEmpresasAdministrables(user)

  return (
    <AppLayout>
      <div className="mb-8">
        <h1 className="text-3xl font-semibold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground mt-1 text-sm">
          {displayUserName(user) || user?.email}, has iniciado sesión correctamente.
        </p>
      </div>

      <Tabs defaultValue="resumen" className="max-w-4xl">
        <TabsList>
          <TabsTrigger value="resumen">Resumen</TabsTrigger>
          <TabsTrigger value="empresas">Empresas</TabsTrigger>
          <TabsTrigger value="acceso">Acceso</TabsTrigger>
        </TabsList>

        <TabsContent value="resumen">
          <Card>
            <CardHeader>
              <CardTitle>Bienvenido a FacturaOn</CardTitle>
              <CardDescription>
                Panel de control con la nueva identidad visual — sobrio, claro y listo para
                escalar.
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 sm:grid-cols-3">
              <div className="bg-muted/50 rounded-lg border p-4">
                <Globe2 className="text-primary mb-2 size-5" />
                <p className="text-sm font-medium">Plataforma</p>
                <p className="text-muted-foreground mt-1 text-sm">
                  {hasAccesoGlobal(user) ? 'Acceso global FON' : 'Acceso por empresa'}
                </p>
              </div>
              <div className="bg-muted/50 rounded-lg border p-4">
                <Building2 className="text-primary mb-2 size-5" />
                <p className="text-sm font-medium">Empresas</p>
                <p className="text-muted-foreground mt-1 text-sm">
                  {empresasAdministrables.length} administrable
                  {empresasAdministrables.length === 1 ? '' : 's'}
                </p>
              </div>
              <div className="bg-muted/50 rounded-lg border p-4">
                <ShieldCheck className="text-primary mb-2 size-5" />
                <p className="text-sm font-medium">Roles</p>
                <p className="text-muted-foreground mt-1 text-sm">
                  {formatRoles(user) || 'Sin roles asignados'}
                </p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="empresas">
          <Card>
            <CardHeader>
              <CardTitle>Empresas administrables</CardTitle>
              <CardDescription>
                Organizaciones sobre las que tiene permisos de gestión.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {empresasAdministrables.length > 0 ? (
                <ul className="divide-border divide-y rounded-lg border">
                  {empresasAdministrables.map((empresa) => (
                    <li
                      key={empresa.id}
                      className="flex items-center justify-between gap-4 px-4 py-3 text-sm"
                    >
                      <span className="font-medium">{empresa.razon_social}</span>
                      <Badge variant="outline">ID {empresa.id}</Badge>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-muted-foreground text-sm">
                  No tiene empresas asignadas para administrar.
                </p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="acceso">
          <Card>
            <CardHeader>
              <CardTitle>Detalle de acceso</CardTitle>
              <CardDescription>Información de sesión y permisos actuales.</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-3 text-sm">
              {user?.email ? (
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-muted-foreground w-24 shrink-0">Email</span>
                  <span>{user.email}</span>
                </div>
              ) : null}
              {user?.roles.length ? (
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-muted-foreground w-24 shrink-0">Roles</span>
                  <Badge variant="secondary">{formatRoles(user)}</Badge>
                </div>
              ) : null}
              {hasAccesoGlobal(user) ? (
                <div className="flex flex-wrap items-center gap-2">
                  <span className="text-muted-foreground w-24 shrink-0">Alcance</span>
                  <Badge>Administrador FON</Badge>
                </div>
              ) : null}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </AppLayout>
  )
}
