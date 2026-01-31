#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/guake-monitor.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/guake-monitor.sh"

echo "Installed to $INSTALL_DIR/guake-monitor.sh"
echo ""
echo "Next steps:"
echo "  1. Edit $INSTALL_DIR/guake-monitor.sh to configure your monitors"
echo "  2. Run 'xrandr --listmonitors' to find output names"
echo "  3. Disable Guake's built-in shortcut:"
echo "     gsettings set guake.keybindings.global show-hide ''"
echo "  4. Set up KDE shortcuts (run script without args for instructions)"
