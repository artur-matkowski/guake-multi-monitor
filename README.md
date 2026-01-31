# Guake Multi-Monitor Controller

Toggle Guake terminal on specific monitors using stable output names (not indices that change with KVM switching).

## Features

- **Show** Guake on a specific monitor when hidden
- **Hide** Guake when pressing the same monitor's shortcut
- **Move** Guake to a different monitor when pressing another shortcut (stays visible)

## Requirements

- Guake 3.x (uses org.guake3 D-Bus interface)
- xrandr
- gsettings (GNOME/GTK)
- notify-send (optional, for notifications)

## Installation

```bash
./install.sh
```

Or manually:

```bash
cp guake-monitor.sh ~/.local/bin/
chmod +x ~/.local/bin/guake-monitor.sh
```

To uninstall:

```bash
./uninstall.sh
```

### Optional: Automatic Cache Invalidation on Monitor Changes

If you frequently plug/unplug monitors, install the udev rule and systemd service to automatically clear the cache:

```bash
sudo cp 85-guake-monitor-hotplug.rules /etc/udev/rules.d/
sudo cp guake-monitor-hotplug.service /etc/systemd/system/
sudo udevadm control --reload-rules
sudo systemctl daemon-reload
```

## Configuration

Edit `~/.local/bin/guake-monitor.sh` and modify the slot variables at the top:

```bash
SLOT_1="DP-0"       # F8 - Primary monitor
SLOT_2="DP-2"       # F9 - Secondary monitor
SLOT_3="HDMI-0"     # F10 - Third monitor
SLOT_4="HDMI-1"     # F11 - Fourth monitor
```

Use `xrandr --listmonitors` to find your output names.

To disable a slot, set it to empty:

```bash
SLOT_3=""
SLOT_4=""
```

## Usage

```bash
guake-monitor.sh <SLOT_NUMBER>
```

Run without arguments to see help and KDE shortcut setup instructions.

## KDE Plasma Shortcut Setup

1. **Important**: Disable Guake's built-in F12 toggle first (otherwise it conflicts):
   ```bash
   gsettings set guake.keybindings.global show-hide ''
   ```

2. Open **System Settings** > **Shortcuts** > **Custom Shortcuts**

3. Right-click > **New** > **Global Shortcut** > **Command/URL**

4. Create shortcuts:

   | Key | Command |
   |-----|---------|
   | F8  | `~/.local/bin/guake-monitor.sh 1` |
   | F9  | `~/.local/bin/guake-monitor.sh 2` |
   | F10 | `~/.local/bin/guake-monitor.sh 3` |
   | F11 | `~/.local/bin/guake-monitor.sh 4` |

## How It Works

### Performance Caching

The script caches the mapping between slot numbers and monitor indices to avoid calling `xrandr` on every invocation. The cache is stored in an XDG-compliant location:

```
${XDG_RUNTIME_DIR}/guake-monitor/slot-N.idx
```

The cache is automatically invalidated when:
- You install the optional udev rule (monitors plugged/unplugged)
- You manually delete the cache directory
- The system reboots (XDG_RUNTIME_DIR is tmpfs)

### D-Bus Communication

Instead of calling `guake --is-visible` (which spawns a Python process), the script communicates directly with Guake via D-Bus using `gdbus`. This provides faster response times for keyboard shortcuts.

## Troubleshooting

**Monitor not found after changing display configuration:**

Clear the cache manually:
```bash
rm -rf "${XDG_RUNTIME_DIR}/guake-monitor"
```

**Guake doesn't respond:**

Ensure Guake 3.x is running and the D-Bus service is available:
```bash
gdbus introspect --session --dest org.guake3.RemoteControl --object-path /org/guake3/RemoteControl
```

**Keyboard shortcut doesn't work:**

Make sure you disabled Guake's built-in shortcut (step 1 in setup).

## License

MIT
