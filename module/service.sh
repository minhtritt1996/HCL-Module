#!/system/bin/sh
MODDIR=${0%/*}

# Chi chay sau khi he thong da boot xong hoan toan vao Launcher (bao ve tuyet doi cho modem)
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
HYPEROS_DEVICE=$(getprop ro.product.device)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.product.name)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.build.product)

HYPEROS_RAW_MOD_DEVICE=$(getprop ro.product.mod_device)
if echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_in_global"; then
    HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_in_global"
elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_ru_global"; then
    HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_ru_global"
elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_eea_global"; then
    HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_eea_global"
elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_global"; then
    HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_global"
elif [ -n "$HYPEROS_RAW_MOD_DEVICE" ]; then
    HYPEROS_NORM_MOD_DEVICE=$(echo "$HYPEROS_RAW_MOD_DEVICE" | sed -E 's/_(xiaomieu|eu|hypertn|tn|elite|eliterom|mipa|pulse|mod|custom)//Ig')
    [ -z "$HYPEROS_NORM_MOD_DEVICE" ] && HYPEROS_NORM_MOD_DEVICE="$HYPEROS_DEVICE"
else
    HYPEROS_NORM_MOD_DEVICE="$HYPEROS_DEVICE"
fi

# 3. Chuan hoa properties trong bo nho RAM
$RESETPROP -n -v ro.build.host c5-build-66.bj.xiaomi.com
[ -n "$HYPEROS_NORM_MOD_DEVICE" ] && $RESETPROP -n -v ro.product.mod_device "$HYPEROS_NORM_MOD_DEVICE"

# Xu ly rom userdebug / debuggable neu co
[ "$(getprop ro.build.type)" = "userdebug" ] && $RESETPROP -n -v ro.build.type user
[ "$(getprop ro.debuggable)" = "1" ] && $RESETPROP -n -v ro.debuggable 0

# Quet dong va loai bo toan bo cac property chua chu ky ROM mod
for prop in $(getprop | grep -iE 'xiaomi\.eu|developerid|hypertn|eliterom|mipa|pulse|lineage|modversion' | sed -E 's/^\[([^]]+)\].*/\1/'); do
    [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
done

# 4. Chuan bi compat_build.prop cho SuSFS
mkdir -p /mnt/vendor/susfs4ksu 2>/dev/null
TARGET_COMPAT_PROP=""
SOURCE_PROP_FILE=""

if [ -f "$MODDIR/compat_build.prop" ]; then
    SOURCE_PROP_FILE="$MODDIR/compat_build.prop"
elif [ -f "$MODDIR/clean_build.prop" ]; then
    SOURCE_PROP_FILE="$MODDIR/clean_build.prop"
fi

if [ -n "$SOURCE_PROP_FILE" ]; then
    cp -f "$SOURCE_PROP_FILE" /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
    chmod 644 /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
    chcon u:object_r:system_file:s0 /mnt/vendor/susfs4ksu/compat_build.prop 2>/dev/null || true
    # Legacy link
    cp -f "$SOURCE_PROP_FILE" /mnt/vendor/susfs4ksu/clean_build.prop 2>/dev/null || true
fi

if [ -f "/mnt/vendor/susfs4ksu/compat_build.prop" ]; then
    TARGET_COMPAT_PROP="/mnt/vendor/susfs4ksu/compat_build.prop"
elif [ -f "/data/adb/susfs4ksu/compat_build.prop" ]; then
    TARGET_COMPAT_PROP="/data/adb/susfs4ksu/compat_build.prop"
elif [ -f "/mnt/vendor/susfs4ksu/clean_build.prop" ]; then
    TARGET_COMPAT_PROP="/mnt/vendor/susfs4ksu/clean_build.prop"
elif [ -f "/data/adb/susfs4ksu/clean_build.prop" ]; then
    TARGET_COMPAT_PROP="/data/adb/susfs4ksu/clean_build.prop"
elif [ -n "$SOURCE_PROP_FILE" ]; then
    TARGET_COMPAT_PROP="$SOURCE_PROP_FILE"
fi

# 5. Kich hoat quy tac SuSFS (Chi ap dung cho app nguoi dung uid >= 10000, khong dong vao system daemons)
SUSFS_BIN=""
if [ -f "/data/adb/ksu/bin/ksu_susfs" ]; then
    SUSFS_BIN="/data/adb/ksu/bin/ksu_susfs"
elif [ -f "/data/adb/ap/bin/ap_susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/ap_susfs"
elif command -v ksu_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ksu_susfs"
fi

if [ -n "$SUSFS_BIN" ] && [ -x "$SUSFS_BIN" ] && [ -n "$($SUSFS_BIN show version 2>/dev/null)" ]; then
    # Cach ly cac thanh phan ROM mod da phat hien dong
    COMPONENT_LIST=""
    if [ -f "$MODDIR/compat_isolated_components.txt" ]; then
        COMPONENT_LIST="$MODDIR/compat_isolated_components.txt"
    elif [ -f "$MODDIR/detected_paths.txt" ]; then
        COMPONENT_LIST="$MODDIR/detected_paths.txt"
    fi

    if [ -n "$COMPONENT_LIST" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            if [ -e "$p" ]; then
                $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
            fi
        done < "$COMPONENT_LIST"
    else
        # Fallback neu chua co danh sach quet
        for p in "/product/priv-app/XiaomiEUExt" \
                 "/product/priv-app/XiaomiEUExt/XiaomiEUExt.apk" \
                 "/product/priv-app/MiuiExtraPhoto" \
                 "/product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk"; do
            [ -e "$p" ] && $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
        done
    fi

    # UID scheme 3 = chi danh cho cac app khong gian nguoi dung co uid >= 10000
    if [ -n "$TARGET_COMPAT_PROP" ]; then
        $SUSFS_BIN add_open_redirect /system/build.prop "$TARGET_COMPAT_PROP" 3 2>/dev/null || true
    fi
fi
