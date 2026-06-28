function indentXml(xml: string) {
  const padding = '  '
  let pad = 0

  return xml
    .replace(/>\s*</g, '>\n<')
    .split('\n')
    .map((line) => {
      const trimmed = line.trim()
      if (!trimmed) {
        return ''
      }

      if (trimmed.startsWith('</')) {
        pad = Math.max(pad - 1, 0)
      }

      const indented = `${padding.repeat(pad)}${trimmed}`

      if (
        trimmed.startsWith('<') &&
        !trimmed.startsWith('</') &&
        !trimmed.startsWith('<?') &&
        !trimmed.endsWith('/>') &&
        !trimmed.includes('</')
      ) {
        pad += 1
      }

      return indented
    })
    .filter(Boolean)
    .join('\n')
}

export async function formatXmlPreview(blob: Blob) {
  const raw = await blob.text()

  try {
    const doc = new DOMParser().parseFromString(raw, 'application/xml')
    if (doc.querySelector('parsererror')) {
      return raw
    }

    const serialized = new XMLSerializer().serializeToString(doc)
    return indentXml(serialized)
  } catch {
    return raw
  }
}
