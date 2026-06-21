import type { ReactNode } from 'react'
import { BrandLogo } from '@/components/brand/BrandLogo'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/shadcn/card'

interface AuthLayoutProps {
  title: string
  subtitle?: string
  children: ReactNode
}

export function AuthLayout({ title, subtitle, children }: AuthLayoutProps) {
  return (
    <div className="relative flex min-h-svh items-center justify-center overflow-hidden bg-[radial-gradient(circle_at_top,_oklch(0.93_0.03_255),_transparent_55%),linear-gradient(180deg,oklch(0.985_0.004_255),oklch(0.96_0.01_255))] p-6">
      <div className="pointer-events-none absolute inset-0 bg-[linear-gradient(rgba(15,23,42,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(15,23,42,0.03)_1px,transparent_1px)] bg-[size:32px_32px]" />

      <Card className="relative z-10 w-full max-w-md border-border/80 shadow-xl">
        <CardHeader className="border-b pb-6">
          <BrandLogo variant="light" className="mb-5 h-12 w-auto max-w-[240px] object-left" />
          <CardTitle className="text-2xl">{title}</CardTitle>
          {subtitle ? <CardDescription className="text-base">{subtitle}</CardDescription> : null}
        </CardHeader>
        <CardContent className="pt-6">{children}</CardContent>
      </Card>
    </div>
  )
}
