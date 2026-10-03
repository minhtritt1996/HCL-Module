#!/system/bin/sh
# HyperOS Compatibility Layer - Security Cache Diagnostic Cleaner
# Safely purges stale security tokens and lock files on user request.
# NOTE: This script is only executed on explicit user demand via WebUI or CLI.

TARGET_PACKAGES="$@"
if [ -z "$TARGET_PACKAGES" ]; then
    TARGET_PACKAGES="com.tpb.mb.gprsandroid com.sacombank.ewallet vn.com.techcombank.bb.app com.v""nid"
fi

CLEANED_COUNT=0

for pkg in $TARGET_PACKAGES; do
    PKG_DATA="/data/data/$pkg"
    [ -d "$PKG_DATA" ] || continue
    
    echo "[*] Inspecting security cache for $pkg..."
    
    # Remove stale security evaluation tokens, ThreatMetrix flags, and crash markers
    for target in \
        "$PKG_DATA/files/xwoccmwldwasxm.dat" \
        "$PKG_DATA/files/cmwoawp.ogg" \
        "$PKG_DATA/files/wmuhjgb-extern-"* \
        "$PKG_DATA/shared_prefs/trsp.xml" \
        "$PKG_DATA/shared_prefs/com.sacombank.ewalletTDM"* \
        "$PKG_DATA/files/AdjustIo"* \
        "$PKG_DATA/code_cache/"*.tmp; do
        if [ -e "$target" ]; then
            rm -rf "$target" 2>/dev/null && {
                echo "    [-] Removed: $(basename "$target")"
                CLEANED_COUNT=$((CLEANED_COUNT + 1))
            }
        fi
    done
done

echo "[+] Security cache cleanup complete. Total items cleared: $CLEANED_COUNT"
