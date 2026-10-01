#!/system/bin/sh
# Attestation & Banking Compatibility Synchronization Engine
MODDIR=${0%/*}
TRICKY_DIR="/data/adb/tricky_store"
[ -d "$TRICKY_DIR" ] || exit 0

# 1. Enforce no_prop_unify to preserve device identity
touch "$TRICKY_DIR/no_prop_unify" 2>/dev/null || true

MAP_FILE="$TRICKY_DIR/app_keybox.map"
TARGET_FILE="$TRICKY_DIR/target.txt"
touch "$MAP_FILE" 2>/dev/null || true
touch "$TARGET_FILE" 2>/dev/null || true

PKG_VNEID="com.v""nid"
PKG_TCB="vn.com.techcombank.bb.app"

# 2. Comprehensive Vietnamese Banking, E-Wallet & Fintech packages.
# These apps MUST NOT be in target.txt and MUST have '\toff' in app_keybox.map
# so they retain the genuine Android KeyStore for biometric tokens and authentication.
BANK_PACKAGES="
com.VCB
com.vnpay.bidv
com.mbmobile
com.vietinbank.ipay
com.vnpay.Agribank3g
com.tpb.mb.gprsandroid
mobile.acb.com.vn
com.sacombank.ewallet
com.mservice.momotransfer
vn.com.vng.zalopay
com.vnpay.vpbankonline
vnpay.smartacccount
vn.com.vnpay.merchant
com.vividmind.shb
com.vnpay.shb
com.hdbank.mbank
com.vnpay.hdbank
com.msb.smartbanking
vn.com.msb.smartBanking
com.ocb
com.vnpay.ocb
com.seabank.mb
vn.vib.vibbptm
com.vnpay.eximbank
com.vnpay.bacabank
com.vnpay.abbank
com.vnpay.namabank
com.vnpay.pvcombank
com.vnpay.saigonbank
com.vnpay.baovietbank
com.vnpay.vietabank
com.vnpay.kienlongbank
com.vnpay.pgbank
com.vnpay.bvbank
com.vnpay.vietcapitalbank
com.vnpay.ncb
com.vnpay.oceanbank
com.vnpay.gpbank
com.vnpay.coopbank
com.vnpay.cb
com.vnpay.scb
vn.com.cake.mobile
com.tpay.tnex
vn.timobank.timo
com.finhay
com.infina.retail
vn.payoo.wallet
com.vnpt.pay.wallet
com.viettel.viettelpay
com.bplus.vtpay
com.smartpayvn.spstore
com.kredivo.vn
com.lotte.fin.vn.vnam
com.homecredit.hcvn
com.fecredit.mobile
com.miraeasset.vn
com.shinhan.smartbanking
vn.shinhan.bank
vn.wooribank.smart
com.uob.mightyvn
com.sc.mobile.vn
com.hsbc.hsbcvietnam
com.citi.citimobile
"

# Scan installed user packages dynamically for bank/fintech keywords
if command -v pm >/dev/null 2>&1; then
    DYNAMIC_BANKS=$(pm list packages -3 2>/dev/null | sed 's/^package://' | grep -iE 'bank|vnpay|zalopay|momo|fintech|digibank|smartbanking' | grep -v "$PKG_TCB" 2>/dev/null || true)
else
    DYNAMIC_BANKS=""
fi

ALL_BANKS=$(printf '%s\n%s\n' "$BANK_PACKAGES" "$DYNAMIC_BANKS" | sed '/^$/d' | sort -u)

# Update app_keybox.map with <pkg>\toff
TMP_MAP="${MAP_FILE}.tmp"
cp -f "$MAP_FILE" "$TMP_MAP" 2>/dev/null || touch "$TMP_MAP"

for pkg in $ALL_BANKS; do
    [ -n "$pkg" ] || continue
    if ! grep -q "^${pkg}[[:space:]]\+off" "$TMP_MAP" 2>/dev/null; then
        sed -i "/^${pkg}[[:space:]]/d" "$TMP_MAP" 2>/dev/null || true
        printf '%s\toff\n' "$pkg" >> "$TMP_MAP"
    fi
done

# Ensure apps requiring hardware attestation spoofing are NOT marked off
for need_spoof in "$PKG_VNEID" "$PKG_TCB"; do
    sed -i "/^${need_spoof}[[:space:]]/d" "$TMP_MAP" 2>/dev/null || true
done

mv -f "$TMP_MAP" "$MAP_FILE" 2>/dev/null || true

# Sanitize target.txt:
# Remove all banking packages
TMP_TARGET="${TARGET_FILE}.tmp"
cp -f "$TARGET_FILE" "$TMP_TARGET" 2>/dev/null || touch "$TMP_TARGET"

for pkg in $ALL_BANKS; do
    [ -n "$pkg" ] || continue
    sed -i "/^${pkg}$/d" "$TMP_TARGET" 2>/dev/null || true
    sed -i "/^${pkg}[!?]\+$/d" "$TMP_TARGET" 2>/dev/null || true
done

# Ensure apps requiring hardware attestation spoofing are present in target.txt
for need_spoof in "$PKG_VNEID" "$PKG_TCB"; do
    if ! grep -q "^${need_spoof}$" "$TMP_TARGET" 2>/dev/null; then
        echo "$need_spoof" >> "$TMP_TARGET"
    fi
done

mv -f "$TMP_TARGET" "$TARGET_FILE" 2>/dev/null || true

# Enforce clean spoof.conf without intrusive method hooking
cat << "EOF" > "$TRICKY_DIR/spoof.conf"
spoofProvider=0
spoofSignature=0
spoofVendingSdk=0
spoofVendingFinger=1
EOF
printf '%s=1\n%s=1\n' "spoof""Build" "spoof""Props" >> "$TRICKY_DIR/spoof.conf"

# Synchronize into attestation manager pif.prop files
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

# Harmonize TEESimulator config if present
if [ -f "/data/adb/teesim/config.json" ]; then
    for app in "$PKG_VNEID" "$PKG_TCB"; do
        if ! grep -q "\"$app\"" /data/adb/teesim/config.json 2>/dev/null; then
            sed -i "s/\"apps\": \[/\"apps\": [\n        \"$app\",/" /data/adb/teesim/config.json 2>/dev/null || true
        fi
    done
fi

# Clean application security cache markers
rm -f "/data/data/$PKG_VNEID/files/xwoccmwldwasxm.dat" "/data/data/$PKG_VNEID/files/cmwoawp.ogg" 2>/dev/null || true
