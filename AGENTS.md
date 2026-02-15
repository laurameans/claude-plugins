# MeansAI Claude Plugins - Agent Directives

## Deploying Skill Updates

When updating any skill in this repo, follow this process:

### 1. Update the Skill File

Edit the skill's `SKILL.md` file in `skills/<skill-name>/SKILL.md`

### 2. Update Related Templates (if applicable)

If the skill uses a template repo (e.g., `/new-app` uses StarterApp):

```bash
cd /Users/justinmeans/Documents/JMLLC/StarterApp
# Make changes
git add <files>
git commit -m "Description

Co-Authored-By: Mean-E <mean-e@users.noreply.github.com>"
git push origin main
```

### 3. Commit and Push to claude-plugins

```bash
cd /tmp/claude-plugins  # or wherever cloned
git add skills/<skill-name>/SKILL.md
git commit -m "Update <skill-name> skill - <description>

Co-Authored-By: Mean-E <mean-e@users.noreply.github.com>"
git push origin main
```

### 4. Sync Local Skills Directory

```bash
cp /tmp/claude-plugins/skills/<skill-name>/SKILL.md /Users/justinmeans/Documents/JMLLC/Skills/<skill-name>.md
```

## Quick Deploy Command

For simple skill updates, use this one-liner:

```bash
SKILL="new-app" && \
cd /tmp && rm -rf claude-plugins && \
git clone https://github.com/MeansAI/claude-plugins.git && \
cp /Users/justinmeans/Documents/JMLLC/Skills/${SKILL}.md /tmp/claude-plugins/skills/${SKILL}/SKILL.md && \
cd /tmp/claude-plugins && \
git add skills/${SKILL}/SKILL.md && \
git commit -m "Update ${SKILL} skill

Co-Authored-By: Mean-E <mean-e@users.noreply.github.com>" && \
git push origin main
```

## How Users Receive Updates

Users update their plugins with:

```bash
/plugin update means-tools@means-marketplace
```

Or update all plugins:

```bash
/plugin update
```

## Repository Structure

```
claude-plugins/
├── .claude/
│   └── settings.json      # Permissions for the plugin
├── .claude-plugin/
│   └── manifest.json      # Plugin metadata
├── skills/
│   ├── new-app/
│   │   └── SKILL.md       # /new-app skill definition
│   ├── jws-style/
│   │   └── SKILL.md
│   ├── jws-page/
│   │   └── SKILL.md
│   ├── manim/
│   │   └── SKILL.md
│   ├── x-news/
│   │   └── SKILL.md
│   ├── x-monitor/
│   │   └── SKILL.md
│   ├── blog-post/
│   │   └── SKILL.md
│   ├── outfit-post/
│   │   └── SKILL.md
│   ├── new-site/
│   │   └── SKILL.md
│   ├── slop-outfit/
│   │   └── SKILL.md
│   └── post/
│       └── SKILL.md
├── scripts/               # Helper scripts for skills
├── README.md
└── AGENTS.md              # This file
```

## Related Repositories

| Repo | Purpose | URL |
|------|---------|-----|
| StarterApp | Template for /new-app | https://github.com/MeansAI/StarterApp |
| JWS | Server framework | https://github.com/MeansAI/jws |

## Critical Patterns for JCS Apps

All skills that generate JCS apps MUST use these constants:

```swift
let topBarHeight: CGFloat = 52
let bottomBarHeight: CGFloat = 100
```

And apply BOTH paddings in ScrollView content:

```swift
ScrollView {
    VStack { ... }
    .padding()
    .padding(.top, topBarHeight)
    .padding(.bottom, bottomBarHeight)
}
```

NEVER use `Fibonacci.large.wholeValue` for bar heights - it's 34pt, not the correct 52pt.
