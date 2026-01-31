#!/bin/bash
#==============================================================================
# GUAKE MULTI-MONITOR CONTROLLER
#
# Usage: guake-monitor.sh <SLOT>
# Example: guake-monitor.sh 1
#
# Behavior:
#   - Guake hidden → show on target monitor
#   - Guake visible on SAME monitor → hide
#   - Guake visible on DIFFERENT monitor → move to target (stays visible)
#==============================================================================

#------------------------------------------------------------------------------
# CONFIGURATION - Edit these variables to customize behavior
#------------------------------------------------------------------------------

# Slot configuration: SLOT_<N>="<OUTPUT_NAME>"
#   OUTPUT_NAME: The xrandr output (DP-0, HDMI-0, etc.) - use 'xrandr' to list
#   Set to empty string "" to disable a slot

SLOT_1="DP-0"       # F8 - Primary monitor
SLOT_2="DP-2"       # F9 - Secondary monitor
SLOT_3="HDMI-0"     # F10 - Third monitor
SLOT_4="HDMI-1"     # F11 - Fourth monitor

# To disable a slot, set it to empty:
# SLOT_3=""
# SLOT_4=""

#------------------------------------------------------------------------------
# SCRIPT LOGIC - No need to edit below this line
#------------------------------------------------------------------------------

SLOT_NUM="$1"

if [ -z "$SLOT_NUM" ]; then
    echo "Usage: $0 <SLOT_NUMBER>"
    echo "Slots: 1, 2, 3, 4"
    echo ""
    echo "KDE Plasma Shortcut Setup:"
    echo "  1. Open System Settings > Shortcuts > Custom Shortcuts"
    echo "  2. Right-click > New > Global Shortcut > Command/URL"
    echo "  3. Set trigger (e.g., F8) and command: $0 1"
    echo "  4. Repeat for each slot/key combination"
    echo ""
    echo "Suggested mapping:"
    echo "  F8  -> $0 1  (${SLOT_1:-disabled})"
    echo "  F9  -> $0 2  (${SLOT_2:-disabled})"
    echo "  F10 -> $0 3  (${SLOT_3:-disabled})"
    echo "  F11 -> $0 4  (${SLOT_4:-disabled})"
    exit 1
fi

# Get slot config
SLOT_VAR="SLOT_$SLOT_NUM"
TARGET_OUTPUT="${!SLOT_VAR}"

if [ -z "$TARGET_OUTPUT" ]; then
    notify-send "Guake" "Slot $SLOT_NUM is disabled"
    exit 0
fi

# Get target monitor index for the given output name
TARGET_INDEX=$(xrandr --listmonitors | grep -w "$TARGET_OUTPUT" | awk '{print $1}' | tr -d ':')

if [ -z "$TARGET_INDEX" ]; then
    notify-send "Guake" "Monitor $TARGET_OUTPUT not found" --icon=dialog-warning
    exit 1
fi

# Check if Guake is currently visible (outputs 1=visible, 0=hidden)
IS_VISIBLE=$(guake --is-visible)

# Get current monitor index where Guake is displayed
CURRENT_INDEX=$(gsettings get guake.general display-n)

if [ "$IS_VISIBLE" -eq 1 ]; then
    # Guake is visible
    if [ "$CURRENT_INDEX" -eq "$TARGET_INDEX" ]; then
        # Same monitor - hide
        guake --hide
    else
        # Different monitor - move (hide, change setting, show)
        guake --hide
        gsettings set guake.general display-n "$TARGET_INDEX"
        guake --show
    fi
else
    # Guake is hidden - show on target monitor
    gsettings set guake.general display-n "$TARGET_INDEX"
    guake --show
fi
