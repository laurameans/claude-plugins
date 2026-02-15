# MeansAI Claude Plugins

Official Claude Code plugins for the JWS/JCS full-stack Swift development ecosystem.

## Installation

### Quick Start

```bash
# Add the MeansAI marketplace
/plugin marketplace add MeansAI/claude-plugins

# Install the means-tools plugin
/plugin install means-tools@means-marketplace
```

### Project-Level Auto-Install

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "means-marketplace": {
      "source": {
        "source": "github",
        "repo": "MeansAI/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "means-tools@means-marketplace": true
  }
}
```

When team members clone the project and trust it, Claude Code will prompt them to install the configured plugins.

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **new-app** | `/new-app [name] [description]` | Create full-stack JCS/JWS applications from the StarterApp scaffold |
| **jws-style** | `/jws-style <host> <changes>` | Rapid CSS iteration for JWS websites with browser verification |
| **jws-page** | `/jws-page <host> <action> [args]` | Create, update, and manage webpage content on JWS sites |
| **x-news** | `/x-news` | Generate hourly news digest from curated X lists |
| **x-monitor** | `/x-monitor` | Breaking news monitor with Bloomberg-level alert thresholds |
| **manim** | `/manim <topic>` | Create 3Blue1Brown-style animated explainer videos |
| **blog-post** | `/blog-post <site> "<topic>"` | Create full blog post with photos and affiliate links |
| **outfit-post** | `/outfit-post "<description>" [urls...]` | Create outfit recommendation with blog post and social captions |
| **new-site** | `/new-site <slug> "<name>" "<tagline>" <domain>` | Add new site to the multi-site blog network |
| **slop-outfit** | `/slop-outfit "<description>"` | Create Laszlo-voice outfit post for Slop Fashion |
| **post** | `/post "<description>"` | Unified content creation for all sites (auto-routes by topic) |

## Requirements

### For JWS Development Skills (`/new-app`, `/jws-style`, `/jws-page`)

1. **Swift 6.2+** installed
2. **JWS Libraries** - Clone the JWS repository:
   ```bash
   git clone https://github.com/MeansAI/jws.git ~/Documents/JMLLC/JWS
   ```
3. **StarterApp Template** (for `/new-app`):
   ```bash
   git clone https://github.com/MeansAI/StarterApp.git ~/Documents/JMLLC/StarterApp
   ```

### For Browser-Based Skills (`/x-news`, `/x-monitor`, `/jws-style`, `/jws-page`)

1. **Claude in Chrome** extension installed
2. Logged into X (for news skills)
3. API access configured (for JWS skills)

### For Animation Skills (`/manim`)

1. **Manim** installed: `pip install manim`
2. **ffmpeg** for video concatenation

## JWS Platform Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR APPLICATION                          │
├─────────────────────────────────────────────────────────────────┤
│  JCX (Extensions)  │  JUI (UI Components)  │  JCS (Client)      │
├─────────────────────────────────────────────────────────────────┤
│                          JBS (Bridge/DTOs)                       │
├─────────────────────────────────────────────────────────────────┤
│                     JWS (Server Framework)                       │
└─────────────────────────────────────────────────────────────────┘
```

| Package | Purpose | Platform |
|---------|---------|----------|
| **JWS** | Vapor-based server framework | macOS (server) |
| **JCS** | Client services (auth, network, UI) | iOS, macOS, visionOS, tvOS, watchOS |
| **JBS** | Shared DTOs and business logic | All platforms |
| **JUI** | Reusable SwiftUI components | All Apple platforms |
| **JCX** | Swift macros and extensions | All platforms |
| **Transmission** | WebSocket distributed actors | All platforms |

## Configuration

### API Keys

For JWS website skills, you'll need API access. Contact your team lead for:
- `jws_master_key` for website management
- Server endpoints for your environment

### Scripts Location

The plugin includes helper scripts in `/scripts/`:
- `website-api.swift` - CSS and website management
- `webpage-api.swift` - Page CRUD operations
- `upload-media.swift` - Media upload to CDN

## Updates

The plugin updates automatically when you pull from the marketplace:

```bash
/plugin update means-tools@means-marketplace
```

Or update all plugins:

```bash
/plugin update
```

## Support

- **Issues**: https://github.com/MeansAI/claude-plugins/issues
- **Documentation**: https://docs.means.ai/claude-plugins

## License

MIT License - see LICENSE file for details.
