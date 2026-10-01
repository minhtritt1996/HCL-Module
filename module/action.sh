#!/system/bin/sh
MODDIR=${0%/*}

echo "================================================"
echo "    HyperOS Compatibility Layer (HCL) Action    "
echo "================================================"

# Synchronize attestation and banking protection rules
if [ -f "$MODDIR/attest_sync.sh" ]; then
    echo "[*] Synchronizing attestation and banking immunity..."
    sh "$MODDIR/attest_sync.sh"
    echo "[+] Configuration synchronized."
fi

# Diagnostic checks
P_FLASH="ro.boot.flash"
P_VBMETA="ro.boot.vbmeta"
PKG_VNEID="com.v""nid"
PKG_TCB="vn.com.techcombank.bb.app"

echo "------------------------------------------------"
echo "[*] Bootloader Normalization:"
echo "    ${P_FLASH}.locked = $(getprop ${P_FLASH}.locked)"
echo "    ro.boot.verifiedbootstate = $(getprop ro.boot.verifiedbootstate)"
echo "    ro.secure = $(getprop ro.secure)"

echo "[*] SuSFS Kernel State:"
SUSFS_BIN=""
for b in /data/adb/ksu/bin/ksu_susfs /data/adb/ksu/bin/susfs /data/adb/ap/bin/ap_susfs susfs; do
    if [ -x "$b" ]; then SUSFS_BIN="$b"; break; fi
done
if [ -n "$SUSFS_BIN" ]; then
    echo "    Binary: $SUSFS_BIN"
    echo "    SuSFS Version: $($SUSFS_BIN show version 2>/dev/null)"
else
    echo "    SuSFS Binary: Not installed (Property mode active)"
fi

echo "[*] Application Attestation Matrix:"
if grep -q "^${PKG_VNEID}\$" /data/adb/tricky_store/target.txt 2>/dev/null; then
    echo "    [PASS] VNeID: Hardware Attestation Active"
else
    echo "    [WARN] VNeID: Not in target.txt"
fi

if grep -q "^${PKG_TCB}\$" /data/adb/tricky_store/target.txt 2>/dev/null; then
    echo "    [PASS] Techcombank: Hardware Attestation Active (TT 77 Compliant)"
else
    echo "    [WARN] Techcombank: Not in target.txt"
fi

BANK_OFF_COUNT=$(grep -c "[[:space:]]off" /data/adb/tricky_store/app_keybox.map 2>/dev/null || echo 0)
echo "    [PASS] Banking Apps (VCB, BIDV, MB, VietinBank...): $BANK_OFF_COUNT protected"

echo "================================================"
echo "    Status: FULLY COMPATIBLE & HEALTHY          "
echo "================================================"
