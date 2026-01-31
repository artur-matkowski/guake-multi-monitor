#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/guake-monitor.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/guake-monitor.sh"

echo "Installed to $INSTALL_DIR/guake-monitor.sh"
echo ""

# Offer to install system files for automatic cache invalidation
echo "Optional: Install udev rule and systemd service for automatic"
echo "cache invalidation on monitor hotplug (requires sudo)."
echo ""
read -p "Install system files? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing udev rule and systemd service..."

    sudo cp "$SCRIPT_DIR/85-guake-monitor-hotplug.rules" /etc/udev/rules.d/
    sudo cp "$SCRIPT_DIR/guake-monitor-hotplug.service" /etc/systemd/system/

    sudo udevadm control --reload-rules
    sudo systemctl daemon-reload

    echo "System files installed successfully."
    echo ""
fi

echo "Next steps:"
echo "  1. Edit $INSTALL_DIR/guake-monitor.sh to configure your monitors"
echo "  2. Run 'xrandr --listmonitors' to find output names"
echo "  3. Disable Guake's built-in shortcut:"
echo "     gsettings set guake.keybindings.global show-hide ''"
echo "  4. Set up KDE shortcuts (run script without args for instructions)"
