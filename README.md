# Guake Multi-Monitor Controller

Toggle Guake terminal on specific monitors using stable output names (not indices that change with KVM switching).

## Features

- **Show** Guake on a specific monitor when hidden
- **Hide** Guake when pressing the same monitor's shortcut
- **Move** Guake to a different monitor when pressing another shortcut (stays visible)

## Requirements

- Guake terminal
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

1. Disable Guake's built-in toggle:
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

## License

MIT
