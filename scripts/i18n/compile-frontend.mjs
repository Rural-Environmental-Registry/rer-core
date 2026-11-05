#!/usr/bin/env node
/** Compila locale/frontend/*.po → locale/frontend/translations.json (formato vue3-gettext). */
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { createRequire } from 'node:module'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '../..')
const require = createRequire(
  pathToFileURL(join(ROOT, 'frontend/node_modules/vue3-gettext/package.json')).href,
)
const PO = require('pofile')

const localeDir = join(ROOT, 'locale/frontend')
const LOCALES = readFileSync(join(ROOT, 'locale/LINGUAS'), 'utf8')
  .trim()
  .split('\n')
  .filter(Boolean)

function sanitizePoData(poItems) {
  const messages = {}
  for (const item of poItems) {
    const ctx = item.msgctxt || ''
    if (item.msgstr[0]?.length > 0 && !item.flags?.fuzzy && !item.obsolete) {
      if (!messages[item.msgid]) messages[item.msgid] = {}
      messages[item.msgid][ctx] = item.msgstr.length === 1 ? item.msgstr[0] : item.msgstr
    }
  }
  for (const key of Object.keys(messages)) {
    if (Object.keys(messages[key]).length === 1 && messages[key]['']) {
      messages[key] = messages[key]['']
    }
  }
  return messages
}

function po2json(poContent) {
  const catalog = PO.parse(poContent)
  if (!catalog.headers.Language) {
    throw new Error('Cabeçalho Language ausente no arquivo PO')
  }
  return {
    headers: catalog.headers,
    messages: sanitizePoData(catalog.items),
  }
}

const translations = {}

for (const locale of LOCALES) {
  const poPath = join(localeDir, `${locale}.po`)
  const data = po2json(readFileSync(poPath, 'utf8'))
  translations[data.headers.Language] = data.messages
}

const outPath = join(localeDir, 'translations.json')
writeFileSync(outPath, JSON.stringify(translations, null, 2))

const frontendRuntimePath = join(ROOT, 'frontend/src/i18n/translations.json')
writeFileSync(frontendRuntimePath, JSON.stringify(translations, null, 2))

console.log(`Gerado: ${outPath} e ${frontendRuntimePath} (${LOCALES.length} locales)`)
