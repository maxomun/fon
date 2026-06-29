export function userInitials(displayName: string, email?: string | null): string {
  const normalizedName = displayName.trim()

  if (normalizedName) {
    const parts = normalizedName.split(/\s+/).filter(Boolean)

    if (parts.length >= 2) {
      return `${parts[0]![0] ?? ''}${parts[parts.length - 1]![0] ?? ''}`.toUpperCase()
    }

    return normalizedName.slice(0, 2).toUpperCase()
  }

  const normalizedEmail = email?.trim() ?? ''
  if (!normalizedEmail) {
    return '?'
  }

  const localPart = normalizedEmail.split('@')[0] ?? normalizedEmail
  return localPart.slice(0, 2).toUpperCase()
}
