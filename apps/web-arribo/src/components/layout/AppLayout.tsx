import type { ReactNode } from 'react'
import { AppHeader } from '@/components/layout/AppHeader'
import { Sidebar } from '@/components/layout/Sidebar'

interface AppLayoutProps {
  children: ReactNode
}

export function AppLayout({ children }: AppLayoutProps) {
  return (
    <div className="bg-background flex min-h-svh">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <AppHeader />
        <main className="flex-1 px-6 py-6 lg:px-8">{children}</main>
      </div>
    </div>
  )
}
