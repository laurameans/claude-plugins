---
description: Create 3Blue1Brown-style mathematical animations with Manim - from concept to complete video
argument-hint: <topic or concept to visualize>
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch, Task
---

# Manim Video Composer

**Input:** $ARGUMENTS

Transform any concept into a polished, 3Blue1Brown-style animated explainer video. This skill handles the entire pipeline: research, planning, scripting, coding, and rendering.

---

## CRITICAL: Style & Asset Rules

### USE ACTUAL LOGO FILES - NEVER APPROXIMATE

When using Means/JWS branding, ALWAYS download and use the actual PNG/image files:

```python
# CORRECT: Use ImageMobject with actual logo files
from manim import *

# Download logos first (run in bash):
# curl -o assets/MeansSig.png "https://c.jws.ai/MeansSigBlack.png"
# curl -o assets/JWSWhite.png "https://c.jws.ai/JWS%20Icon%20Only%20White.png"

# Then use ImageMobject:
means_logo = ImageMobject("assets/MeansSig.png").scale(0.5)
jws_logo = ImageMobject("assets/JWSWhite.png").scale(0.3)
self.play(FadeIn(means_logo))

# WRONG: Never try to recreate logos with SVG paths or Text approximations
# sig = Text("Means", font="Brush Script MT")  # NO! Use the actual image!
```

### Official Logo URLs (CDN)

| Logo | URL | Usage |
|------|-----|-------|
| Means Signature (Black) | `https://c.jws.ai/MeansSigBlack.png` | Dark backgrounds |
| Means Signature (White) | `https://c.jws.ai/MeansSigWhite.png` | Light backgrounds |
| JWS Icon (White) | `https://c.jws.ai/JWS%20Icon%20Only%20White.png` | Dark backgrounds |
| JWS Icon (Black) | `https://c.jws.ai/JWS%20Icon%20Only%20Black.png` | Light backgrounds |

### Fonts That Render Properly in Manim

```python
# SAFE FONTS - these render correctly:
FONT_BODY = "Helvetica Neue"      # Or "Arial" as fallback
FONT_CODE = "Menlo"               # Or "Courier New" as fallback
FONT_BOLD = "Helvetica Neue Bold"

# AVOID - may render incorrectly:
# "SF Pro Display" - system font, inconsistent
# "Brush Script MT" - cursive doesn't render well
# Custom/exotic fonts - use images instead
```

---

## Phase 0: Deep Research (REQUIRED for Means Projects)

**When visualizing Means/JWS products, ALWAYS spawn parallel Task agents to research:**

```
Launch these agents IN PARALLEL before writing any code:

1. Task(subagent_type="Explore"): Search codebase for [product] - architecture, features, code
2. Task(subagent_type="Explore"): Search JWS/JCS modules - technical capabilities
3. WebFetch: Scrape means.ai for latest project descriptions and visuals
4. WebFetch: Scrape product-specific sites (jws.ai, outtakes.com, voosey.com, etc.)
```

### Means Product Priority (when showcasing ecosystem)

**High Priority (feature prominently):**
1. **Mean-E** - Sovereign AI agent, LLM integration
2. **JWS** - Core platform, full-stack Swift
3. **Outtakes** - Creative AI, computer vision, generative
4. **Voosey** - Spatial computing, visionOS, architecture
5. **Neuraform** - Brainwave entrainment, audio processing

**Medium Priority:**
6. **Neurafund** - Finance AI, investment intelligence
7. **RevoluSun** - Solar CRM, renewable energy

**Lower Priority:**
8. **GHF** - Global Housing Foundation
9. **Untold Culture** - Digital wellness

### Supported Platforms (INCLUDE WEB!)

```
iOS • iPadOS • macOS • visionOS • Web • Linux • Embedded • tvOS
```

**Web is a first-class platform** - JWS powers means.ai, jws.ai, outtakes.com, voosey.com

---

## Phase 1: Research & Understand

Before asking questions, deeply research the topic:

1. **Spawn parallel agents** to search codebase and web
2. **Identify the "aha moment"** - what makes this click for learners
3. **Find the narrative hook** - why should viewers care?
4. **Collect actual assets** - logos, screenshots, product images

---

## Phase 2: Quick Clarification

Ask only essential questions (adapt based on the topic):

- **Audience**: What background to assume? (high school, undergrad, professional)
- **Length**: Short (2-5 min), medium (5-10 min), or long (10+ min)?
- **Focus**: Intuition-first or proof-heavy? Real-world applications?

---

## Phase 3: Create Scene Plan

Write a `scenes.md` file with this structure:

```markdown
# [Video Title]

## Overview
- **Topic**: [Core concept]
- **Hook**: [Opening question/mystery]
- **Target Audience**: [Prerequisites]
- **Key Insight**: [The "aha moment"]

## Narrative Arc
[Journey from confusion to understanding]

---

## Scene 1: [Name]
**Duration**: ~X seconds
**Purpose**: [What this accomplishes]

### Visual Elements
- [Mobjects, animations, camera moves]
- [ACTUAL logo files to use - with URLs]

### Content
[What happens, what's shown]

### Narration Notes
[Key points, tone, pacing]

---
[Repeat for each scene]
```

---

## Phase 4: Implement with Manim

### Project Setup

```bash
# Check if manim is installed
which manim || pip install manim

# Create project with assets directory
PROJECT="~/manim_projects/[project_name]"
mkdir -p "$PROJECT/assets"
cd "$PROJECT"

# Download Means brand assets
curl -so assets/MeansSig.png "https://c.jws.ai/MeansSigBlack.png"
curl -so assets/JWSWhite.png "https://c.jws.ai/JWS%20Icon%20Only%20White.png"
curl -so assets/JWSBlack.png "https://c.jws.ai/JWS%20Icon%20Only%20Black.png"
```

### Means Brand Colors (from means.ai CSS)

```python
# === MEANS.AI BRAND COLORS (extracted from live CSS) ===

# Primary backgrounds
MEANS_BLACK = "#000000"
MEANS_DARK = "#1F2429"
# Background is: linear-gradient(#000000, #1F2429)

# Text colors
MEANS_TEXT_DARK = "#f5f5f7"   # Light text on dark bg
MEANS_TEXT_LIGHT = "#282a2c"  # Dark text on light bg

# Accent colors
MEANS_CYAN = "#82D6FF"        # Primary accent / links
MEANS_BLUE = "#007AFF"        # Apple blue
MEANS_GREEN = "#34C759"       # Success / server
MEANS_RED = "#FF3B30"         # Error / warning
MEANS_ORANGE = "#FF9500"      # Web / highlight

# Glass effects
MEANS_GLASS_BG = "#1F242999"           # 60% opacity dark
MEANS_GLASS_BORDER = "#FFFFFF1A"       # 10% white border
MEANS_HEADER_BG = "#000000AD"          # 68% opacity black

# Chromatic aberration hints (use sparingly)
CHROMATIC_BLUE = "#007AFF1A"   # 10% blue
CHROMATIC_RED = "#FF3B301A"    # 10% red
CHROMATIC_GREEN = "#34C7591A"  # 10% green
```

### Fibonacci Timing & Spacing

```python
# Timing (seconds) - use for run_time and wait()
FIB_XS = 0.24
FIB_S = 0.39
FIB_M = 0.63
FIB_L = 1.02
FIB_XL = 1.65

# Spacing (Manim units) - use for positioning
FIB_SPACE_XS = 0.06
FIB_SPACE_S = 0.09
FIB_SPACE_M = 0.15
FIB_SPACE_L = 0.24
FIB_SPACE_XL = 0.39
```

### Base Scene Template

```python
from manim import *
import numpy as np
import os

# === MEANS BRAND ===
MEANS_BLACK = "#000000"
MEANS_DARK = "#1F2429"
MEANS_TEXT = "#f5f5f7"
MEANS_CYAN = "#82D6FF"
MEANS_BLUE = "#007AFF"
MEANS_GREEN = "#34C759"
MEANS_RED = "#FF3B30"
MEANS_ORANGE = "#FF9500"

# Fibonacci timing
FIB_S, FIB_M, FIB_L = 0.39, 0.63, 1.02

# Safe fonts
FONT_BODY = "Helvetica Neue"
FONT_CODE = "Menlo"

# Asset path
ASSETS = os.path.join(os.path.dirname(__file__), "assets")


def create_microdot_grid(spacing=0.24, opacity=0.09):
    """Exact means.ai microdot grid: 24px spacing, 0.09 opacity white dots"""
    dots = VGroup()
    for x in np.arange(-8, 8.5, spacing):
        for y in np.arange(-5, 5.5, spacing):
            dot = Dot(point=[x, y, 0], radius=0.012, color=WHITE)
            dot.set_opacity(opacity)
            dots.add(dot)
    return dots


def create_glass_panel(width, height, color=MEANS_CYAN):
    """Glassmorphism panel matching means.ai aesthetic"""
    return RoundedRectangle(
        corner_radius=0.15,
        width=width, height=height,
        fill_color=MEANS_DARK, fill_opacity=0.7,
        stroke_color=color, stroke_width=2
    )


class MeansScene(Scene):
    """Base scene with Means styling"""

    def setup(self):
        self.camera.background_color = MEANS_BLACK
        self.grid = create_microdot_grid()
        self.add(self.grid)

    def load_logo(self, name, scale=0.5):
        """Load a logo from assets directory"""
        path = os.path.join(ASSETS, name)
        if os.path.exists(path):
            return ImageMobject(path).scale(scale)
        return None

    def construct(self):
        # Override in subclass
        pass
```

---

## Phase 5: Render

```bash
# Preview (low quality, fast)
manim -pql scene.py SceneName

# Medium quality (720p30)
manim -qm scene.py SceneName

# High quality (1080p60)
manim -pqh scene.py SceneName

# 4K
manim -pqk scene.py SceneName

# GIF output
manim -qm --format gif scene.py SceneName

# Combine multiple scenes with ffmpeg
cd media/videos/*/720p30/
cat > files.txt << EOF
file 'Scene01.mp4'
file 'Scene02.mp4'
file 'Scene03.mp4'
EOF
ffmpeg -f concat -safe 0 -i files.txt -c copy ../Combined.mp4
```

---

## 3b1b Style Principles

### Visual Storytelling
- **Show, don't tell** - every concept needs a visual
- **Progressive revelation** - build complexity gradually
- **Visual continuity** - transform objects, don't replace
- **Use actual assets** - real logos, screenshots, not approximations

### Pacing (Fibonacci-based)
- **Quick actions**: 0.39s (FIB_S)
- **Standard animations**: 0.63s (FIB_M)
- **Dramatic reveals**: 1.02s (FIB_L)
- **Pause for insight**: wait(FIB_M) to let moments breathe

### Engagement
- **Pose questions** - make viewers curious first
- **Acknowledge difficulty** - "This might seem confusing..."
- **Celebrate insight** - make "aha" moments feel earned

---

## Quick Reference

| Means Colors | Hex | Usage |
|--------------|-----|-------|
| Background | `#000000` → `#1F2429` | Gradient |
| Text | `#f5f5f7` | Primary text |
| Cyan | `#82D6FF` | Primary accent |
| Blue | `#007AFF` | Apple blue |
| Green | `#34C759` | Success/server |
| Red | `#FF3B30` | Error/warning |
| Orange | `#FF9500` | Web/highlight |

| Logo | CDN URL |
|------|---------|
| Means (black) | `https://c.jws.ai/MeansSigBlack.png` |
| JWS (white) | `https://c.jws.ai/JWS%20Icon%20Only%20White.png` |

| Safe Fonts | Usage |
|------------|-------|
| Helvetica Neue | Body text |
| Menlo | Code/monospace |

| Render | Command |
|--------|---------|
| Preview | `manim -pql file.py Scene` |
| Medium | `manim -qm file.py Scene` |
| High | `manim -pqh file.py Scene` |
| 4K | `manim -pqk file.py Scene` |
