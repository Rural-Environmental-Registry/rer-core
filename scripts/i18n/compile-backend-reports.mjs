#!/usr/bin/env node
/** Compila locale/backend/*.po → JSON aninhado para relatórios Jasper. */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { createRequire } from 'node:module'
import { unflattenStrings } from './lib/flatten-json.mjs'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '../..')
const require = createRequire(
  pathToFileURL(join(ROOT, 'frontend/node_modules/vue3-gettext/package.json')).href,
)
const PO = require('pofile')

const localeDir = join(ROOT, 'locale/backend')
const outPaths = [
  join(ROOT, 'backend/src/main/resources/reports/i18n'),
  join(ROOT, 'config/Core-Backend/custom/reports/i18n'),
]
const LOCALES = readFileSync(join(ROOT, 'locale/LINGUAS'), 'utf8')
  .trim()
  .split('\n')
  .filter(Boolean)

function parseReportPo(poContent) {
  const catalog = PO.parse(poContent)
  const flat = new Map()

  for (const item of catalog.items) {
    if (!item.msgctxt || item.obsolete || item.flags?.fuzzy) continue
    const msgstr = item.msgstr[0]?.length ? item.msgstr[0] : item.msgid
    if (!msgstr?.length) continue
    flat.set(item.msgctxt, msgstr)
  }

  return unflattenStrings(flat)
}

for (const locale of LOCALES) {
  const poPath = join(localeDir, `${locale}.po`)
  const json = parseReportPo(readFileSync(poPath, 'utf8'))
  for (const outBase of outPaths) {
    const outDir = join(outBase, locale)
    mkdirSync(outDir, { recursive: true })
    const outFile = join(outDir, 'report_params.json')
    writeFileSync(outFile, JSON.stringify(json, null, 2))
    console.log(`Gerado: ${outFile}`)
  }
}
