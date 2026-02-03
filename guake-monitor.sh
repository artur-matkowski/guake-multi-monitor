#!/bin/bash
#==============================================================================
# GUAKE MULTI-MONITOR CONTROLLER
#
# Usage: guake-monitor.sh [--debug] <SLOT>
# Example: guake-monitor.sh 1
#          guake-monitor.sh --debug 1
#
# Behavior:
#   - Guake hidden → show on target monitor
#   - Guake visible on SAME monitor → hide
#   - Guake visible on DIFFERENT monitor → move to target (stays visible)
#==============================================================================

#------------------------------------------------------------------------------
# DEBUG MODE
#------------------------------------------------------------------------------
DEBUG=0
if [ "$1" = "--debug" ]; then
    DEBUG=1
    shift
fi

debug_log() {
    [ "$DEBUG" -eq 1 ] && echo "[DEBUG] $*" >&2
}

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
    echo "Usage: $0 [--debug] <SLOT_NUMBER>"
    echo "Slots: 1, 2, 3, 4"
    echo ""
    echo "Options:"
    echo "  --debug    Enable debug logging to stderr"
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
# Caching with verification and retry mechanism
#------------------------------------------------------------------------------
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/guake-monitor"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/slot-${SLOT_NUM}.idx"

# Retry settings: 100ms, 200ms, 400ms
RETRY_DELAYS=(0.1 0.2 0.4)
MAX_RETRIES=${#RETRY_DELAYS[@]}

# Extract output name at a given index from xrandr output
# Args: $1 = xrandr output, $2 = index
get_output_at_index() {
    local xrandr_out="$1"
    local idx="$2"
    echo "$xrandr_out" | awk -v idx="$idx" '$1 == idx":" {print $2}'
}

# Find index for target output in xrandr output
# Args: $1 = xrandr output, $2 = target output name
find_index_for_output() {
    local xrandr_out="$1"
    local target="$2"
    echo "$xrandr_out" | grep -w "$target" | awk '{print $1}' | tr -d ':'
}

# Verify cached index still points to expected output
# Args: $1 = xrandr output, $2 = cached index, $3 = expected output name
# Returns: 0 if valid, 1 if invalid
verify_cached_index() {
    local xrandr_out="$1"
    local cached_idx="$2"
    local expected_output="$3"
    local actual_output

    actual_output=$(get_output_at_index "$xrandr_out" "$cached_idx")
    debug_log "Verifying cache: index $cached_idx -> '$actual_output' (expected: '$expected_output')"

    [ "$actual_output" = "$expected_output" ]
}

# Main lookup function with retry mechanism
find_output_index() {
    local target="$1"
    local attempt=0
    local xrandr_out
    local idx

    while [ $attempt -le $MAX_RETRIES ]; do
        xrandr_out=$(xrandr --listmonitors)
        debug_log "Attempt $((attempt+1)): xrandr output:"
        [ "$DEBUG" -eq 1 ] && echo "$xrandr_out" | sed 's/^/  /' >&2

        idx=$(find_index_for_output "$xrandr_out" "$target")

        if [ -n "$idx" ]; then
            debug_log "Found $target at index $idx"
            echo "$idx"
            return 0
        fi

        if [ $attempt -lt $MAX_RETRIES ]; then
            debug_log "Output $target not found, waiting ${RETRY_DELAYS[$attempt]}s before retry..."
            sleep "${RETRY_DELAYS[$attempt]}"
        fi
        ((attempt++))
    done

    debug_log "Output $target not found after $MAX_RETRIES retries"
    return 1
}

# Get current xrandr state
XRANDR_OUTPUT=$(xrandr --listmonitors)
debug_log "Target output: $TARGET_OUTPUT"
debug_log "Cache file: $CACHE_FILE"

# Try to use cache with verification
TARGET_INDEX=""
if [ -f "$CACHE_FILE" ]; then
    CACHED_INDEX=$(cat "$CACHE_FILE")
    debug_log "Found cached index: $CACHED_INDEX"

    if verify_cached_index "$XRANDR_OUTPUT" "$CACHED_INDEX" "$TARGET_OUTPUT"; then
        debug_log "Cache verified successfully"
        TARGET_INDEX="$CACHED_INDEX"
    else
        debug_log "Cache verification failed, invalidating"
        rm -f "$CACHE_FILE"
    fi
else
    debug_log "No cache file found"
fi

# If cache miss or invalid, do fresh lookup with retries
if [ -z "$TARGET_INDEX" ]; then
    debug_log "Performing fresh lookup with retry mechanism"
    TARGET_INDEX=$(find_output_index "$TARGET_OUTPUT")

    if [ -n "$TARGET_INDEX" ]; then
        debug_log "Caching verified index: $TARGET_INDEX"
        echo "$TARGET_INDEX" > "$CACHE_FILE"
    fi
fi

if [ -z "$TARGET_INDEX" ]; then
    notify-send "Guake" "Monitor $TARGET_OUTPUT not found" --icon=dialog-warning
    exit 1
fi

debug_log "Final target index: $TARGET_INDEX"

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
