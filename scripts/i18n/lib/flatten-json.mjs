/** Achata objetos JSON aninhados em mapa chave.caminho → valor string. */

export function flattenStrings(obj, prefix = '') {
  const result = new Map()

  if (obj == null || typeof obj !== 'object') {
    return result
  }

  for (const [key, value] of Object.entries(obj)) {
    const path = prefix ? `${prefix}.${key}` : key

    if (typeof value === 'string') {
      result.set(path, value)
    } else if (value && typeof value === 'object' && !Array.isArray(value)) {
      for (const [k, v] of flattenStrings(value, path)) {
        result.set(k, v)
      }
    }
  }

  return result
}

export function unflattenStrings(flatMap) {
  const root = {}

  for (const [path, value] of flatMap) {
    const parts = path.split('.')
    let current = root

    for (let i = 0; i < parts.length - 1; i++) {
      const part = parts[i]
      if (!(part in current) || typeof current[part] !== 'object') {
        current[part] = {}
      }
      current = current[part]
    }

    current[parts[parts.length - 1]] = value
  }

  return root
}
