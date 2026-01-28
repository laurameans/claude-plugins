#!/bin/bash
#
# MeansAI JWS Ecosystem Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/MeansAI/claude-plugins/main/install.sh | bash
#

set -e

echo "=== MeansAI JWS Ecosystem Installer ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
JMLLC_DIR="$HOME/Documents/JMLLC"
JWS_DIR="$JMLLC_DIR/JWS"
CLAUDE_DIR="$HOME/.claude"

# Create directories
echo "Creating directories..."
mkdir -p "$JWS_DIR"
mkdir -p "$JMLLC_DIR/Skills/JWS"
mkdir -p "$CLAUDE_DIR/commands"

# Clone or update repositories
clone_or_pull() {
    local repo=$1
    local dir=$2
    local name=$3

    if [ -d "$dir" ]; then
        echo -e "${YELLOW}Updating${NC} $name..."
        (cd "$dir" && git pull --quiet)
    else
        echo -e "${GREEN}Cloning${NC} $name..."
        git clone --quiet "https://github.com/MeansAI/$repo.git" "$dir"
    fi
}

# Clone JWS packages
echo ""
echo "=== Cloning JWS Swift Packages ==="
clone_or_pull "JWS" "$JWS_DIR/JWS" "JWS (Server)"
clone_or_pull "JCS" "$JWS_DIR/JCS" "JCS (Client)"
clone_or_pull "JBS" "$JWS_DIR/JBS" "JBS (Bridge)"
clone_or_pull "Transmission" "$JWS_DIR/Transmission" "Transmission"

# Clone supporting packages
clone_or_pull "JUI" "$JMLLC_DIR/JUI" "JUI (UI Components)"
clone_or_pull "JCX" "$JMLLC_DIR/JCX" "JCX (Extensions)"

# Clone StarterApp template
clone_or_pull "StarterApp" "$JMLLC_DIR/StarterApp" "StarterApp (Template)"

# Clone Claude plugins
echo ""
echo "=== Installing Claude Code Skills ==="
clone_or_pull "claude-plugins" "$JMLLC_DIR/claude-plugins" "Claude Plugins"

# Symlink skills to Claude commands directory
echo "Linking skills..."
for skill in new-app jws-style jws-page x-news x-monitor manim; do
    src="$JMLLC_DIR/claude-plugins/skills/$skill/SKILL.md"
    dst="$CLAUDE_DIR/commands/$skill.md"
    if [ -f "$src" ]; then
        ln -sf "$src" "$dst"
        echo "  ✓ /$skill"
    fi
done

# Copy support scripts
echo "Copying support scripts..."
cp "$JMLLC_DIR/claude-plugins/scripts/"*.swift "$JMLLC_DIR/Skills/JWS/" 2>/dev/null || true

# Create Claude settings if not exists
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "Creating Claude settings..."
    cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(swift:*)",
      "Bash(swift build:*)",
      "Bash(swift test:*)",
      "Bash(xcodebuild:*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(curl:*)",
      "Bash(mkdir:*)",
      "Bash(cp:*)",
      "Bash(open:*)"
    ]
  }
}
SETTINGS
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed to: $JMLLC_DIR"
echo ""
echo "Available slash commands:"
echo "  /new-app      - Create full-stack JCS/JWS applications"
echo "  /jws-style    - Edit website CSS with browser verification"
echo "  /jws-page     - Manage website page content"
echo "  /x-news       - Aggregate news from X feeds"
echo "  /x-monitor    - Breaking news alerts"
echo "  /manim        - Create animated explainer videos"
echo ""
echo "Swift packages available at: $JWS_DIR"
echo ""
echo -e "${GREEN}Ready to use!${NC} Restart Claude Code to load new skills."
