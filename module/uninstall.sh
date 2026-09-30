#!/system/bin/sh
# Go bo module va don dep sach se cac quy tac
MODDIR=${0%/*}

if [ -f "/data/adb/susfs4ksu/sus_open_redirect.txt" ]; then
    sed -i '/compat_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
    sed -i '/clean_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
fi

if [ -f "/data/adb/susfs4ksu/sus_path.txt" ]; then
    COMPONENT_LIST=""
    if [ -f "$MODDIR/compat_isolated_components.txt" ]; then
        COMPONENT_LIST="$MODDIR/compat_isolated_components.txt"
    elif [ -f "$MODDIR/detected_paths.txt" ]; then
        COMPONENT_LIST="$MODDIR/detected_paths.txt"
    fi

    if [ -n "$COMPONENT_LIST" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            escaped_p=$(echo "$p" | sed 's/\//\\\//g')
            sed -i "/$escaped_p/d" /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
        done < "$COMPONENT_LIST"
    fi

    # Don dep fallback cu
    sed -i '/XiaomiEUExt/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
    sed -i '/MiuiExtraPhoto/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
    sed -i '/HyperTN/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
    sed -i '/TNToolbox/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
    sed -i '/Elite/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
fi

rm -f /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
rm -f /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
