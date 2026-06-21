export const brandAssets = {
  logoHorizontalLight: '/brand/logo-horizontal-light.png',
  logoHorizontalDark: '/brand/logo-horizontal-dark.png',
  logoEmailWhite: '/brand/logo-email-white.png',
  logoHorizontalBlack: '/brand/logo-horizontal-black.png',
  icon: '/brand/icon-512.png',
  iconWhite: '/brand/icon-white.png',
} as const

export type BrandLogoVariant = 'light' | 'dark' | 'sidebar' | 'email-white' | 'icon'

export const brandLogoByVariant: Record<BrandLogoVariant, string> = {
  light: brandAssets.logoHorizontalLight,
  dark: brandAssets.logoHorizontalDark,
  sidebar: brandAssets.logoEmailWhite,
  'email-white': brandAssets.logoEmailWhite,
  icon: brandAssets.icon,
}
