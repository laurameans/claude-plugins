---
description: Generate hourly news digest from X using curated lists and Following feed
allowed-tools: mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__javascript_tool, mcp__claude-in-chrome__read_page, mcp__claude-in-chrome__find
---

# X News Aggregator

Generate a 12-story news digest from pinned X lists + Following feed (chronological).

## Sources (Hardcoded)

| Source | URL | Volume | J-key Scrolls |
|--------|-----|--------|---------------|
| Intelligence | https://x.com/i/lists/1495874616409014273 | HIGH | 50-60 total (in batches of 15-20) |
| AI | https://x.com/i/lists/1551731754930606080 | MEDIUM | 20-30 total |
| MLX | https://x.com/i/lists/1884325179582734603 | LOW (8 members) | 5-10 total |
| Following | https://x.com/home | MEDIUM | 20-30 total |

**Note:** Following tab requires setup: Click "Following" tab → Click "Sort by" → Select "Recent"

## Execution Steps (Parallel with Adaptive Scrolling)

1. **Initialize**: `tabs_context_mcp` (createIfEmpty: true)
2. **Create 3 additional tabs**: `tabs_create_mcp` x3 (total 4 tabs)
3. **Navigate all 4 tabs in parallel** to their URLs
4. **Wait 1.5s** for pages to load
5. **Setup Home tab**: Click "Following" tab → Click "Sort by" → Click "Recent"
6. **Initial extract** from all 4 tabs in parallel
7. **Adaptive scroll loop** (run in parallel across tabs):
   - HIGH volume (Intelligence): 3-4 rounds of 15-20 J-keys, extract after each
   - MEDIUM volume (AI, Following): 2 rounds of 10-15 J-keys, extract after each
   - LOW volume (MLX): 1 round of 8 J-keys, extract once
   - **Stop condition**: When oldest tweet in view shows "1h" or older
8. **Compile and deduplicate** all results, prioritizing recency

### Extraction JavaScript (copy-safe, single line)
```javascript
var tweets = document.querySelectorAll("article"); var results = []; for (var i = 0; i < tweets.length; i++) { var t = tweets[i]; var time = t.querySelector("time"); var text = t.querySelector("[data-testid='tweetText']"); if (time && text) results.push({ time: time.innerText, text: text.innerText.substring(0, 300) }); } results
```

## Output Format

```markdown
## Top News Stories (Last Hour)

**1. [Topic]**
- [Summary] (Xm ago)

**2. [Topic]**
- [Summary] (Xm ago)

... (12 total unique stories)
```

## Rules
- Focus on posts within last hour (time shows "Xm" or "1h")
- De-duplicate across all sources
- Mix categories: geopolitics, tech, AI, finance, breaking news
- Use J key navigation (not scroll) for lazy-load triggering
- Home tab MUST use Following + Recent sort (chronological, not algorithmic)
- Target runtime: 10-15 seconds with parallel execution
