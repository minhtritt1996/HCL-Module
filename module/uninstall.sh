#!/system/bin/sh
# HyperOS Compatibility Layer - Module Uninstallation & Restoration
MODDIR=${0%/*}
SUSFS_DIR="/data/adb/susfs4ksu"
SUS_PATH_FILE="$SUSFS_DIR/sus_path.txt"
SUS_REDIRECT_FILE="$SUSFS_DIR/sus_open_redirect.txt"
TRICKY_DIR="/data/adb/tricky_store"
CONF_DIR="/data/adb/hyperos_compat"

# 1. Stop background guardian daemon if running
PIDFILE="/dev/hcl_guardian.pid"
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$PID" ] && [ -d "/proc/$PID" ]; then
        kill "$PID" 2>/dev/null || true
    fi
    rm -f "$PIDFILE" 2>/dev/null || true
fi

# 2. Restore original third-party configuration files from backups
restore_backup() {
    src="$1"
    dst="$2"
    if [ -f "$src" ]; then
        cp -f "$src" "$dst" 2>/dev/null || true
        rm -f "$src" 2>/dev/null || true
    fi
}

if [ -d "$TRICKY_DIR" ]; then
    restore_backup "$TRICKY_DIR/target.txt.hcl_bak" "$TRICKY_DIR/target.txt"
    restore_backup "$TRICKY_DIR/app_keybox.map.hcl_bak" "$TRICKY_DIR/app_keybox.map"
    restore_backup "$TRICKY_DIR/spoof.conf.hcl_bak" "$TRICKY_DIR/spoof.conf"
fi

if [ -d "/data/adb/teesim" ]; then
    restore_backup "/data/adb/teesim/config.json.hcl_bak" "/data/adb/teesim/config.json"
fi

# 3. Remove only compatibility rules owned by this module from SuSFS
remove_owned_lines() {
    file="$1"
    list="$2"
    [ -f "$file" ] || return 0
    [ -f "$list" ] || return 0

    tmp="${file}.hyperos_compat.tmp"
    cp -f "$file" "$tmp" 2>/dev/null || return 0

    while IFS= read -r line; do
        [ -n "$line" ] || continue
        grep -Fvx "$line" "$tmp" > "${tmp}.next" 2>/dev/null || :
        mv -f "${tmp}.next" "$tmp" 2>/dev/null || return 0
    done < "$list"

    mv -f "$tmp" "$file" 2>/dev/null || rm -f "$tmp"
}

remove_owned_lines "$SUS_PATH_FILE" "$MODDIR/owned_sus_paths.txt"
remove_owned_lines "$SUS_REDIRECT_FILE" "$MODDIR/owned_open_redirect.txt"

# Clean legacy references
if [ -f "$SUS_PATH_FILE" ]; then
    sed -i '/MiuiExtraPhoto/d' "$SUS_PATH_FILE" 2>/dev/null || true
fi
if [ -f "$SUS_REDIRECT_FILE" ]; then
    sed -i '/compat_build\.prop/d' "$SUS_REDIRECT_FILE" 2>/dev/null || true
    sed -i '/clean_build\.prop/d' "$SUS_REDIRECT_FILE" 2>/dev/null || true
    sed -i '/hyperos_compat_build\.prop/d' "$SUS_REDIRECT_FILE" 2>/dev/null || true
fi

# 4. Remove generated runtime props and owned records
rm -f "$MODDIR/owned_sus_paths.txt"
rm -f "$MODDIR/owned_open_redirect.txt"
rm -f "$MODDIR/compat_isolated_components.txt"
rm -f "$MODDIR/detected_paths.txt"

rm -f /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
rm -f /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true

# 5. Clean module configuration directory
rm -rf "$CONF_DIR" 2>/dev/null || true
