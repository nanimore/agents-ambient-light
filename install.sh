#!/bin/bash
# Quick Installation Script for macOS/Linux
# Run: chmod +x install.sh && ./install.sh

echo "Installing Agents Ambient Light for Claude Code..."

# Check Python
if command -v python3 &> /dev/null; then
    echo "✓ Python found: $(python3 --version)"
else
    echo "✗ Python3 not found. Please install Python 3.7+ first."
    exit 1
fi

# Install PyQt5
echo ""
echo "Installing PyQt5..."
pip3 install PyQt5

# Copy files
TARGET_DIR="$HOME/.claude"
mkdir -p "$TARGET_DIR"

echo ""
echo "Copying files to $TARGET_DIR..."
cp ambient-light-qt.py "$TARGET_DIR/"
cp ambient-light-config.yaml "$TARGET_DIR/"
cp notify.sh "$TARGET_DIR/"
chmod +x "$TARGET_DIR/notify.sh"

echo "✓ Files copied successfully"

# Test
echo ""
echo "Testing ambient light (3 seconds)..."
python3 "$TARGET_DIR/ambient-light-qt.py" --color green --duration 3 --style border --animation breathe

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.claude/settings.json to add hooks (see README.md)"
echo "2. Customize colors/settings in ~/.claude/ambient-light-config.yaml"
echo "3. Restart Claude Code"
