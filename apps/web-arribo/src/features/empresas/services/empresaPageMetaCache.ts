const empresaNombreCache = new Map<number, string>()

export function getCachedEmpresaNombre(empresaId: number) {
  return empresaNombreCache.get(empresaId)
}

export function setCachedEmpresaNombre(empresaId: number, razonSocial: string) {
  empresaNombreCache.set(empresaId, razonSocial.trim())
}

export function clearCachedEmpresaNombre(empresaId: number) {
  empresaNombreCache.delete(empresaId)
}
