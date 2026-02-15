# /blog-post - Create a Full Blog Post with Photos & Affiliate Links

Automates the entire blog post creation workflow for any site in the moms-blog network. Researches the topic, finds Unsplash photos, browses Amazon for affiliate products, writes SEO-optimized content, and publishes via API.

## Usage

```
/blog-post europemoms "Paris with a Toddler: Complete Survival Guide"
/blog-post mexicomoms "Tulum Beach Day with Kids"
/blog-post alohamom "Maui with a Baby: Everything You Need to Know"
/blog-post parkcitymoms "Best Family Ski Runs at Deer Valley"
/blog-post europemoms "Barcelona Family Itinerary"
```

**Arguments:** `<site> "<topic/title>"`
- `site`: `europemoms`, `mexicomoms`, `alohamom`, or `parkcitymoms`
- `topic`: the blog post title or topic (in quotes)

If no arguments provided, ask the user for both.

---

## CRITICAL RULES

### Style
- **NEVER USE EMOJIS** in any content, titles, or descriptions -- use SVG icons or plain text labels only
- **NEVER USE EM DASHES** (—) in any content, titles, excerpts, or descriptions. Use ` - ` (space-hyphen-space) instead. Em dashes are a dead giveaway for AI-written content.
- Write in a warm, authoritative mom-to-mom voice
- Content should be practical, specific, and experience-based
- Target 1500-2500 words of HTML content
- Use semantic HTML: `<h2>`, `<h3>`, `<p>`, `<ul>`, `<ol>`, `<strong>`, `<em>`
- Include internal links to other relevant destinations when natural

### SEO
- Title tag: 50-60 characters, keyword-rich
- Meta description: 150-160 characters, compelling with call-to-action
- Use the target keyword in the first paragraph
- Include 2-4 `<h2>` sections and relevant `<h3>` subsections
- Add alt text to all images (handled by featured_image alt)

### Photos
- Browse Unsplash in the browser to find high-quality, relevant travel/family photos
- Visually verify each photo is appropriate before downloading
- **ALWAYS upload images to R2** via the images API: `POST /api/images` with multipart form data — NEVER link to external image URLs (Unsplash, etc.) as featured_image. Download first, upload to R2, use the returned `/images/...` path.
- Use the returned URL as `featured_image`

### Affiliate Links
- **Amazon**: Browse Amazon for products, use tag `meansalot0c-20`. Create via `POST /api/affiliates/links` with `provider_slug: "amazon"`
- **Mavely**: For brands like Target, Walmart, Nordstrom — create SmartLinks at creators.joinmavely.com, then register via API with `provider_slug: "mavely"`
- **CJ Affiliate**: For CJ advertiser brands — use Deep Link Generator (CID: `7868406`), register via API with `provider_slug: "cj"`
- Products should be practical items a traveling parent would actually buy
- Find 3-6 well-reviewed products across networks
- Collect the returned IDs to include as `affiliate_link_ids` in the post
- **ALWAYS include inline affiliate links in the body text** — don't just list products at the bottom. Find natural mentions of each product category in the body (e.g., "sunscreen", "hiking shoes") and wrap them with the affiliate link. Every product in the packing section should have at least one contextual link in the body text above it.
- **ALWAYS verify affiliate links are working** before publishing. Test each Amazon ASIN URL (`https://www.amazon.com/dp/{ASIN}`) to confirm it returns a valid product page (not 404). Replace any broken ASINs with working alternatives.

---

## API Reference

All API calls use:
- **europemoms**: `https://europemoms.com/api/...`
- **mexicomoms**: `https://mexicomoms.com/api/...`
- **alohamom**: `https://alohamom.com/api/...`
- **parkcitymoms**: `https://parkcitymoms.com/api/...`
- **Auth header**: `Authorization: Bearer moms-blog-bot-key-2026`
- **Cloudflare Account ID**: `1503003085362bc51e16169dd108de97`

### Create Affiliate Link
```
POST /api/affiliates/links
{
  "provider_slug": "amazon",
  "title": "Product Name",
  "url": "https://www.amazon.com/dp/ASIN?tag=AFFILIATE_TAG",
  "image_url": "https://...",
  "description": "Brief description of why this product is great for traveling families",
  "category": "travel-gear"
}
Response: { "success": true, "id": 123 }
```

### Upload Image
```
POST /api/images
Content-Type: multipart/form-data
- file: (binary image data)
- alt: "Description of image"
Response: { "success": true, "url": "/images/filename.jpg" }
```

### Create Post
```
POST /api/posts
{
  "title": "Post Title",
  "slug": "post-slug",
  "excerpt": "Short description for cards and previews",
  "content": "<h2>...</h2><p>...</p>...",
  "featured_image": "/images/uploaded-photo.jpg",
  "status": "published",
  "author": "Mom-E",
  "location_slug": "paris",
  "meta_title": "SEO Title | Site Name",
  "meta_description": "150-160 char meta description",
  "categories": ["travel", "itineraries"],
  "tags": ["Paris", "toddler travel", "family vacation"],
  "affiliate_link_ids": [1, 2, 3]
}
```

### Available Categories

**europemoms**: `fashion`, `travel`, `itineraries`, `kids-tips`, `food`, `budget`
**mexicomoms**: `fashion`, `travel`, `itineraries`, `kids-tips`, `food`, `budget`
**alohamom**: `travel`, `kids`, `garden`, `itineraries`, `travel-tips`, `island-life`
**parkcitymoms**: `fashion`, `travel`, `skiing`, `dining`, `outdoor`, `family`

### Available Locations (europemoms)
`paris`, `london`, `rome`, `barcelona`, `amsterdam`, `prague`, `lisbon`, `berlin`, `vienna`, `dublin`, `copenhagen`, `stockholm`, `zurich`, `florence`, `santorini`, `munich`, `bruges`, `edinburgh`, `nice`, `krakow`

### Available Locations (mexicomoms)
`mexico-city`, `cancun`, `playa-del-carmen`, `tulum`, `oaxaca`, `san-miguel-de-allende`, `puerto-vallarta`, `guadalajara`, `merida`, `cabo-san-lucas`

### Available Locations (alohamom)
`honolulu`, `maui`, `kauai`, `big-island`, `north-shore-oahu`, `waikiki`, `kona`, `hilo`

### Available Locations (parkcitymoms)
`park-city`, `deer-valley`, `salt-lake-city`, `heber-city`, `midway`, `sundance`, `alta`, `snowbird`

---

## Execution Steps

### Step 1: Parse Arguments
Extract site and topic from arguments. Validate site is `europemoms`, `mexicomoms`, `alohamom`, or `parkcitymoms`.

### Step 2: Research Topic
Use WebSearch to research the destination/topic. Gather:
- Key attractions and activities for families
- Practical tips (transport, food, safety)
- Seasonal considerations
- Budget information

### Step 3: Find & Upload Photos
1. Open Unsplash in the browser
2. Search for relevant photos (e.g., "Paris family travel", "Tulum beach kids")
3. Visually verify 1-3 good photos
4. Download the best one for featured image
5. Upload to R2 via `POST /api/images`

### Step 4: Find Amazon Products
1. Open Amazon in the browser
2. Search for 3-6 products relevant to the destination/topic
3. Look for well-reviewed items (4+ stars) that a traveling parent would need
4. For each product, create an affiliate link via the API
5. Collect all affiliate link IDs

### Step 5: Write Content
Write 1500-2500 words of SEO-optimized HTML content including:
- Engaging introduction with the target keyword
- 3-5 major sections with `<h2>` headings
- Practical tips, specific recommendations, and personal-voice advice
- A "What to Pack" or "Essential Gear" section that naturally references affiliate products
- Conclusion with encouragement and call-to-action

### Step 6: Create Post via API
```
POST https://{site}.com/api/posts
```
With all fields populated: title, slug, excerpt, content, featured_image, status, author, location_slug, meta_title, meta_description, categories, tags, affiliate_link_ids.

### Step 7: Verify
Open the published post URL in the browser and verify it renders correctly with:
- Featured image displaying
- Content formatted properly
- Recommended Products section showing affiliate cards
- OG tags present in page source

---

## Content Templates by Category

### Travel Guide
Sections: Overview, Best Time to Visit, Getting Around, Top Family Activities, Where to Eat with Kids, What to Pack, Budget Tips

### Itinerary
Sections: Trip Overview, Day 1/2/3... breakdown, Where to Stay, Packing Essentials, Budget Breakdown

### Kids Tips
Sections: The Challenge, Our Solution, Step-by-Step Tips, Gear That Helps, Age-Specific Advice

### Fashion
Sections: The Look, Key Pieces, Where to Shop, Styling Tips for Moms, Budget-Friendly Alternatives

---

## Example Product Categories by Destination

### European Cities
- Lightweight stroller, comfortable walking shoes, crossbody bag, rain jacket, kids snack container, portable charger, packing cubes

### Mexican Beach Towns
- Reef-safe sunscreen, kids swim gear, waterproof phone case, beach shade tent, travel car seat, insect repellent, water shoes

### Hawaii / Island
- Reef-safe sunscreen, rash guards, water shoes, lightweight carrier, beach tent, snorkel gear, mosquito repellent, waterproof dry bag

### Mountain / Ski (Park City)
- Kids ski gear, hand warmers, base layers, snow boots, ski helmet, goggle wipes, insulated water bottle, après-ski cozy layers
