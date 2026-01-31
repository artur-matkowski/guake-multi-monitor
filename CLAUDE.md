# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A bash utility that enables per-monitor toggle control of Guake terminal on Linux multi-monitor setups. Solves the problem of xrandr monitor indices changing when switching KVM inputs by using stable output names (DP-0, HDMI-0, etc.) instead.

## Architecture

**guake-monitor.sh**: Main script with two sections:
- Configuration block (top): SLOT_1 through SLOT_4 variables mapping slot numbers to xrandr output names
- Script logic (bottom): Translates output names to runtime monitor indices, then controls Guake visibility

**install.sh**: Copies script to `~/.local/bin/` with execute permissions.

## Key Logic Flow

1. Slot number → output name lookup (SLOT_N variables)
2. Output name → monitor index via `xrandr --listmonitors`
3. Guake state check via `guake --is-visible`
4. Current monitor via `gsettings get guake.general display-n`
5. Action: show, hide, or move based on current state

## Dependencies

- guake (terminal)
- xrandr (monitor detection)
- gsettings (GNOME/GTK settings)
- notify-send (optional notifications)

## Testing

Run directly with slot number argument:
```bash
./guake-monitor.sh 1
```

Run without arguments to see usage and current slot configuration.
