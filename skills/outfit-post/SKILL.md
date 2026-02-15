---
description: Create outfit recommendation posts with affiliate links across all sites and social media
argument-hint: "<description>" [product-urls...]
---

# /outfit-post - Create & Distribute Outfit Recommendations

Takes a brief outfit description (and optional product URLs), generates affiliate links, writes blog content and social captions, publishes to the correct blog site, and posts to Pinterest + Instagram via AlohaMom accounts.

## Usage

```
/outfit-post "Coachella desert boho vibes - flowy maxi dress, cowboy boots, fringe bag"
/outfit-post "Spring in Paris - trench coat, ballet flats, crossbody bag" https://amazon.com/dp/B0xxx https://amazon.com/dp/B0yyy
/outfit-post "Park City ski day to aprés-ski dinner transition outfit"
/outfit-post "Tulum beach to restaurant sunset outfit"
```

**Arguments:** `"<description>" [product-urls...]`
- `description`: Brief outfit concept with vibe, occasion, and key pieces (in quotes)
- `product-urls`: Optional — specific product URLs to create affiliate links for

If no arguments provided, ask the user for the description.

---

## Constants

- **Cloudflare Account ID**: `1503003085362bc51e16169dd108de97`
- **API Key**: `moms-blog-bot-key-2026`
- **Amazon Affiliate Tag**: `meansalot0c-20`
- **Social Hub**: All social posts go through AlohaMom accounts

### Affiliate Networks
| Network | How to Create Links |
|---------|-------------------|
| **Amazon** | Direct URL: `https://www.amazon.com/dp/{ASIN}?tag=meansalot0c-20` |
| **CJ Affiliate** | CID: `7868406`. Use CJ Chrome extension or Deep Link Generator bookmarklet on advertiser sites. API at developers.cj.com (needs Personal Access Token). |
| **Mavely** | Dashboard: creators.joinmavely.com. Enter any URL into the SmartLink creator in the nav bar. Works with 1000+ brands (Target, Walmart, Nordstrom, etc). |

### Social Media Accounts
| Platform | Handle | Type |
|----------|--------|------|
| Pinterest | @meansalot | Business |
| Instagram | @alohamomhi | Creator |
| X/Twitter | @AlohaMomHi | — |

### Site API Endpoints
| Site | API Base |
|------|----------|
| europemoms | `https://europemoms.com/api` |
| mexicomoms | `https://mexicomoms.com/api` |
| alohamom | `https://alohamom.com/api` |
| parkcitymoms | `https://parkcitymoms.com/api` |

### Site-to-Destination Routing
| Destination Type | Blog Site |
|-----------------|-----------|
| European cities/countries | europemoms.com |
| Mexico/Caribbean destinations | mexicomoms.com |
| Hawaii/Pacific/General/Festivals | alohamom.com |
| Utah/Park City/Mountain | parkcitymoms.com |
| Non-location-specific (Coachella, general fashion) | alohamom.com |

---

## CRITICAL RULES

### Content Style
- **NEVER USE EMOJIS** in any content — plain text only
- Write in a warm, relatable, confident mom voice
- Be specific about WHY each piece works (not just "this is cute")
- Include practical details: "packs flat", "machine washable", "true to size"
- Every post MUST include FTC affiliate disclosure

### FTC Disclosure (MANDATORY)
Every blog post must include at the top of content:
```html
<p><em>This post contains affiliate links. If you make a purchase through these links, I may earn a small commission at no extra cost to you. See our <a href="/disclosure">full disclosure</a>.</em></p>
```

Every social caption must include `#ad` or `#affiliate` near the beginning (not buried in hashtags).

### Affiliate Links
- **Amazon**: Use tag `meansalot0c-20` — format: `https://www.amazon.com/dp/{ASIN}?tag=meansalot0c-20`
- **CJ Affiliate**: For brands in the CJ network, use the Deep Link Generator or CJ Chrome extension to create tracked links. CID: `7868406`.
- **Mavely**: For brands in the Mavely network (Target, Walmart, Nordstrom, etc.), paste the product URL into the SmartLink creator at creators.joinmavely.com to get a tracked link.
- **Priority**: Check Mavely first (broadest brand coverage), then Amazon (universal fallback), then CJ (for specific fashion advertisers).
- Always create the link via the site's API so clicks are tracked on the blog
- If user provides product URLs, convert them to affiliate links using the best matching network
- If no URLs provided, search Amazon or browse brand sites for 3-6 relevant products

### Image Requirements
- **Pinterest**: Tall vertical (2:3 ratio, minimum 1000x1500px)
- **Instagram**: Square (1:1, 1080x1080) or portrait (4:5, 1080x1350)
- **Blog**: Landscape or portrait, minimum 1200px wide

---

## Outfit Engine

The outfit-engine (`~/Projects/outfit-engine/`) automates the full pipeline. It can be triggered via:
- **CLI**: `cd ~/Projects/outfit-engine && npx tsx src/cli.ts "occasion" url1 url2 ...`
- **Web form**: `npm run dev` then open http://localhost:3847
- **iOS Share Sheet**: Share links from Safari, then tap "Create Outfit"
- **This skill**: Claude Code runs the pipeline directly

### Quick Pipeline (when outfit-engine server is running)
```bash
curl -X POST http://localhost:3847/api/outfit/create \
  -H "Content-Type: application/json" \
  -d '{"urls": [...], "occasion": "description", "publish": true, "postSocial": true}'
```

---

## Execution Steps

### Step 1: Parse & Route

Extract the outfit description and any product URLs from arguments.

**Always post to alohamom.com as primary**, then cross-post based on destination keywords:
- Paris, London, Rome, Barcelona, etc. → ALSO `europemoms` (with link back to alohamom)
- Tulum, Cancun, Mexico City, etc. → ALSO `mexicomoms` (with link back to alohamom)
- Park City, skiing, Deer Valley, etc. → ALSO `parkcitymoms` (with link back to alohamom)
- Coachella, general fashion, festivals → `alohamom` only

Tell the user which sites will receive the post.

### Step 2: Research & Find Products

**If product URLs were provided:**
1. For each URL, identify the retailer:
   - Amazon → append `?tag=meansalot0c-20` and use `provider_slug: "amazon"`
   - Mavely-supported brand (Target, Walmart, Nordstrom, etc.) → create SmartLink via Mavely dashboard, use `provider_slug: "mavely"`
   - CJ advertiser → use CJ deep link generator, use `provider_slug: "cj"`
2. Create affiliate links via the target site's API

**If NO product URLs were provided:**
1. Search for products matching the outfit description across sources:
   - **Amazon** for universal product search (always available)
   - **Brand sites** like Target, Nordstrom, Anthropologie for curated fashion (create Mavely SmartLinks)
2. Find 3-6 well-reviewed items (4+ stars) that match the vibe
3. Look for: the key pieces mentioned, accessories that complete the look, and one budget-friendly alternative
4. For each product, note: title, price, image URL, star rating, source URL
5. Create affiliate links via the blog API:

```bash
# For Amazon products
curl -s -X POST https://{site}/api/affiliates/links \
  -H "Authorization: Bearer moms-blog-bot-key-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_slug": "amazon",
    "title": "Product Name",
    "url": "https://www.amazon.com/dp/{ASIN}?tag=meansalot0c-20",
    "image_url": "https://...",
    "description": "Why this piece works for this outfit",
    "category": "fashion"
  }'

# For Mavely SmartLinks (Target, Walmart, Nordstrom, etc.)
curl -s -X POST https://{site}/api/affiliates/links \
  -H "Authorization: Bearer moms-blog-bot-key-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_slug": "mavely",
    "title": "Product Name",
    "url": "https://mavely.app.link/...",
    "image_url": "https://...",
    "description": "Why this piece works for this outfit",
    "category": "fashion"
  }'

# For CJ deep links
curl -s -X POST https://{site}/api/affiliates/links \
  -H "Authorization: Bearer moms-blog-bot-key-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_slug": "cj",
    "title": "Product Name",
    "url": "https://www.anrdoezrs.net/click-7868406-...",
    "image_url": "https://...",
    "description": "Why this piece works for this outfit",
    "category": "fashion"
  }'
```

### Step 3: Find/Create Feature Image

1. Search Unsplash in the browser for a photo matching the outfit vibe
   - Try searches like: "boho festival outfit", "Paris spring fashion", "ski lodge outfit"
2. Download the best match
3. Upload to R2:
```bash
curl -s -X POST https://{site}/api/images \
  -H "Authorization: Bearer moms-blog-bot-key-2026" \
  -F "file=@/tmp/outfit-photo.jpg"
```

### Step 4: Write Blog Post Content

Write 800-1500 words of HTML content. Structure:

```html
<p><em>This post contains affiliate links. See our <a href="/disclosure">full disclosure</a>.</em></p>

<h2>The Vibe</h2>
<p>Set the scene — where you're going, what the occasion is, why this outfit works.</p>

<h2>The Key Pieces</h2>
<p>Break down each item: what it is, why it works, styling tips, sizing notes.</p>
<!-- Reference each piece with specifics: fabric, fit, versatility -->

<h2>How to Style It</h2>
<p>Putting it all together — layering, accessories, day-to-night transitions.</p>

<h2>Budget-Friendly Alternatives</h2>
<p>Similar looks at lower price points.</p>

<h2>Packing Tips</h2>
<p>How these pieces pack, what else they pair with, maximizing your travel wardrobe.</p>
```

### Step 5: Publish Blog Post

```bash
curl -s -X POST https://{site}/api/posts \
  -H "Authorization: Bearer moms-blog-bot-key-2026" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Outfit Title",
    "excerpt": "Short preview description",
    "content": "<h2>...</h2>...",
    "featured_image": "/images/uploaded.jpg",
    "status": "published",
    "author": "AlohaMom",
    "location_slug": "paris",
    "meta_title": "SEO Title | Site Name",
    "meta_description": "150-160 char description with keywords",
    "categories": ["fashion"],
    "tags": ["outfit ideas", "spring fashion", "Paris style"],
    "affiliate_link_ids": [1, 2, 3, 4]
  }'
```

Note the returned slug for the post URL.

### Step 6: Generate Social Media Captions

Generate platform-specific captions from the outfit description:

**Pinterest Pin Description** (max 500 chars):
```
{Outfit title} | {Destination/occasion}

{2-3 sentences describing the outfit and why it works}

{Key pieces listed}

Shop the full look on the blog — link below.

#affiliate #outfitideas #travelstyle #{destination} #{occasion}
```

**Instagram Caption** (max 2200 chars):
```
#ad {Hook line — question or bold statement}

{2-3 short paragraphs about the outfit: the vibe, key pieces, where to wear it}

Every piece is linked on the blog — link in bio!

.
.
.
#outfitideas #traveloutfit #{destination} #momstyle #whatiwore #{occasion} #affiliatelinks
```

### Step 7: Post to Pinterest

Use the Pinterest API to create a pin:

```bash
curl -s -X POST "https://api.pinterest.com/v5/pins" \
  -H "Authorization: Bearer {PINTEREST_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Outfit title",
    "description": "{Pinterest caption}",
    "board_id": "{FASHION_BOARD_ID}",
    "media_source": {
      "source_type": "image_url",
      "url": "https://{site}/images/{key}"
    },
    "link": "https://{site}/post/{slug}"
  }'
```

**If Pinterest API is not yet configured**, skip this step and tell the user:
> Pinterest pin ready but not posted — API token needed. Set up at developers.pinterest.com.

### Step 8: Post to Instagram

Use the Instagram Graph API to create a post:

```bash
# Step 1: Create media container
curl -s -X POST "https://graph.facebook.com/v21.0/{IG_USER_ID}/media" \
  -d "image_url=https://{site}/images/{key}" \
  -d "caption={Instagram caption}" \
  -d "access_token={IG_ACCESS_TOKEN}"

# Step 2: Publish
curl -s -X POST "https://graph.facebook.com/v21.0/{IG_USER_ID}/media_publish" \
  -d "creation_id={container_id}" \
  -d "access_token={IG_ACCESS_TOKEN}"
```

**If Instagram API is not yet configured**, skip and tell the user:
> Instagram post ready but not posted — API token needed. Connect Instagram Business account to Meta Developer app.

### Step 9: Copy to Clipboard (Fallback)

If social APIs are not configured, copy the captions to clipboard so the user can paste them manually:

```bash
echo "{Pinterest caption}" | pbcopy
```

Then tell the user: "Caption copied to clipboard. Paste it into Pinterest/Instagram."

### Step 10: Report

```
Outfit post published!

  Blog:      https://{site}/post/{slug}
  Site:      {site}
  Products:  {count} affiliate links created
  Pinterest: {posted/ready — needs API token}
  Instagram: {posted/ready — needs API token}

  Affiliate links:
  - {product 1 title} → amazon.com/dp/{ASIN}
  - {product 2 title} → amazon.com/dp/{ASIN}
  ...
```

---

## Social Media Token Configuration

When social APIs are configured, tokens should be stored as environment variables or in a config file. Check for:

- `PINTEREST_TOKEN` — Pinterest API access token
- `PINTEREST_BOARD_ID` — Target board for outfit pins
- `IG_USER_ID` — Instagram Business account user ID
- `IG_ACCESS_TOKEN` — Long-lived Instagram/Meta access token

These can be stored in `~/.outfit-post-config.json`:
```json
{
  "pinterest": {
    "token": "...",
    "board_id": "..."
  },
  "instagram": {
    "user_id": "...",
    "access_token": "..."
  }
}
```

---

## Outfit Categories & Hashtag Templates

### Festival/Event Outfits (→ alohamom.com)
Tags: `#festivaloutfit #festivalfashion #concertoutfit #musicfestival #{eventname}`

### European City Style (→ europemoms.com)
Tags: `#europestyle #traveloutfit #europetravel #{city}style #packinglist`

### Beach/Resort Wear (→ mexicomoms.com or alohamom.com)
Tags: `#beachoutfit #resortwear #vacationstyle #beachstyle #{destination}`

### Mountain/Ski Style (→ parkcitymoms.com)
Tags: `#skioutfit #apresski #mountainstyle #winterfashion #skitown`

### General Travel Fashion (→ alohamom.com)
Tags: `#travelstyle #traveloutfit #packinglist #capsulewardrobe #momstyle`

---

## Available Locations by Site

### europemoms
paris, london, rome, barcelona, amsterdam, prague, lisbon, berlin, vienna, dublin, copenhagen, stockholm, zurich, florence, santorini, munich, bruges, edinburgh, nice, krakow

### mexicomoms
mexico-city, cancun, playa-del-carmen, tulum, oaxaca, san-miguel-de-allende, puerto-vallarta, guadalajara, merida, cabo-san-lucas

### alohamom
honolulu, maui, kauai, big-island, north-shore-oahu, waikiki, kona, hilo

### parkcitymoms
park-city, deer-valley, salt-lake-city, heber-city, midway, sundance, alta, snowbird
