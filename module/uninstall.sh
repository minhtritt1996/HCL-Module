#!/system/bin/sh
# Go bo module va don dep cac quy tac
if [ -f "/data/adb/susfs4ksu/sus_open_redirect.txt" ]; then
    sed -i '/clean_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
fi
if [ -f "/data/adb/susfs4ksu/sus_path.txt" ]; then
    sed -i '/XiaomiEUExt/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
    sed -i '/MiuiExtraPhoto/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
fi
rm -f /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
rm -f /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
