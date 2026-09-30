#!/system/bin/sh
MODDIR=${0%/*}

# Chi chay sau khi he thong da boot xong hoan toan vao Launcher (tuyet doi an toan)
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# 1. Tim cong cu resetprop
RESETPROP="resetprop"
if [ -f "/data/adb/ksu/bin/resetprop" ]; then
    RESETPROP="/data/adb/ksu/bin/resetprop"
elif [ -f "/data/adb/ap/bin/resetprop" ]; then
    RESETPROP="/data/adb/ap/bin/resetprop"
elif [ -f "/data/adb/magisk/magisk" ]; then
    RESETPROP="/data/adb/magisk/magisk --resetprop"
fi

# 2. Xac dinh thiet bi va chuan hoa ma may sach se
CURR_DEV=$(getprop ro.product.device)
[ -z "$CURR_DEV" ] && CURR_DEV=$(getprop ro.product.name)
[ -z "$CURR_DEV" ] && CURR_DEV=$(getprop ro.build.product)

CURR_MOD_DEV=$(getprop ro.product.mod_device)
if echo "$CURR_MOD_DEV" | grep -qi "_in_global"; then
    CLEAN_MOD="${CURR_DEV}_in_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_ru_global"; then
    CLEAN_MOD="${CURR_DEV}_ru_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_eea_global"; then
    CLEAN_MOD="${CURR_DEV}_eea_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_global"; then
    CLEAN_MOD="${CURR_DEV}_global"
elif [ -n "$CURR_MOD_DEV" ]; then
    CLEAN_MOD=$(echo "$CURR_MOD_DEV" | sed -E 's/_(xiaomieu|eu|hypertn|tn|elite|eliterom|mipa|pulse|mod|custom)//Ig')
    [ -z "$CLEAN_MOD" ] && CLEAN_MOD="$CURR_DEV"
else
    CLEAN_MOD="$CURR_DEV"
fi

# 3. Lam sach properties trong bo nho RAM dong thoi
$RESETPROP -n -v ro.build.host c5-build-66.bj.xiaomi.com
[ -n "$CLEAN_MOD" ] && $RESETPROP -n -v ro.product.mod_device "$CLEAN_MOD"

# Xu ly rom userdebug / debuggable neu co
[ "$(getprop ro.build.type)" = "userdebug" ] && $RESETPROP -n -v ro.build.type user
[ "$(getprop ro.debuggable)" = "1" ] && $RESETPROP -n -v ro.debuggable 0

# Quet dong va xoa toan bo cac property chua chu ky ROM mod
for prop in $(getprop | grep -iE 'xiaomi\.eu|developerid|hypertn|eliterom|mipa|pulse|lineage|modversion' | sed -E 's/^\[([^]]+)\].*/\1/'); do
    [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
done

# 4. Chuan bi clean_build.prop cho SuSFS
mkdir -p /mnt/vendor/susfs4ksu 2>/dev/null
if [ -f "$MODDIR/clean_build.prop" ]; then
    cp -f "$MODDIR/clean_build.prop" /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
    chmod 644 /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
    chcon u:object_r:system_file:s0 /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
fi

# 5. Kich hoat luat SuSFS (Chi ap dung cho app nguoi dung uid >= 10000, khong dong vao system daemons)
SUSFS_BIN=""
if [ -f "/data/adb/ksu/bin/ksu_susfs" ]; then
    SUSFS_BIN="/data/adb/ksu/bin/ksu_susfs"
elif [ -f "/data/adb/ap/bin/ap_susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/ap_susfs"
elif command -v ksu_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ksu_susfs"
fi

if [ -n "$SUSFS_BIN" ] && [ -d "/sys/fs/susfs" ]; then
    # An toan bo cac priv-app da duoc phat hien dong
    if [ -f "$MODDIR/detected_paths.txt" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            if [ -e "$p" ]; then
                $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
            fi
        done < "$MODDIR/detected_paths.txt"
    else
        # Fallback neu chua co detected_paths.txt
        for p in "/product/priv-app/XiaomiEUExt" \
                 "/product/priv-app/XiaomiEUExt/XiaomiEUExt.apk" \
                 "/product/priv-app/MiuiExtraPhoto" \
                 "/product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk"; do
            [ -e "$p" ] && $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
        done
    fi

    # UID scheme 3 = chi danh cho cac app duoc unmount co uid >= 10000 (VNeID, App ngan hang)
    if [ -f "/mnt/vendor/susfs4ksu/clean_build.prop" ]; then
        $SUSFS_BIN add_open_redirect /system/build.prop /mnt/vendor/susfs4ksu/clean_build.prop 3 2>/dev/null || true
    fi
fi
