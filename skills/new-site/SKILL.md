---
description: Add a new location-based mom site to the multi-site blog network
argument-hint: <slug> "<Site Name>" "<tagline>" <domain>
---

# /new-site - Add a New Location-Based Blog Site

Adds a new site to the moms-blog multi-site network. Creates the D1 database entry, categories, locations, Cloudflare Pages project, and deploy script. Everything flows through AlohaMom for social media.

## Usage

```
/new-site parkcitymoms "Park City Moms" "Mountain life and family adventures" parkcitymoms.com
/new-site austinmoms "Austin Moms" "Keep Austin family-friendly" austinmoms.com
```

**Arguments:** `<slug> "<name>" "<tagline>" <domain>`
- `slug`: lowercase, no spaces (used as SITE_SLUG and Pages project name)
- `name`: Display name for the site
- `tagline`: Short site description
- `domain`: The custom domain

If no arguments provided, ask the user for all four.

---

## Constants

- **Cloudflare Account ID**: `1503003085362bc51e16169dd108de97`
- **D1 Database**: `moms-blog-db` (ID: `f263e028-cfb3-4089-8b5c-17d417e93448`)
- **R2 Bucket**: `moms-blog-images`
- **API Key**: `moms-blog-bot-key-2026`
- **Moms-blog repo**: `/Users/mom/moms-blog`

---

## Execution Steps

### Step 1: Validate Arguments

Parse the slug, name, tagline, and domain from arguments. Ensure:
- `slug` is lowercase alphanumeric with no spaces
- Domain looks valid (contains a dot)

### Step 2: Check if Site Already Exists

```bash
CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler d1 execute moms-blog-db --remote --command "SELECT id, slug FROM sites WHERE slug = '{slug}';"
```

If it exists, inform the user and ask if they want to update it instead.

### Step 3: Add Site to D1

```bash
CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler d1 execute moms-blog-db --remote --command "INSERT INTO sites (slug, name, tagline, domain) VALUES ('{slug}', '{name}', '{tagline}', '{domain}');"
```

Then get the site_id:
```bash
CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler d1 execute moms-blog-db --remote --command "SELECT id FROM sites WHERE slug = '{slug}';"
```

### Step 4: Add Default Categories

Ask the user what kind of location this is and customize categories. Use these defaults as a starting point, then adjust:

**For beach/island destinations:**
```sql
INSERT INTO categories (site_id, slug, name, description, sort_order) VALUES
({id}, 'fashion', 'Fashion & Outfits', 'Style and outfit ideas for {name}', 1),
({id}, 'travel', 'Travel', 'Travel guides and destination tips', 2),
({id}, 'beach', 'Beach Life', 'Beach activities and essentials', 3),
({id}, 'food', 'Food & Dining', 'Best restaurants and local food', 4),
({id}, 'adventure', 'Adventures', 'Outdoor activities and excursions', 5),
({id}, 'family', 'Family Life', 'Family-friendly activities and tips', 6);
```

**For mountain/ski destinations:**
```sql
INSERT INTO categories (site_id, slug, name, description, sort_order) VALUES
({id}, 'fashion', 'Fashion & Outfits', 'Mountain chic style and outfit ideas', 1),
({id}, 'travel', 'Travel & Day Trips', 'Exploring the area and beyond', 2),
({id}, 'skiing', 'Skiing & Snow Sports', 'Ski resorts and winter adventures', 3),
({id}, 'dining', 'Food & Dining', 'Best restaurants and cafes', 4),
({id}, 'outdoor', 'Outdoor Adventures', 'Hiking, biking, and year-round activities', 5),
({id}, 'family', 'Family Life', 'Raising kids in the area', 6);
```

**For European cities:**
```sql
INSERT INTO categories (site_id, slug, name, description, sort_order) VALUES
({id}, 'fashion', 'Fashion & Outfits', 'European style and outfit inspiration', 1),
({id}, 'travel', 'Travel', 'Guides and tips for traveling with kids', 2),
({id}, 'itineraries', 'Itineraries', 'Day-by-day family itineraries', 3),
({id}, 'kids-tips', 'Kids Tips', 'Practical tips for traveling with children', 4),
({id}, 'food', 'Food', 'Family-friendly restaurants and local food', 5),
({id}, 'budget', 'Budget', 'Money-saving tips and budget guides', 6);
```

**IMPORTANT**: Always include 'fashion' as category #1 — this enables outfit posts on every site.

### Step 5: Add Relevant Locations

Ask the user what key locations/neighborhoods/areas to add for this site. Then:

```sql
INSERT OR IGNORE INTO locations (slug, name, country, region, latitude, longitude) VALUES
('{slug}', '{name}', '{country}', '{region}', {lat}, {lng});
```

Use WebSearch to look up latitude/longitude for each location.

### Step 6: Create Cloudflare Pages Project

Check if project already exists:
```bash
CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler pages project list
```

If not, create it:
```bash
CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler pages project create {slug}
```

### Step 7: Update package.json

Add a deploy script to `/Users/mom/moms-blog/package.json`:
```json
"deploy:{slug}": "CLOUDFLARE_ACCOUNT_ID=1503003085362bc51e16169dd108de97 wrangler pages deploy dist --project-name={slug}"
```

Also update the `deploy:all` script to include the new site.

### Step 8: Deploy

```bash
cd /Users/mom/moms-blog && npm run build && npm run deploy:{slug}
```

### Step 9: Set SITE_SLUG in Pages Dashboard

Tell the user:
> Set the environment variable `SITE_SLUG={slug}` in the Cloudflare Pages project settings for `{slug}`. Go to: Cloudflare Dashboard > Pages > {slug} > Settings > Environment Variables > Add: SITE_SLUG = {slug}

Also tell them to add the D1 and R2 bindings if not automatically inherited.

### Step 10: Configure Domain

Tell the user:
> Add your custom domain `{domain}` to the Pages project in Cloudflare Dashboard > Pages > {slug} > Custom domains. If the domain is already on Cloudflare, it will auto-configure DNS.

### Step 11: Verify

```bash
curl -s https://{slug}.pages.dev/ | head -20
```

Or if custom domain is configured:
```bash
curl -s https://{domain}/ | head -20
```

### Step 12: Report

Print a summary:
```
Site created successfully!

  Name:       {name}
  Slug:       {slug}
  Domain:     {domain}
  Site ID:    {id}
  Categories: 6
  Locations:  {count}
  Deploy:     npm run deploy:{slug}

Manual steps needed:
  1. Set SITE_SLUG={slug} in Cloudflare Pages environment variables
  2. Add D1 binding (DB → moms-blog-db) in Pages settings
  3. Add R2 binding (IMAGES → moms-blog-images) in Pages settings
  4. Add custom domain {domain} to Pages project
```

---

## All Current Sites

| Slug | Name | Domain | Social Hub |
|------|------|--------|-----------|
| europemoms | Europe Moms | europemoms.com | AlohaMom |
| mexicomoms | Mexico Moms | mexicomoms.com | AlohaMom |
| alohamom | Aloha Mom | alohamom.com | AlohaMom (primary) |
| parkcitymoms | Park City Moms | parkcitymoms.com | AlohaMom |
