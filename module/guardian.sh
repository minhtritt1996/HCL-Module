#!/system/bin/sh
# HyperOS Compatibility Layer - Background Guardian Daemon
# Low-overhead monitoring daemon with configurable interval and kill-switch.

MODDIR=${0%/*}
CONF_DIR="/data/adb/hyperos_compat"
CONF_FILE="$CONF_DIR/config.json"
KILL_SWITCH="$CONF_DIR/disable_guardian"
TRICKY_DIR="/data/adb/tricky_store"
PIDFILE="/dev/hcl_guardian.pid"

# Check kill-switch immediately
if [ -f "$KILL_SWITCH" ]; then
    exit 0
fi

# Check single instance
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && [ -d "/proc/$OLD_PID" ]; then
        exit 0
    fi
fi
echo "$$" > "$PIDFILE" 2>/dev/null || true

trap '' HUP
cleanup() {
    rm -f "$PIDFILE" 2>/dev/null || true
    exit 0
}
trap cleanup TERM INT

# Read interval and enabled state from config
get_conf_val() {
    key="$1"
    file="$2"
    [ -f "$file" ] || return 0
    sed -n -E "s/.*\"$key\": *\"?([^,\"]*)\"?.*/\1/p" "$file" 2>/dev/null | head -n 1
}

LAST_PKG_STAMP=""
if [ -f "/data/system/packages.xml" ]; then
    LAST_PKG_STAMP=$(stat -c %Y /data/system/packages.xml 2>/dev/null || stat -c %Z /data/system/packages.xml 2>/dev/null || true)
fi

while true; do
    # Check kill switch at start of each iteration
    if [ -f "$KILL_SWITCH" ]; then
        break
    fi

    # Read config dynamically
    INTERVAL=120
    if [ -f "$CONF_FILE" ]; then
        IS_ENABLED=$(get_conf_val "enabled" "$CONF_FILE")
        if [ "$IS_ENABLED" = "false" ]; then
            break
        fi
        CFG_INT=$(get_conf_val "interval_seconds" "$CONF_FILE")
        if [ -n "$CFG_INT" ] && [ "$CFG_INT" -ge 15 ] 2>/dev/null; then
            INTERVAL="$CFG_INT"
        fi
    fi

    sleep "$INTERVAL"

    if [ -d "$TRICKY_DIR" ]; then
        NEED_SYNC=0

        # Check essential integrity flags
        if [ ! -f "$TRICKY_DIR/no_prop_unify" ]; then
            NEED_SYNC=1
        fi

        # Check if package manager state changed (new app installed or uninstalled)
        if [ -f "/data/system/packages.xml" ]; then
            CURR_PKG_STAMP=$(stat -c %Y /data/system/packages.xml 2>/dev/null || stat -c %Z /data/system/packages.xml 2>/dev/null || true)
            if [ -n "$CURR_PKG_STAMP" ] && [ "$CURR_PKG_STAMP" != "$LAST_PKG_STAMP" ]; then
                NEED_SYNC=1
                LAST_PKG_STAMP="$CURR_PKG_STAMP"
            fi
        fi

        # Only execute sync if an actual change occurred
        if [ "$NEED_SYNC" -eq 1 ] && [ -f "$MODDIR/attest_sync.sh" ]; then
            sh "$MODDIR/attest_sync.sh" >/dev/null 2>&1
        fi
    fi
done

rm -f "$PIDFILE" 2>/dev/null || true
