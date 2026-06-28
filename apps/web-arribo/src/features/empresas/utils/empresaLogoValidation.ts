const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/webp'] as const
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024
const MIN_WIDTH = 180
const MIN_HEIGHT = 60
const MIN_ASPECT_RATIO = 2
const MAX_ASPECT_RATIO = 4

function readImageDimensions(file: File): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const image = new Image()

    image.onload = () => {
      URL.revokeObjectURL(url)
      resolve({ width: image.naturalWidth, height: image.naturalHeight })
    }

    image.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('invalid_image'))
    }

    image.src = url
  })
}

export async function validateEmpresaLogoFile(file: File): Promise<string | null> {
  if (!ALLOWED_TYPES.includes(file.type as (typeof ALLOWED_TYPES)[number])) {
    return 'Formato no permitido. Use PNG, JPEG o WebP.'
  }

  if (file.size > MAX_UPLOAD_BYTES) {
    return 'El archivo supera el máximo de 5 MB.'
  }

  let dimensions: { width: number; height: number }
  try {
    dimensions = await readImageDimensions(file)
  } catch {
    return 'El archivo no es una imagen válida.'
  }

  const { width, height } = dimensions

  if (width < MIN_WIDTH || height < MIN_HEIGHT) {
    return `La imagen es muy pequeña (mínimo ${MIN_WIDTH}×${MIN_HEIGHT} px). Obtuvo ${width}×${height}.`
  }

  const aspect = width / height
  if (aspect < MIN_ASPECT_RATIO || aspect > MAX_ASPECT_RATIO) {
    return `La proporción debe ser horizontal (~3:1). Obtuvo ${width}×${height} (${aspect.toFixed(1)}:1).`
  }

  return null
}

export function formatLogoByteSize(bytes: number) {
  if (bytes < 1024) {
    return `${bytes} B`
  }

  const kb = bytes / 1024
  return kb < 1024 ? `${kb.toFixed(1)} KB` : `${(kb / 1024).toFixed(1)} MB`
}
