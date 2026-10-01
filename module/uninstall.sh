#!/system/bin/sh
# Remove only compatibility rules owned by this module.
MODDIR=${0%/*}
SUSFS_DIR="/data/adb/susfs4ksu"
SUS_PATH_FILE="$SUSFS_DIR/sus_path.txt"
SUS_REDIRECT_FILE="$SUSFS_DIR/sus_open_redirect.txt"

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

rm -f "$MODDIR/owned_sus_paths.txt"
rm -f "$MODDIR/owned_open_redirect.txt"
rm -f "$MODDIR/compat_isolated_components.txt"
rm -f "$MODDIR/detected_paths.txt"

rm -f /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
rm -f /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true
