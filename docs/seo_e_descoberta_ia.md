# SEO e descoberta por IA — portal Guardian Sense

Plano de configurações e alterações para o Google (busca) e sistemas de IA
(ChatGPT, Perplexity, etc.) encontrarem e citarem o portal com mais precisão.

**Status:** pacote mínimo implementado em 2026-09-10  
**Domínio de referência:** `https://guardian-sense.com`  
**Escopo:** camada `web/` + páginas públicas; **não** inclui rotas autenticadas.

---

## 1. Contexto e problema

O portal é um **Flutter Web (SPA)**. Crawladores e muitas IAs leem sobretudo o HTML
inicial (`web/index.html`), não o conteúdo renderizado depois pelo Dart.

### Situação atual

| Item | Estado |
|------|--------|
| `web/index.html` | Title, description, viewport, canonical, OG, Twitter, JSON-LD e bloco SEO no body |
| Open Graph / Twitter Card | Presente (`og-image.png`) |
| Canonical URL | `https://guardian-sense.com/` |
| Conteúdo HTML no `<body>` | H1, parágrafo, bullets e links (oculto visualmente; legível a bots) |
| JSON-LD (schema.org) | `WebApplication` |
| `robots.txt` | Presente |
| `sitemap.xml` | Presente (home) |
| `web/manifest.json` | Description alinhada (“celular”) |
| Rotas | Hash (`/#/login`) — ainda limitação; ver camada seguinte |

Enquanto só o Flutter mudava, textos da login quase não entravam no índice. O pacote
mínimo mitiga isso via HTML estático.

---

## 2. Objetivos

1. Google indexar a home/portal com title e snippet corretos.
2. Compartilhamento em redes (WhatsApp, LinkedIn, X) mostrar preview com imagem e texto.
3. IAs e assistentes conseguirem resumir o produto a partir de HTML/schema estável.
4. Evitar indexar área logada (Centro, Eventos, Localizar, etc.).

---

## 3. Princípios

- **HTML estático primeiro** — o que importa para crawl está em `web/`, não só no Flutter.
- **Uma URL canônica** — `https://guardian-sense.com/` (ajustar se o domínio público for outro).
- **Copy alinhada ao produto** — usar “celular” (padrão da login), não “aparelho”.
- **Não indexar o privado** — dashboard e afins bloqueados no robots.
- **Implementar em camadas** — pacote mínimo antes de landing/FAQ grandes.

---

## 4. Pacote mínimo

Arquivos sob `web/` (+ headers no `firebase.json`).

### 4.1 `web/index.html`

- [x] Atualizar `<title>` → `Guardian Sense | Central de Proteção do celular`
- [x] Atualizar `<meta name="description">`
- [x] Viewport
- [x] Meta Open Graph
- [x] Meta Twitter
- [x] Canonical
- [x] Bloco de conteúdo no `<body>` (classe `.seo-content`)
- [x] JSON-LD `WebApplication`
- [x] Asset `web/og-image.png`

### 4.2 `web/robots.txt`

- [x] `User-agent: *` / `Allow: /`
- [x] `Disallow` das rotas autenticadas / internas
- [x] `Sitemap: https://guardian-sense.com/sitemap.xml`

### 4.3 `web/sitemap.xml`

- [x] Home `https://guardian-sense.com/`
- [x] Sem listar Centro, Eventos, etc.

### 4.4 `web/manifest.json`

- [x] Description atualizada (“celular”, Central de Proteção)

### 4.5 Deploy / hosting

- [x] Headers de cache para `robots.txt`, `sitemap.xml`, `og-image.png` no `firebase.json`
- [x] Arquivos em `web/` → incluídos no `flutter build web` → `build/web` (Hosting `public`)

> Firebase Hosting serve arquivos estáticos **antes** do rewrite `** → /index.html`, então
> `/robots.txt` e `/sitemap.xml` respondem como arquivos reais após o deploy.

---

## 5. Camada seguinte (depois do mínimo)

| Item | Por quê |
|------|---------|
| Landing pública indexável em `/` (mesmo simples) | Melhor que depender só de `/#/login` |
| Reduzir dependência de hash routes para páginas públicas | SEO e compartilhamento mais limpos |
| Páginas FAQ / Sobre / Privacidade com texto real | Fonte que IAs citam |
| Google Search Console | Enviar sitemap, monitorar cobertura e erros |
| Bing Webmaster | Idem para Bing / Copilot |
| `llms.txt` (opcional, experimental) | Alguns agentes leem; não substitui HTML/schema |

---

## 6. O que não fazer

- Keyword stuffing no title/description  
- Esperar que só mudar strings no Flutter resolva SEO  
- Indexar telas autenticadas  
- Duplicar a mesma landing em várias URLs sem canonical  

---

## 7. Copy em uso

| Campo | Valor |
|-------|-------|
| Title | `Guardian Sense \| Central de Proteção do celular` |
| Description | `Guardian Sense — Central de Proteção. Seu celular continua protegido, mesmo quando está longe de você. Localize, acompanhe alertas e aja pelo portal.` |
| H1 (body estático) | `Guardian Sense` |
| Manifest description | Versão curta da description |

---

## 8. Checklist de validação

Checagem em **2026-09-10**:

### Local (`web/`) — OK

- [x] Title / description / canonical / OG / Twitter / JSON-LD / bloco SEO no body
- [x] `og:image` absoluto → `https://guardian-sense.com/og-image.png`
- [x] `og-image.png` 1200×630 (escudo oficial)
- [x] `robots.txt` e `sitemap.xml` presentes
- [x] `manifest.json` description atualizada

### Produção (`guardian-sense.com`) — pendente de deploy

- [ ] Home ainda serve o `index.html` **antigo**
- [ ] `/robots.txt` → 200 mas `Content-Type: text/html` (rewrite para `index.html`)
- [ ] `/sitemap.xml` → idem
- [ ] `/og-image.png` → idem
- [ ] Search Console: enviar sitemap após o deploy
- [ ] Rich Results Test / LinkedIn Post Inspector (opcional) após o deploy

**Conclusão:** pacote correto no repo; **só vale na internet após `flutter build web` + deploy do Hosting**.

---

## 9. Ordem de execução

1. [x] `index.html` (meta + OG + body + JSON-LD) + imagem OG  
2. [x] `manifest.json`  
3. [x] `robots.txt` + `sitemap.xml` + headers hosting  
4. [ ] Search Console / Bing (manual, após deploy)  
5. [ ] Landing/FAQ (futuro)  

---

## 10. Referências no repo

- `web/index.html` — entrada HTML  
- `web/og-image.png` — preview social  
- `web/robots.txt` / `web/sitemap.xml`  
- `web/manifest.json`  
- `firebase.json` — Hosting headers  
- `lib/app/constants.dart` — tagline, destaques, `playStoreUrl`  
- `docs/visao_geral.md` — produto e publicação  
