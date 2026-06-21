import { brandLogoByVariant, type BrandLogoVariant } from '@/config/brand'
import { cn } from '@/lib/utils'

interface BrandLogoProps {
  variant?: BrandLogoVariant
  className?: string
  alt?: string
}

export function BrandLogo({
  variant = 'light',
  className,
  alt = 'FacturaOn',
}: BrandLogoProps) {
  return (
    <img
      src={brandLogoByVariant[variant]}
      alt={alt}
      className={cn('block h-auto w-auto max-w-full object-contain object-left', className)}
      decoding="async"
    />
  )
}
