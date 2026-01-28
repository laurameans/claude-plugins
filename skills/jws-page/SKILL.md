---
description: Create and modify webpage content on JWS websites
argument-hint: <hostname> <action> [page-slug] [instructions]
allowed-tools: Bash, Read, Write, WebFetch, Grep, Glob, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__read_page
---

# JWS Page Manager

**Target:** $ARGUMENTS

## Argument Parsing

Parse arguments as: `<hostname> <action> [page-slug] [instructions]`

Actions:
- `list` - List all pages for the website
- `get <slug>` - Get full page content as JSON
- `create <slug> "<instructions>"` - Create new page from natural language
- `update <slug> "<instructions>"` - Update existing page from natural language
- `delete <slug>` - Delete a page (requires confirmation)

## Server Detection

| Server | Base URL | Sites |
|--------|----------|-------|
| Means | outtakes.com | means.ai, outtakes.com, jws.ai, flow.outtakes.com, dave.means.ai |
| Voosey | api.voosey.com | voosey.com, dajh.com, sixpacmanco.com |

## Execution Flow

### Phase 1: Resolve Website

Get website info to obtain the website UUID:

```bash
swift scripts/website-api.swift get <hostname>
```

Extract the website `id` from the JSON response.

### Phase 2: Execute Action

#### LIST Action

```bash
# Determine server based on hostname
# Means hosts: means.ai, outtakes.com, jws.ai, flow.outtakes.com, dave.means.ai
# Voosey hosts: voosey.com, dajh.com, sixpacmanco.com

# For means server:
curl -s -H "jws_master_key: 2571123FD179EA45A21B5563D4B1D" \
  "https://outtakes.com/v2/mainframe/web/pages/<website-id>"

# For voosey server:
curl -s -H "jws_master_key: 2571123FD179EA45A21B5563D4B1D" \
  "https://api.voosey.com/v2/mainframe/web/pages/<website-id>"
```

Display pages in a readable format showing: title, slug, id.

#### GET Action

```bash
swift scripts/webpage-api.swift get <website-id> <page-id>
```

First list pages to find the page ID by slug, then get the full page content.

#### CREATE Action

1. Generate page JSON based on natural language instructions
2. Write JSON to `/tmp/jws-page-new.json`
3. Execute:
```bash
swift scripts/webpage-api.swift post <website-id> /tmp/jws-page-new.json
```

#### UPDATE Action

1. Get existing page content
2. Modify based on instructions (preserve existing content where not mentioned)
3. Write updated JSON to `/tmp/jws-page-update.json`
4. Execute:
```bash
swift scripts/webpage-api.swift put <website-id> <page-id> /tmp/jws-page-update.json
```

#### DELETE Action

1. Confirm with user before proceeding
2. Execute:
```bash
swift scripts/webpage-api.swift delete <website-id> <page-id>
```

### Phase 3: Browser Verification (for create/update)

**3a. Open site in browser**
```
mcp__claude-in-chrome__tabs_context_mcp (createIfEmpty: true)
mcp__claude-in-chrome__tabs_create_mcp
mcp__claude-in-chrome__navigate to https://<hostname>/<page-slug>
mcp__claude-in-chrome__computer action: wait, duration: 3
```

**3b. Take screenshot**
```
mcp__claude-in-chrome__computer action: screenshot
```

**3c. Analyze screenshot**
Visually verify the page:
- Does the content appear correctly?
- Are there layout issues?
- Did the update apply as expected?

**3d. Self-correction loop**
If the page doesn't look right:
1. Analyze what went wrong
2. Adjust the JSON in `/tmp/jws-page-*.json`
3. Re-push with the API
4. Wait 3 seconds for cache
5. Hard refresh: `mcp__claude-in-chrome__computer action: key, text: "cmd+shift+r"`
6. Take new screenshot
7. Repeat until correct (max 3 iterations)

### Phase 4: Report to User

- Show the screenshot (for create/update)
- Summarize what was done
- Provide the page URL

---

## Page Structure Reference

### WebPageGlobal (Top Level)
```json
{
  "micro": { /* WebPageMicro */ },
  "sections": [ /* WebSection[] */ ]
}
```

### WebPageMicro (Page Metadata)
```json
{
  "id": null,           // null for new pages, UUID for updates
  "title": "Page Title",
  "slug": "page-slug",
  "createdDate": "2025-01-22T00:00:00Z",
  "updatedDate": "2025-01-22T00:00:00Z",
  "visibility": "published",
  "taxonomy": "article",
  "isTaxonomyBase": false,
  "featuredImageURL": "https://...",
  "metaDescription": "SEO description",
  "keywords": "keyword1, keyword2"
}
```

### Visibility Options
- `published` - Public page
- `draft` - Not publicly visible
- `userAuthenticated` - Requires login
- `internal` - Internal use only
- `confidential` - Restricted access
- `restricted` - Limited access

### Taxonomy Options
- `article` - Blog post / news article
- `devlog` - Development log
- `documentation` - Technical docs
- `internal` - Internal page
- `onboarding` - User onboarding
- `publication` - Book / publication

### WebSection
```json
{
  "id": "uuid",
  "rows": [ /* WebRow[] */ ],
  "enabled": true,
  "type": { "standard": {} }  // or "fullWidth" or "fullWidthAndHeight"
}
```

### Section Types
- `{ "standard": {} }` - Normal width section
- `{ "fullWidth": {} }` - Full width section
- `{ "fullWidthAndHeight": {} }` - Full viewport section

### WebRow
```json
{
  "id": "uuid",
  "columns": [ /* WebColumn[] */ ],
  "enabled": true
}
```

### WebColumn
```json
{
  "id": "uuid",
  "contents": [ /* WebContent[] */ ]
}
```

### WebContent
```json
{
  "id": "uuid",
  "type": { "text": {} },  // Module type
  "value": "<h1>Hello</h1>",
  "link": null,
  "enabled": true,
  "rawHTML": null,
  "doubleWidth": false,
  "style": "custom-class",
  "darkModeValue": null,
  "altText": null
}
```

### Content Types (ModuleType)
- `{ "text": {} }` - HTML text content (value = HTML string)
- `{ "image": {} }` - Image (value = URL, altText for accessibility)
- `{ "button": {} }` - Button (value = label, link = URL)
- `{ "video": {} }` - Video embed (value = URL)
- `{ "portfolio": {} }` - Portfolio grid

---

## Example Invocations

```
/jws-page means.ai list
/jws-page means.ai get about
/jws-page means.ai create news "Create a news page announcing our new AI product called Fabric"
/jws-page means.ai update about "Add a team section with 3 placeholder team members"
/jws-page outtakes.com create docs "Create a documentation page for our API"
/jws-page voosey.com delete old-page
```

---

## Important Notes

1. **Generate UUIDs**: When creating new pages, generate fresh UUIDs for all `id` fields in sections, rows, columns, and contents. Use format: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

2. **Preserve Content**: When updating, fetch the existing page first and preserve content not mentioned in the instructions.

3. **HTML in Text**: The `value` field for text content accepts HTML. Use semantic tags like `<h1>`, `<h2>`, `<p>`, `<ul>`, `<li>`, etc.

4. **Date Format**: Use ISO 8601 format for dates: `2025-01-22T00:00:00Z`

5. **Minimal Changes**: For updates, make targeted changes only. Don't restructure the entire page unless asked.
