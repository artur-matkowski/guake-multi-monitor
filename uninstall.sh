#!/bin/bash

INSTALL_DIR="$HOME/.local/bin"
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/guake-monitor"

echo "Uninstalling guake-monitor..."

# Remove user script
if [ -f "$INSTALL_DIR/guake-monitor.sh" ]; then
    rm "$INSTALL_DIR/guake-monitor.sh"
    echo "Removed $INSTALL_DIR/guake-monitor.sh"
fi

# Remove cache
if [ -d "$CACHE_DIR" ]; then
    rm -rf "$CACHE_DIR"
    echo "Removed cache directory $CACHE_DIR"
fi

# Check for system files
UDEV_RULE="/etc/udev/rules.d/85-guake-monitor-hotplug.rules"
SYSTEMD_SERVICE="/etc/systemd/system/guake-monitor-hotplug.service"

if [ -f "$UDEV_RULE" ] || [ -f "$SYSTEMD_SERVICE" ]; then
    echo ""
    read -p "Remove udev rule and systemd service? (requires sudo) [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        [ -f "$UDEV_RULE" ] && sudo rm "$UDEV_RULE" && echo "Removed $UDEV_RULE"
        [ -f "$SYSTEMD_SERVICE" ] && sudo rm "$SYSTEMD_SERVICE" && echo "Removed $SYSTEMD_SERVICE"
        sudo udevadm control --reload-rules
        sudo systemctl daemon-reload
        echo "System files removed."
    fi
fi

echo ""
echo "Uninstall complete."
