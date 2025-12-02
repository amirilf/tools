#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Secure TOTP Authenticator..."

# Try system packages first
if ! python3 -c "import cryptography" 2>/dev/null; then
    echo "Installing cryptography..."
    pip3 install --user --break-system-packages cryptography 2>/dev/null || sudo apt install -y python3-cryptography
fi

if ! python3 -c "import pyotp" 2>/dev/null; then
    echo "Installing pyotp..."
    pip3 install --user --break-system-packages pyotp 2>/dev/null || {
        echo "Note: pyotp not in apt, installing with pip..."
        pip3 install --user --break-system-packages pyotp
    }
fi

chmod +x "$DIR/ath"
mkdir -p ~/.local/bin
ln -sf "$DIR/ath" ~/.local/bin/ath

echo ""
echo "✓ Installed!"
echo ""
echo "Usage:"
echo "  ath init              # Initialize"
echo "  ath add               # Add code"
echo "  ath                   # Show codes"
echo "  ath server            # Start server for extension"
echo ""
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Add to ~/.bashrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
    echo ""
fi

