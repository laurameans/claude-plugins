---
description: Create Slop Fashion outfit posts in Laszlo's voice — reactive to trending events, with satirical styling
argument-hint: "<occasion-or-event>" [product-urls...]
---

# /slop-outfit - Laszlo's Situational Styling Engine

Outfit posts for **slopfashion.com** in **Laszlo's voice**. NOT the mom-blog engine.

## Usage

```
/slop-outfit "Grammy Awards Red Carpet Response"
/slop-outfit "Super Bowl Watch Party" https://amazon.com/dp/B0xxx
/slop-outfit trending
```

## Laszlo Voice (ABSOLUTE RULES)

- Authoritative, precise, dry wit, deadpan. Imperative mood. Period-heavy. No exclamation marks.
- NO emojis. NO warmth. NO relatability.
- Banned: cute, adorable, obsessed, vibes, slay, bestie, girly, hun, mama, babe, gorgeous, stunning
- ONE satirical item when context allows (real product, presented with full authority, no winking)

## Constants

| Key | Value |
|-----|-------|
| Site | `https://slopfashion.com` |
| API Key | `slop-fashion-bot-key-2026` |
| Amazon Tag | `meansalot0c-20` |
| Engine | `~/Projects/outfit-engine/` |
| Vision Server | `cd ~/Projects/outfit-engine/services && python3 vision_server.py` |

Affiliate priority: Mavely > Amazon (`?tag=meansalot0c-20`) > CJ

---

## Execution (OPTIMIZED — follow exactly)

### Phase 1: Determine Situation

**If `trending`:** Open X, scan Trending + Following for outfit-worthy events (awards, politics, sports, viral, absurd news). Pick the most compelling. Proceed autonomously.

**If occasion provided:** Parse context, decide if satirical item fits.

### Phase 2: Find Products (USE PARALLEL AGENTS)

Find 4-7 items. **Launch 2-3 Task agents in parallel** to search different retailers simultaneously:

- **Agent 1**: Search Amazon for hero garment + shoes (use WebSearch, collect ASIN + image URL + price)
- **Agent 2**: Search REVOLVE/Nordstrom for complementary pieces (bag, accessories)
- **Agent 3** (if satirical): Find the satirical item on Amazon

For each product collect: `title`, `price`, `imageUrl` (high-res product photo URL), `affiliateUrl`, `retailer`

**Amazon affiliate URLs**: `https://www.amazon.com/dp/{ASIN}?tag=meansalot0c-20`
**REVOLVE image trick**: Change `_V1.jpg` to `_V2.jpg`/`_V3.jpg` for product-only shots (auto-handled by engine)
**Amazon images**: Use `https://m.media-amazon.com/images/I/{IMAGE_ID}._AC_SX679_.jpg` — get IMAGE_ID from search results

### Phase 3: Generate + Publish (SINGLE COMMAND)

Ensure vision server is running, then execute ONE command that does everything:

```bash
cd ~/Projects/outfit-engine && npx tsx -e "
import { generateAndPublishToSlopFashion } from './src/slop-fashion.js';
const result = await generateAndPublishToSlopFashion(
  [
    { imageUrl: 'URL', altImageUrls: [], category: 'dress', title: 'TITLE', price: '99', affiliateUrl: 'URL', retailer: 'REVOLVE' },
    // ... all items
  ],
  'Occasion Name',
  {
    event: 'Trending event headline',
    satiricalItemIndex: N,  // or undefined
    tags: ['tag1', 'situational-styling'],
  }
);
console.log(JSON.stringify(result, null, 2));
"
```

This single call handles: mockup generation, image upload to R2, Laszlo caption generation, blog post creation, and auto-publish.

### Phase 4: Post to X (@LSlop27150)

The mockup image IS the post. Use osascript clipboard method:

```bash
curl -s -o /tmp/mockup.jpg "https://slopfashion.com/images/..."
osascript -e 'set the clipboard to (read (POSIX file "/tmp/mockup.jpg") as JPEG picture)'
```

Then in browser: navigate to x.com, click compose, Cmd+V to paste image, type caption, click Post.

**DO NOT** attempt: upload_image MCP tool, fetch() from URLs, programmatic input.files.

### Phase 5: Report

```
Laszlo has issued a dress code.
  Post:      {url}
  Items:     {count} pieces, {total}
  Satirical: {title or "none"}
  X caption copied to clipboard.
```

---

## Critical Efficiency Rules

1. **DO NOT** browse retail sites one at a time. Use parallel Task agents + WebSearch.
2. **DO NOT** write captions manually. `laszlo.ts` generates all captions automatically.
3. **DO NOT** upload images separately. `generateAndPublishToSlopFashion()` handles everything.
4. **DO NOT** create intermediate gen scripts. Use inline `npx tsx -e` directly.
5. **PREFER** Amazon products (direct ASIN URL construction, no browser needed).
6. **BATCH** all product research before starting Phase 3.
7. **SKIP** confirmation prompts. Execute autonomously.
