---
description: Breaking news monitor - loops every 5 min, alerts on Bloomberg-red-banner-level events only
allowed-tools: mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__javascript_tool, mcp__claude-in-chrome__find, Read, Write, Bash
---

# Situation Monitor

Real-time breaking news monitor. Loops every 5 minutes, alerts ONLY on Bloomberg-red-banner-level events.

## Source

| Source | URL |
|--------|-----|
| Intelligence | https://x.com/i/lists/1495874616409014273 |

## Breaking News Criteria (Bloomberg Red Banner Level)

**ONLY trigger for these event types:**
- Major military action / armed conflict escalation (war declaration, invasion, strike on ally)
- Head of state death, assassination, or removal from power
- Major terrorist attack (mass casualty)
- Nuclear/WMD incident
- Financial system crisis (major bank collapse, currency failure, market halt)
- Natural disaster with mass casualties (100+)
- Critical infrastructure attack (power grid down, etc.)
- Coup or government collapse

**NOT breaking (ignore these):** Policy announcements, protests, routine military movements, sports, weather, arrests, investigations, political speeches, tariffs, sanctions

## Break Tracking

Track seen breaks in `/tmp/situation-breaks.json` to avoid duplicate alerts.

Before alerting, check if story already exists (semantic match, not exact text).

## Execution Loop

```
LOOP:
  1. tabs_context_mcp (createIfEmpty: true)
  2. Navigate to Intelligence feed (or reuse existing tab)
  3. Wait 1s for load
  4. Extract initial tweets
  5. Scroll with J-key (10-15 presses) to load more content
  6. Extract again after scroll
  7. Filter for posts < 30m old
  8. Analyze against breaking criteria
  9. Check against /tmp/situation-breaks.json
  10. IF new break: Alert user, append to breaks file
  11. Output top 3 stories summary
  12. Wait 5 minutes
  13. GOTO LOOP
```

### Extraction JavaScript
```javascript
var tweets = document.querySelectorAll("article"); var results = []; for (var i = 0; i < tweets.length; i++) { var t = tweets[i]; var time = t.querySelector("time"); var text = t.querySelector("[data-testid='tweetText']"); if (time && text) results.push({ time: time.innerText, text: text.innerText.substring(0, 300) }); } results
```

## Output Formats

### Standard Output (every 5 min):
```
[MONITOR] 21:45

Top 3:
1. [Topic] - [Summary] (Xm ago)
2. [Topic] - [Summary] (Xm ago)
3. [Topic] - [Summary] (Xm ago)

Next check in 5 min.
```

### BREAKING Alert (prepended when detected):
```
🚨 BREAKING 🚨
[CATEGORY]: [Headline summary]
Source: Intelligence feed ({Xm} ago)
---

[Then standard output follows]
```

## Break History File Format (`/tmp/situation-breaks.json`)

```json
{
  "breaks": [
    {
      "headline": "Short description",
      "detected_at": "2026-01-18T21:45:00Z",
      "category": "military|political|terror|financial|disaster|infrastructure"
    }
  ]
}
```

Initialize file if missing:
```json
{"breaks": []}
```

## Rules

1. **HIGH BAR**: When in doubt, DON'T alert. False positives erode trust.
2. Posts older than 30m are stale - not "breaking"
3. Single unverified source = lower confidence, still alert if criteria met
4. De-duplicate against history (semantic similarity)
5. Loop continuously until user sends `/stop` or Ctrl+C
6. Reuse browser tab between checks - don't create new tabs each cycle
