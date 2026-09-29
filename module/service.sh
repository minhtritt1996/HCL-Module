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

# 2. Xac dinh ma may sach se (giu nguyen hau to _global de modem hoat dong chuan)
CURR_DEV=$(getprop ro.product.device)
[ -z "$CURR_DEV" ] && CURR_DEV=$(getprop ro.product.name)
[ -z "$CURR_DEV" ] && CURR_DEV=$(getprop ro.build.product)

MOD_DEV=$(getprop ro.product.mod_device)
CLEAN_MOD=$(echo "$MOD_DEV" | sed -E 's/_(xiaomieu|eu)//g')
[ -z "$CLEAN_MOD" ] && CLEAN_MOD="$CURR_DEV"

# 3. Lam sach properties trong bo nho RAM
$RESETPROP -n -v ro.build.host c5-build-66.bj.xiaomi.com
$RESETPROP -n -v -d ro.xiaomi.eu.ota_device
$RESETPROP -n -v -d ro.xiaomi.eu.version.code_time
$RESETPROP -n -v -d ro.xiaomi.developerid
[ -n "$CLEAN_MOD" ] && $RESETPROP -n -v ro.product.mod_device "$CLEAN_MOD"

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
    for p in "/product/priv-app/XiaomiEUExt" \
             "/product/priv-app/XiaomiEUExt/XiaomiEUExt.apk" \
             "/product/priv-app/MiuiExtraPhoto" \
             "/product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk"; do
        if [ -e "$p" ]; then
            $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
        fi
    done

    # UID scheme 3 = chi danh cho cac app duoc unmount co uid >= 10000 (VNeID, App ngan hang)
    if [ -f "/mnt/vendor/susfs4ksu/clean_build.prop" ]; then
        $SUSFS_BIN add_open_redirect /system/build.prop /mnt/vendor/susfs4ksu/clean_build.prop 3 2>/dev/null || true
    fi
fi
