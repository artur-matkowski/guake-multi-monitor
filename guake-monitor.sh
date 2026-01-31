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

#------------------------------------------------------------------------------
# Caching: store slot→index mapping to avoid xrandr call on every invocation
#------------------------------------------------------------------------------
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/guake-monitor"
CACHE_FILE="$CACHE_DIR/slot-${SLOT_NUM}.idx"

if [ -f "$CACHE_FILE" ]; then
    TARGET_INDEX=$(cat "$CACHE_FILE")
else
    TARGET_INDEX=$(xrandr --listmonitors | grep -w "$TARGET_OUTPUT" | awk '{print $1}' | tr -d ':')
    if [ -n "$TARGET_INDEX" ]; then
        mkdir -p "$CACHE_DIR"
        echo "$TARGET_INDEX" > "$CACHE_FILE"
    fi
fi

if [ -z "$TARGET_INDEX" ]; then
    notify-send "Guake" "Monitor $TARGET_OUTPUT not found" --icon=dialog-warning
    exit 1
fi

#------------------------------------------------------------------------------
# D-Bus helpers: direct calls to Guake avoid Python startup overhead
#------------------------------------------------------------------------------
GUAKE_DEST="org.guake3.RemoteControl"
GUAKE_PATH="/org/guake3/RemoteControl"
GUAKE_IFACE="org.guake3.RemoteControl"

guake_is_visible() {
    local result
    result=$(gdbus call --session --dest "$GUAKE_DEST" \
        --object-path "$GUAKE_PATH" \
        --method "${GUAKE_IFACE}.get_visibility" 2>/dev/null)
    # Returns "(1,)" for visible, "(0,)" for hidden
    [[ "$result" == *"(1,"* ]] && echo 1 || echo 0
}

guake_show() {
    gdbus call --session --dest "$GUAKE_DEST" \
        --object-path "$GUAKE_PATH" \
        --method "${GUAKE_IFACE}.show" >/dev/null 2>&1
}

guake_hide() {
    gdbus call --session --dest "$GUAKE_DEST" \
        --object-path "$GUAKE_PATH" \
        --method "${GUAKE_IFACE}.hide" >/dev/null 2>&1
}

#------------------------------------------------------------------------------
# Main logic
#------------------------------------------------------------------------------

# Check if Guake is currently visible
IS_VISIBLE=$(guake_is_visible)

# Get current monitor index where Guake is displayed
CURRENT_INDEX=$(gsettings get guake.general display-n)

if [ "$IS_VISIBLE" -eq 1 ]; then
    # Guake is visible
    if [ "$CURRENT_INDEX" -eq "$TARGET_INDEX" ]; then
        # Same monitor - hide
        guake_hide
    else
        # Different monitor - move (hide, change setting, show)
        guake_hide
        gsettings set guake.general display-n "$TARGET_INDEX"
        guake_show
    fi
else
    # Guake is hidden - show on target monitor
    gsettings set guake.general display-n "$TARGET_INDEX"
    guake_show
fi
