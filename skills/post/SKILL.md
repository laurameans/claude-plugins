---
description: Unified content command center - create any post for any site with natural language
argument-hint: <e.g. "outfit for lunch in Maui" or "Laszlo response to the Grammys" or "blog about skiing in Park City">
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch, Task, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__javascript_tool, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__find, mcp__claude-in-chrome__get_page_text
---

# Unified Post Command Center

**Input:** $ARGUMENTS

Single entry point for ALL content creation across the entire blog network + Slop Fashion. Parses natural language, auto-routes to the correct site, auto-selects voice (Mom vs Laszlo), and handles the full pipeline from idea to deployed post.

---

## Step 1: Parse Intent

Analyze $ARGUMENTS to determine:

### A. Content Type
| Signal | Type |
|--------|------|
| "outfit", "wear", "what to wear", fashion items, product URLs, "style", "look" | **Outfit Post** |
| "blog", "guide", "tips", "things to do", "review", "best", "where to" | **Blog Post** |
| "Laszlo", "slop", "satirical", "response to", "trending", "dress code" | **Laszlo Outfit** (Slop Fashion) |
| Ambiguous with location + occasion | Default to **Outfit Post** |

### B. Target Site (Auto-Route by Keywords)

| Keywords / Signals | Site | Slug |
|---|---|---|
| Hawaii, Maui, Oahu, Kauai, Waikiki, Big Island, Kona, Hilo, Molokai, Lanai, aloha, luau, tropical, lei, plumeria, shave ice, poke | **Aloha Mom** | `alohamom` |
| Paris, London, Rome, Barcelona, Italy, France, Spain, Germany, Amsterdam, Prague, Vienna, Lisbon, Greece, Santorini, Mykonos, Amalfi, Swiss, Alps, European, EU | **Europe Moms** | `europemoms` |
| Mexico, Cancun, Cabo, Tulum, Puerto Vallarta, Playa del Carmen, Riviera Maya, Caribbean, Jamaica, Bahamas, Aruba, Dominican, Cozumel, Latin | **Mexico Moms** | `mexicomoms` |
| Park City, Utah, skiing, snowboarding, Deer Valley, Sundance, mountain, ski, lodge, powder, après, Salt Lake, Wasatch | **Park City Moms** | `parkcitymoms` |
| Laszlo, slop, slopfashion, satirical, "response to", trending event, situational styling | **Slop Fashion** | `slopfashion` |
| General fashion, no clear location, festivals, concerts, date night, general travel | **Aloha Mom** (default hub) | `alohamom` |

### C. Voice Selection
| Site | Voice | Author |
|------|-------|--------|
| alohamom | Warm, relatable mom. Practical travel tips, personal experience. | Mom-E |
| europemoms | Warm, relatable mom. European travel focus. | Mom-E |
| mexicomoms | Warm, relatable mom. Mexico/Caribbean focus. | Mom-E |
| parkcitymoms | Warm, relatable mom. Mountain/ski life focus. | Mom-E |
| slopfashion | **LASZLO** — Authoritative, deadpan, dry wit. Commands, not suggestions. No emojis. Period-heavy. Satirical item when appropriate. | Laszlo |

### D. Extract Details
- **Occasion/Event**: "lunch in Maui", "beach day", "Super Bowl party", "Grammys response"
- **Location**: specific city/region for the post
- **Product URLs**: any URLs provided in the input
- **Season/Weather**: infer from location + time of year
- **Budget**: if mentioned ("budget-friendly", "splurge", "under $200")

---

## Step 2: Announce Plan

Display a brief summary:
```
POSTING TO: [Site Name] ([domain])
TYPE: [Outfit Post / Blog Post]
VOICE: [Mom-E / Laszlo]
TOPIC: [parsed occasion/topic]
```

Do NOT ask for confirmation — proceed immediately.

---

## Step 3: Execute Pipeline

### For OUTFIT POSTS (Mom-Blog Network)

1. **Find Products** (4-7 items):
   - If product URLs provided: scrape those URLs for product details
   - If no URLs: search for products that match the occasion/location
   - Use browser automation to find products on REVOLVE, Target, Nordstrom, Amazon, Abercrombie
   - For each product, capture: title, price, image URL, product URL, retailer
   - Prioritize: one hero piece (dress/top), complementary bottom (if needed), shoes, bag, 1-2 accessories

2. **Generate Affiliate Links**:
   - Check if product URL can be converted to Mavely SmartLink (highest priority)
   - If Amazon product: construct `amazon.com/dp/{ASIN}?tag=meansalot0c-20`
   - If no affiliate available: use direct product URL
   - Register each link via API:
     ```bash
     curl -s -X POST https://[site-domain]/api/affiliates/links \
       -H "Authorization: Bearer moms-blog-bot-key-2026" \
       -H "Content-Type: application/json" \
       -d '{"provider_slug":"mavely|amazon|cj","title":"...","url":"...","image_url":"...","category":"fashion"}'
     ```

3. **Generate Mockup** (via outfit-engine):
   ```bash
   cd ~/Projects/outfit-engine
   # Create a gen script in .tmp/ and run it
   npx tsx .tmp/gen_[timestamp].mjs
   ```
   The gen script imports `generateMockup` from `./src/mockup.js` and passes the product items.

4. **Write Blog Post** (Mom Voice):
   - Title: descriptive, SEO-friendly ("What to Wear to a Beach Lunch in Maui")
   - Excerpt: 1-2 sentence summary
   - Content: 800-1500 words in warm mom voice
     - Opening: personal hook about the occasion/location
     - Each item: why it works, practical details (packs flat, machine washable, true to size)
     - Styling tips: how pieces work together
     - Closing: encouragement, location tips
   - Include affiliate disclosure at top
   - Featured image: the mockup portrait image

5. **Publish via API**:
   ```bash
   curl -s -X POST https://[site-domain]/api/posts \
     -H "Authorization: Bearer moms-blog-bot-key-2026" \
     -H "Content-Type: application/json" \
     -d '{
       "title": "...",
       "slug": "...",
       "excerpt": "...",
       "content": "...",
       "featured_image": "...",
       "status": "published",
       "author": "Mom-E",
       "categories": ["fashion"],
       "tags": ["outfit inspo", "..."],
       "affiliate_link_ids": [...]
     }'
   ```

6. **Generate Social Captions** (Mom Voice):
   - **Instagram**: Warm, lifestyle-focused, 3-5 relevant hashtags
   - **Pinterest**: SEO-rich description with keywords
   - **X/Twitter**: Short, punchy, link to post
   - Copy all captions to clipboard

### For OUTFIT POSTS (Slop Fashion / Laszlo)

1. **Find Products** (4-7 items) — **USE PARALLEL AGENTS**:
   - Launch 2-3 Task agents simultaneously to search different retailers
   - Agent 1: Amazon hero garment + shoes (WebSearch, collect ASIN + image URL + price)
   - Agent 2: REVOLVE/Nordstrom bag + accessories
   - Agent 3 (if satirical): Find the satirical item on Amazon
   - Prefer Amazon products (direct ASIN URL construction: `amazon.com/dp/{ASIN}?tag=meansalot0c-20`)
   - Batch all research before proceeding to generate

2. **Generate + Publish** (SINGLE COMMAND via outfit-engine):
   ```bash
   cd ~/Projects/outfit-engine && npx tsx -e "
   import { generateAndPublishToSlopFashion } from './src/slop-fashion.js';
   const result = await generateAndPublishToSlopFashion(
     [/* items array with imageUrl, category, title, price, affiliateUrl, retailer */],
     'Occasion Name',
     { event: 'Event headline', satiricalItemIndex: N, tags: ['tag1'] }
   );
   console.log(JSON.stringify(result, null, 2));
   "
   ```
   This handles EVERYTHING: mockup generation, Laszlo caption generation (via laszlo.ts), image upload, post creation, and auto-publish.
   DO NOT write captions manually or upload images separately.

3. **Social Captions**: Auto-generated in Laszlo's voice by the engine, copied to clipboard

### For BLOG POSTS (Non-Outfit)

1. **Research Topic**:
   - WebSearch for current, relevant information
   - Find 5-10 relevant affiliate products to recommend
   - Gather location-specific details if applicable

2. **Write Blog Post** (Mom Voice, 1500-2500 words):
   - SEO-optimized title
   - Structured with H2/H3 headings
   - Personal anecdotes and practical tips
   - Product recommendations with affiliate links woven in naturally
   - Location tips, best times to visit, family-friendly advice
   - Include affiliate disclosure

3. **Upload Featured Image**:
   - If product-related: generate a mockup
   - If location/travel: search for and use a relevant image
   ```bash
   curl -s -X POST https://[site-domain]/api/images/upload \
     -H "Authorization: Bearer moms-blog-bot-key-2026" \
     -F "file=@/path/to/image.jpg"
   ```

4. **Publish and Deploy**: Same API flow as outfit posts

---

## Step 4: Output Summary

After publishing, display:

```
PUBLISHED
Site: [Site Name]
URL: https://[domain]/post/[slug]
Voice: [Mom-E / Laszlo]
Items: [count] products, [total price]
Mockup: [path to generated mockup image]

SOCIAL CAPTIONS (copied to clipboard):
[Instagram caption]
---
[X/Twitter caption]
---
[Pinterest caption]
```

---

## Voice Reference: Laszlo

When posting to Slop Fashion, ALL copy must follow Laszlo's voice:

**Tone**: Authoritative, precise, dry wit. Deadpan humor delivered with a straight face.
**Mood**: Imperative. Commands, not suggestions.
**Format**: Short declarative sentences. Period-heavy. No exclamation marks except satirical emphasis.
**Perspective**: Third person for fashion ("Fashion requires..."), first person for directives ("I have assembled...")
**NEVER use**: cute, adorable, obsessed, vibes, slay, bestie, girly, hun, mama, babe
**NEVER use emojis**
**Satirical item**: One deliberately absurd product when the event context allows. Present with complete authority. The humor is in the juxtaposition.

**Post structure**:
```
[Event context — 2 sentences max]. The dress code has been issued.

THE DIRECTIVE
- [Item] ([price], [retailer]) — Selected.
- [Satirical item] — This piece is the editorial response. Do not question it.

THE RULING
[Occasion] demands structure. Every piece has been selected for this moment.
[Price] total. No substitutions.
```

---

## Voice Reference: Mom-E (Blog Network)

**Tone**: Warm, confident, relatable. Like advice from a well-traveled friend.
**Format**: Conversational paragraphs, practical details, personal touches.
**Include**: Sizing notes, material feel, packability, "I love this because..." moments.
**NEVER use emojis**

---

## Site API Reference

| Site | Domain | API Base | Auth |
|------|--------|----------|------|
| Aloha Mom | alohamom.com | https://alohamom.com/api | Bearer moms-blog-bot-key-2026 |
| Europe Moms | europemoms.com | https://europemoms.com/api | Bearer moms-blog-bot-key-2026 |
| Mexico Moms | mexicomoms.com | https://mexicomoms.com/api | Bearer moms-blog-bot-key-2026 |
| Park City Moms | parkcitymoms.com | https://parkcitymoms.com/api | Bearer moms-blog-bot-key-2026 |
| Slop Fashion | slopfashion.com | https://slopfashion.com/api | Bearer slop-fashion-bot-key-2026 |

## Affiliate Link Priority
1. **Mavely** — broadest coverage (Target, Walmart, Nordstrom, Columbia, etc.)
2. **Amazon** — universal fallback, tag: `meansalot0c-20`
3. **CJ** — fashion-specific

## Deploy Commands (if needed)
```bash
cd ~/moms-blog
npm run deploy:alohamom       # or europemoms, mexicomoms, parkcitymoms
npm run deploy:all            # All 4 sites
```

---

## Features You Didn't Know You Wanted

This skill also supports these advanced commands:

### Quick Variations
- `/post "same outfit but for Park City"` — adapts the last outfit to a different site/climate
- `/post "update [slug] with new featured image"` — updates an existing post
- `/post "trending"` — scans X for trending events, suggests outfit concepts for Laszlo

### Cross-Site Intelligence
- `/post "what haven't I posted about recently?"` — checks all sites for content gaps
- `/post "republish [slug] to [other-site]"` — adapts and cross-posts content

### Batch Operations
- `/post "3 outfits for Maui: beach, dinner, hiking"` — creates multiple posts in one go

---

## Rules

1. **NEVER ask for confirmation** — parse intent and execute immediately
2. **NEVER mix voices** — Mom sites get Mom voice, Slop Fashion gets Laszlo
3. **Always include affiliate disclosure** in blog posts
4. **Always generate social captions** and report them
5. **Default to alohamom** when location is ambiguous or general
6. **Default to outfit post** when type is ambiguous
7. **Use the outfit-engine** for mockup generation — never skip the mockup for outfit posts
8. **Register all affiliate links** via the site's API before publishing
9. **NEVER use em dashes** (—) in any content, titles, excerpts, or descriptions. Use ` - ` (space-hyphen-space) instead. Em dashes are a dead giveaway for AI-written content.
10. **ALWAYS include inline affiliate links in the body text** — don't just list products at the bottom. Find natural mentions of each product category in the body (e.g., "sunscreen", "hiking shoes") and wrap them with the corresponding affiliate link. Every product in the packing/essentials section should have at least one contextual link in the body text above it.
11. **Inline links MUST be contextually relevant** — only link a word/phrase when the surrounding sentence is actually talking about that product. Never match substrings inside other words (e.g., "hat" inside "that's", "trail" when referring to a place name). Never link proper nouns, place names, or branded locations to unrelated products (e.g., "Outlets" shopping center to a travel adapter). The linked text must genuinely refer to the product being linked.
12. **ALWAYS upload images to R2** — never use external image URLs as featured_image. Download the image first, upload to R2 via `POST /api/images`, and use the returned `/images/...` path.
13. **ALWAYS verify affiliate links are working** before publishing. Test each Amazon ASIN URL (`https://www.amazon.com/dp/{ASIN}`) to confirm it returns a valid product page (not 404). Replace any broken ASINs with working alternatives.
