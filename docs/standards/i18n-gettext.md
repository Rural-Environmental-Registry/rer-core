# Internacionalização com gettext

Este documento descreve o padrão de i18n do projeto RER-DPG usando **GNU gettext** (arquivos PO/POT), com manutenção das traduções no **Hosted Weblate** (plano Libre).

## Convenções

- **msgid (frontend):** texto em inglês literal, como aparece no código (`$gettext('Register property')`).
- **msgctxt (backend/relatórios):** caminho JSON da chave (`header.title_text`) quando a estrutura aninhada precisa ser reconstruída.
- **Locales suportados:** `en-us`, `pt-br`, `es-es` (definidos em [`locale/LINGUAS`](../../locale/LINGUAS)).
- **Idioma padrão:** primeira linha de `locale/LINGUAS` (`en-us`).

## Estrutura de arquivos

```
locale/
├── LINGUAS
├── frontend/
│   ├── messages.pot      # template UI
│   ├── en-us.po
│   ├── pt-br.po
│   ├── es-es.po
│   └── translations.json # gerado no build (runtime)
└── backend/
    ├── reports.pot
    ├── en-us.po
    ├── pt-br.po
    └── es-es.po
```

## Frontend (vue3-gettext)

### Comandos locais

```bash
cd frontend
npm run gettext:extract   # extrai strings do código → atualiza .pot/.po
npm run gettext:compile   # compila .po → translations.json
npm run build             # inclui compile automaticamente
```

### Uso no código

```vue
<script setup lang="ts">
import { useGettext } from 'vue3-gettext'
const { $gettext } = useGettext()
</script>

<template>
  <h1>{{ $gettext('Choose the option based on what you want to do.') }}</h1>
</template>
```

Lookups dinâmicos (chaves legadas): [`frontend/src/i18n/dynamicTranslations.ts`](../../frontend/src/i18n/dynamicTranslations.ts) e [`frontend/src/i18n/legacyKeyMap.ts`](../../frontend/src/i18n/legacyKeyMap.ts).

## Backend (relatórios Jasper)

- PO em `locale/backend/` compilados para `reports/i18n/{locale}/report_params.json` via Gradle (`compileReportTranslations`).
- `ReceiptGenerator` carrega parâmetros de `reports/i18n/{locale}/` via `TranslationCatalogService` (locale por `Accept-Language` ou query `locale`).
- Fallback: `en-us`.

## Weblate

Guia de implantação (Hosted Weblate, plano Libre, PR para `develop`): [weblate-setup.md](./weblate-setup.md).

Resumo do projeto no Weblate: **RER-DPG**, dois componentes:

| Componente | File mask | Template |
|------------|-----------|----------|
| frontend-ui | `locale/frontend/*.po` | `locale/frontend/messages.pot` |
| backend-reports | `locale/backend/*.po` | `locale/backend/reports.pot` |

Formato: **GNU gettext PO (monolingual)**. Idioma base: `en-us`.

Workflow: tradutor edita no Weblate → Pull Request para `develop` → desenvolvedor valida localmente (`gettext:compile` e, se o PO de relatório mudou, `node scripts/i18n/compile-backend-reports.mjs`).

## CI / pipelines

**Fora de escopo na implementação atual.** Jobs futuros sugeridos (apenas referência):

- `i18n-extract` — falhar se `.pot` desatualizado
- `i18n-compile` — validar sintaxe PO
- `i18n-check` — listar traduções vazias

## Adicionar novo idioma

1. Incluir código em `locale/LINGUAS`
2. Copiar `messages.pot` → `locale/frontend/{codigo}.po` e traduzir `msgstr`
3. Idem para `locale/backend/{codigo}.po`
4. Registrar locale em `vue-gettext.config.ts` e `TranslationCatalogService`

## Política de manutenção

- **Desenvolvedores:** strings em inglês no código; rodar `gettext:extract`; commitar `.pot` + `.po`.
- **Tradutores (Weblate):** editar apenas `msgstr`.
- Não editar `translations.json` ou JSON compilado de relatórios manualmente.
