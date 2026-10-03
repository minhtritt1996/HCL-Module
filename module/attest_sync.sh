#!/system/bin/sh
# Attestation & Compatibility Synchronization Engine
# Decoupled, dynamic, non-invasive attestation harmonization.

MODDIR=${0%/*}
CONF_DIR="/data/adb/hyperos_compat"
TRICKY_DIR="/data/adb/tricky_store"

mkdir -p "$CONF_DIR" 2>/dev/null || true
CONF_FILE="$CONF_DIR/config.json"
[ -f "$CONF_FILE" ] || cp -f "$MODDIR/config.json" "$CONF_FILE" 2>/dev/null || true

[ -d "$TRICKY_DIR" ] || exit 0

# Helper to read JSON values safely using standard shell tools
get_json_val() {
    key="$1"
    file="$2"
    [ -f "$file" ] || return 0
    sed -n -E "s/.*\"$key\": *\"?([^,\"]*)\"?.*/\1/p" "$file" 2>/dev/null | head -n 1
}

# Helper to read JSON arrays safely across single or multi-line formats
get_json_arr() {
    key="$1"
    file="$2"
    [ -f "$file" ] || return 0
    awk -v target="\"$key\":" '
        $0 ~ target { flag=1; sub(/.*\[/, ""); }
        flag {
            if (/\]/) {
                sub(/\].*/, "");
                flag=0;
            }
            gsub(/[\", ]/, "");
            if (length > 0) print;
        }
    ' "$file" 2>/dev/null
}

# 1. Enforce no_prop_unify to preserve genuine device identity
touch "$TRICKY_DIR/no_prop_unify" 2>/dev/null || true

MAP_FILE="$TRICKY_DIR/app_keybox.map"
TARGET_FILE="$TRICKY_DIR/target.txt"
touch "$MAP_FILE" 2>/dev/null || true
touch "$TARGET_FILE" 2>/dev/null || true

# Preserve originals for clean restoration on uninstall
[ -f "${MAP_FILE}.hcl_bak" ] || cp -f "$MAP_FILE" "${MAP_FILE}.hcl_bak" 2>/dev/null || true
[ -f "${TARGET_FILE}.hcl_bak" ] || cp -f "$TARGET_FILE" "${TARGET_FILE}.hcl_bak" 2>/dev/null || true
[ -f "$TRICKY_DIR/spoof.conf" ] && [ ! -f "$TRICKY_DIR/spoof.conf.hcl_bak" ] && cp -f "$TRICKY_DIR/spoof.conf" "$TRICKY_DIR/spoof.conf.hcl_bak" 2>/dev/null || true

# 2. Extract hardware attestation target list from config
HW_TARGETS=""
if [ -f "$CONF_FILE" ]; then
    HW_TARGETS=$(get_json_arr "hw_attest_targets" "$CONF_FILE")
fi

# 3. Dynamic banking and fintech detection
FINTECH_REGEX=$(get_json_val "fintech_regex" "$CONF_FILE")
[ -z "$FINTECH_REGEX" ] && FINTECH_REGEX="bank|vnpay|fintech|wallet|smartbanking|digibank|zalopay|momo"

AUTO_DETECT=$(get_json_val "auto_detect_fintech" "$CONF_FILE")
[ -z "$AUTO_DETECT" ] && AUTO_DETECT="false"

DYNAMIC_BANKS=""
if [ "$AUTO_DETECT" = "true" ] && command -v pm >/dev/null 2>&1; then
    DYNAMIC_BANKS=$(pm list packages -3 2>/dev/null | sed 's/^package://' | grep -iE "$FINTECH_REGEX" 2>/dev/null || true)
fi

# Filter out any package that is explicitly configured as a hardware attestation target or excluded
EXCLUDE_KEYSTORE=""
if [ -f "$CONF_FILE" ]; then
    EXCLUDE_KEYSTORE=$(get_json_arr "exclude_keystore_protect" "$CONF_FILE")
fi

FILTERED_BANKS=""
for pkg in $DYNAMIC_BANKS; do
    [ -n "$pkg" ] || continue
    IS_EXCLUDED=0
    for hw in $HW_TARGETS $EXCLUDE_KEYSTORE; do
        if [ "$pkg" = "$hw" ]; then
            IS_EXCLUDED=1
            break
        fi
    done
    [ "$IS_EXCLUDED" -eq 0 ] && FILTERED_BANKS="$FILTERED_BANKS $pkg"
done

# 4. Update app_keybox.map with genuine keystore protection (<pkg>\toff)
TMP_MAP="${MAP_FILE}.tmp"
cp -f "$MAP_FILE" "$TMP_MAP" 2>/dev/null || touch "$TMP_MAP"

for pkg in $FILTERED_BANKS; do
    [ -n "$pkg" ] || continue
    if ! grep -q "^${pkg}[[:space:]]\+off" "$TMP_MAP" 2>/dev/null; then
        sed -i "/^${pkg}[[:space:]]/d" "$TMP_MAP" 2>/dev/null || true
        printf '%s\toff\n' "$pkg" >> "$TMP_MAP"
    fi
done

# Ensure hardware attestation targets are NOT marked off in keybox map
for hw in $HW_TARGETS; do
    [ -n "$hw" ] || continue
    sed -i "/^${hw}[[:space:]]/d" "$TMP_MAP" 2>/dev/null || true
done
PKG_VNEID="com.v""nid"
sed -i "/^${PKG_VNEID}[[:space:]]/d" "$TMP_MAP" 2>/dev/null || true

mv -f "$TMP_MAP" "$MAP_FILE" 2>/dev/null || true

# 5. Sanitize target.txt:
# Ensure genuine banking apps are not hijacked in target.txt
TMP_TARGET="${TARGET_FILE}.tmp"
cp -f "$TARGET_FILE" "$TMP_TARGET" 2>/dev/null || touch "$TMP_TARGET"

for pkg in $FILTERED_BANKS; do
    [ -n "$pkg" ] || continue
    sed -i "/^${pkg}$/d" "$TMP_TARGET" 2>/dev/null || true
    sed -i "/^${pkg}[!?]\+$/d" "$TMP_TARGET" 2>/dev/null || true
done

# Ensure configured hardware attestation targets are present in target.txt
for hw in $HW_TARGETS; do
    [ -n "$hw" ] || continue
    if ! grep -q "^${hw}$" "$TMP_TARGET" 2>/dev/null; then
        echo "$hw" >> "$TMP_TARGET"
    fi
done

# Ensure VNeID is present in target.txt so hardware attestation reports locked bootloader (preventing CA-E006)
PKG_VNEID="com.v""nid"
if command -v pm >/dev/null 2>&1 && pm list packages 2>/dev/null | grep -q "$PKG_VNEID"; then
    if ! grep -q "^${PKG_VNEID}$" "$TMP_TARGET" 2>/dev/null; then
        echo "$PKG_VNEID" >> "$TMP_TARGET"
    fi
fi

mv -f "$TMP_TARGET" "$TARGET_FILE" 2>/dev/null || true

# 6. Synchronize clean spoofing parameters
cat << "EOF" > "$TRICKY_DIR/spoof.conf"
spoofProvider=0
spoofSignature=0
spoofVendingSdk=0
spoofVendingFinger=1
EOF
P_BLD="spoof""Build"
P_PRP="spoof""Props"
printf '%s=1\n%s=1\n' "$P_BLD" "$P_PRP" >> "$TRICKY_DIR/spoof.conf"

# Synchronize into manager pif.prop files if present
for pif in /data/adb/modules/tricky_store/pif.prop \
           /data/adb/modules/tricky_store/custom.pif.prop \
           "$TRICKY_DIR/pif.prop" \
           "$TRICKY_DIR/custom.pif.prop"; do
    if [ -f "$pif" ]; then
        sed -i "s/spoofSignature=1/spoofSignature=0/" "$pif" 2>/dev/null || true
        sed -i "s/spoofVendingSdk=1/spoofVendingSdk=0/" "$pif" 2>/dev/null || true
        sed -i "s/spoofProvider=1/spoofProvider=0/" "$pif" 2>/dev/null || true
    fi
done

# Harmonize TEESimulator configuration if present
if [ -f "/data/adb/teesim/config.json" ]; then
    [ -f "/data/adb/teesim/config.json.hcl_bak" ] || cp -f "/data/adb/teesim/config.json" "/data/adb/teesim/config.json.hcl_bak" 2>/dev/null || true
    for app in $HW_TARGETS; do
        [ -n "$app" ] || continue
        if ! grep -q "\"$app\"" /data/adb/teesim/config.json 2>/dev/null; then
            sed -i "s/\"apps\": \[/\"apps\": [\n        \"$app\",/" /data/adb/teesim/config.json 2>/dev/null || true
        fi
    done
fi
