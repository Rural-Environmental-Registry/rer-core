/** Utilitários para formatação de arquivos GNU gettext PO. */

export function escapePoString(value) {
  return String(value)
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
}

export function poHeader({ language, project }) {
  const now = new Date().toISOString()
  const langLine = language ? `"Language: ${language}\\n"\n` : ''
  return `# ${project} translations.
# Copyright (C) ${new Date().getFullYear()} RER-DPG
# This file is distributed under the same license as the RER-DPG package.
#
msgid ""
msgstr ""
"Project-Id-Version: rer-dpg\\n"
"POT-Creation-Date: ${now}\\n"
"PO-Revision-Date: ${now}\\n"
"Last-Translator: RER-DPG\\n"
"Language-Team: ${language ?? 'en-us'}\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
${langLine}`
}

export function poEntry({ msgctxt, msgid, msgstr, reference }) {
  const lines = []
  if (reference) {
    lines.push(`#: ${reference}`)
  }
  if (msgctxt) {
    lines.push(`msgctxt "${escapePoString(msgctxt)}"`)
  }
  lines.push(`msgid "${escapePoString(msgid)}"`)
  lines.push(`msgstr "${escapePoString(msgstr)}"`)
  lines.push('')
  return lines.join('\n')
}

export function buildPoFile({ header, entries }) {
  return `${header}\n${entries.join('\n')}`
}
