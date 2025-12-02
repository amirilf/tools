#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Proxy Manager..."

chmod +x "$DIR/px"
mkdir -p ~/.local/bin
ln -sf "$DIR/px" ~/.local/bin/px

echo ""
echo "✓ Installed!"
echo ""
echo "Usage:"
echo "  px                    # Show status"
echo "  px work               # Switch to profile"
echo "  px off                # Disable proxy"
echo "  px list               # List profiles"
echo "  px add work -H proxy:8080 -S proxy:8080"
echo ""
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Add to ~/.bashrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
fi

