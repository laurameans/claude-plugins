---
description: Rapid stylesheet iteration for JWS websites with automatic cache purging
argument-hint: <hostname> <instructions>
allowed-tools: Bash, Read, Write, WebFetch, Grep, Glob, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer, mcp__claude-in-chrome__read_page
---

# JWS Stylesheet Manager

**Target:** $ARGUMENTS

## Execution Flow

Parse arguments: First word = hostname, rest = CSS change request.

### Phase 1: Get Current State

```bash
swift scripts/website-api.swift get-css <hostname> > /tmp/jws-style-current.css
```

Read `/tmp/jws-style-current.css` to understand existing styles.

### Phase 2: Make Minimal Changes

- Do NOT rewrite the entire stylesheet
- Make targeted, minimal edits only
- Preserve all existing styles unless explicitly asked to change
- Use Fibonacci values for all sizing/spacing/opacity (see below)

Write updated CSS to `/tmp/jws-style-current.css`

### Phase 3: Push Update

```bash
swift scripts/website-api.swift put-css-file <hostname> /tmp/jws-style-current.css
```

### Phase 4: Browser Verification Loop

**4a. Open site in browser**
```
mcp__claude-in-chrome__tabs_context_mcp (createIfEmpty: true)
mcp__claude-in-chrome__tabs_create_mcp
mcp__claude-in-chrome__navigate to https://<hostname>
mcp__claude-in-chrome__computer action: wait, duration: 2
```

**4b. Take screenshot**
```
mcp__claude-in-chrome__computer action: screenshot
```

**4c. Analyze screenshot**
Visually verify the CSS change was applied correctly:
- Does the requested change appear?
- Are there any obvious visual issues?
- Did the change break anything else?

**4d. Self-correction loop**
If the change is NOT visible or looks wrong:
1. Analyze what went wrong
2. Adjust the CSS in `/tmp/jws-style-current.css`
3. Re-push with `put-css-file`
4. Wait 2 seconds for cache purge
5. Hard refresh: `mcp__claude-in-chrome__computer action: key, text: "cmd+shift+r"`
6. Take new screenshot
7. Repeat until correct (max 3 iterations)

### Phase 5: Report to User

Only after verification succeeds:
- Show the screenshot
- Summarize what was changed
- Confirm the site URL

---

## Architecture Reference

**CSS Composition Order:**
1. `defaultCSS` - Base styles, variables, typography, **microdot grid shimmer**
2. `stylesheetContent` - **YOUR CUSTOM CSS** ← what we edit (color overrides, etc.)
3. `liquidGlassCSS` - Apple glass design

**Default Features (no custom CSS needed):**
- Microdot grid with shimmer wipe animation (24px grid, 0.09 opacity, 24s duration)
- Light/dark mode support
- Responsive typography
- Liquid glass effects

## Servers

| Server | Sites |
|--------|-------|
| Means | means.ai, outtakes.com, flow.outtakes.com, dave.means.ai |
| Mainframe | jws.ai |
| Voosey | voosey.com, dajh.com, sixpacmanco.com |

## Fibonacci Values (ALWAYS use these)

```
Whole values (for px):     Decimal values (for opacity):
xxxSmall = 2px             0.02
xxSmall  = 3px             0.03
xSmall   = 6px             0.06
small    = 9px             0.09
medium   = 15px            0.15
large    = 24px            0.24
xLarge   = 39px            0.39
xxLarge  = 63px            0.63
xxxLarge = 102px           1.02
```

## CSS Variables (defaults you can override)

```css
:root {
  --primary-background-dark: linear-gradient(#000000, #1F2429);
  --primary-background-light: linear-gradient(#ffffff, #e9e9e9);
  --text-color-dark: #f5f5f7;
  --text-color-light: #282a2c;
  --link-color: #82D6FF;
  --link-color-hover-dark: #82D6FF;
  --link-color-hover-light: #00B0FF;
}
```

## Example Invocations

```
/jws-style means.ai change accent color to desert orange
/jws-style outtakes.com make h1 larger with gradient
/jws-style voosey.com add subtle shadow to cards
```
