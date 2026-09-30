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

# 2. Xac dinh thiet bi va moi truong he dieu hanh (HyperOS vs AOSP)
ROM_ENV="aosp"
if [ -f "$MODDIR/rom_env.txt" ]; then
    ROM_ENV=$(cat "$MODDIR/rom_env.txt" | tr -d ' \r\n')
elif [ -n "$(getprop ro.miui.ui.version.name)" ] || \
     [ -n "$(getprop ro.miui.version.code_time)" ] || \
     [ -n "$(getprop ro.miui.ui.version.code)" ] || \
     [ -f "/system/framework/framework-ext-res.apk" ] || \
     [ -d "/system/priv-app/miui" ] || \
     [ -d "/system/priv-app/MiuiHome" ]; then
    ROM_ENV="hyperos"
fi

HYPEROS_DEVICE=$(getprop ro.product.device)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.product.name)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.build.product)

# 3. Chuan hoa properties trong bo nho RAM
if [ "$ROM_ENV" = "hyperos" ]; then
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

    # Chuan hoa may chu build goc Xiaomi va mod_device cua Xiaomi
    $RESETPROP -n -v ro.build.host c5-build-66.bj.xiaomi.com
    [ -n "$HYPEROS_NORM_MOD_DEVICE" ] && $RESETPROP -n -v ro.product.mod_device "$HYPEROS_NORM_MOD_DEVICE"

    # Quet dong va loai bo thuoc tinh chu ky ROM mod Xiaomi
    for prop in $(getprop | grep -iE 'xiaomi\.eu|developerid|hypertn|eliterom|mipa|pulse' | sed -E 's/^\[([^]]+)\].*/\1/'); do
        [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
    done
else
    # AOSP Profile: Loai bo cac property rò rỉ của ROM AOSP tuy bien ma khong chen thuoc tinh Xiaomi
    for prop in $(getprop | grep -iE 'lineage\.(build|version|device|display)|crdroid|evolution|pixelexperience|havoc|derp|modversion' | sed -E 's/^\[([^]]+)\].*/\1/'); do
        [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
    done
fi

# Xu ly rom userdebug / debuggable chung cho moi loai ROM
[ "$(getprop ro.build.type)" = "userdebug" ] && $RESETPROP -n -v ro.build.type user
[ "$(getprop ro.debuggable)" = "1" ] && $RESETPROP -n -v ro.debuggable 0

# Chuan hoa trang thai Bootloader va toan ven thiet bi
$RESETPROP -n -v ro.boot.flash.locked 1
$RESETPROP -n -v ro.boot.verifiedbootstate green
$RESETPROP -n -v ro.boot.secureboot 1
$RESETPROP -n -v ro.boot.vbmeta.device_state locked
$RESETPROP -n -v ro.secure 1
$RESETPROP -n -v sys.oem_unlock_allowed 0
$RESETPROP -n -v ro.boot.warranty_bit 0

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
elif [ -f "/data/adb/ksu/bin/susfs" ]; then
    SUSFS_BIN="/data/adb/ksu/bin/susfs"
elif [ -f "/data/adb/ap/bin/ap_susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/ap_susfs"
elif [ -f "/data/adb/ap/bin/susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/susfs"
elif command -v ksu_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ksu_susfs"
elif command -v ap_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ap_susfs"
elif command -v susfs >/dev/null 2>&1; then
    SUSFS_BIN="susfs"
fi

if [ -n "$SUSFS_BIN" ] && [ -x "$SUSFS_BIN" ] && [ -n "$($SUSFS_BIN show version 2>/dev/null)" ]; then
    # Cach ly cac thanh phan ROM mod da phat hien dong
    COMPONENT_LIST=""
    if [ -f "$MODDIR/compat_isolated_components.txt" ]; then
        COMPONENT_LIST="$MODDIR/compat_isolated_components.txt"
    elif [ -f "$MODDIR/detected_paths.txt" ]; then
        COMPONENT_LIST="$MODDIR/detected_paths.txt"
    fi

    SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
    [ -d "/data/adb/susfs4ksu" ] && touch "$SUS_PATH_FILE" 2>/dev/null

    # Dong bo va cau hinh tuong thich cho AlwaysStrong / TrickyStore
    if [ -d "/data/adb/tricky_store" ]; then
        touch /data/adb/tricky_store/no_prop_unify 2>/dev/null || true
        
        # 1. Dam bao com.vnid nam trong target.txt de TrickyStore spoof bootloader locked (tranh loi CA-E006)
        sed -i '/com\.vnid/d' /data/adb/tricky_store/app_keybox.map 2>/dev/null || true
        if [ -f "/data/adb/tricky_store/target.txt" ]; then
            grep -q "^com\.vnid$" /data/adb/tricky_store/target.txt || echo "com.vnid" >> /data/adb/tricky_store/target.txt
        fi

        # 2. Chuan hoa spoof.conf de tranh hook Provider va Signature (nguyen nhan Promon bao CA-E012)
        cat << "EOF" > /data/adb/tricky_store/spoof.conf
spoofProvider=0
spoofSignature=0
spoofVendingSdk=0
spoofVendingFinger=1
spoofBuild=1
spoofProps=1
EOF

        # 3. Dong bo vao cac tap tin pif.prop cua module TrickyStore
        for pif in /data/adb/modules/tricky_store/pif.prop /data/adb/modules/tricky_store/custom.pif.prop /data/adb/tricky_store/pif.prop /data/adb/tricky_store/custom.pif.prop; do
            if [ -f "$pif" ]; then
                sed -i "s/spoofSignature=1/spoofSignature=0/" "$pif" 2>/dev/null || true
                sed -i "s/spoofVendingSdk=1/spoofVendingSdk=0/" "$pif" 2>/dev/null || true
                sed -i "s/spoofProvider=1/spoofProvider=0/" "$pif" 2>/dev/null || true
            fi
        done
    fi

    # Don dep bo nho cache ghi nhan vi pham cua Promon Shield RASP neu co
    rm -f /data/data/com.vnid/files/xwoccmwldwasxm.dat /data/data/com.vnid/files/cmwoawp.ogg 2>/dev/null || true

    if [ -n "$COMPONENT_LIST" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            if [ -e "$p" ]; then
                $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
                if [ -f "$SUS_PATH_FILE" ]; then
                    grep -Fxq "$p" "$SUS_PATH_FILE" 2>/dev/null || echo "$p" >> "$SUS_PATH_FILE"
                fi
            fi
        done < "$COMPONENT_LIST"
    else
        # Fallback neu chua co danh sach quet
        for p in "/product/priv-app/XiaomiEUExt" \
                 "/product/priv-app/XiaomiEUExt/XiaomiEUExt.apk" \
                 "/product/priv-app/MiuiExtraPhoto" \
                 "/product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk" \
                 "/product/app/XiaomiEUInject" \
                 "/product/app/XiaomiEUInject/XiaomiEUInject.apk" \
                 "/system_ext/app/XiaomiEUInject" \
                 "/system/app/XiaomiEUInject"; do
            if [ -e "$p" ]; then
                $SUSFS_BIN add_sus_path "$p" 2>/dev/null || true
                if [ -f "$SUS_PATH_FILE" ]; then
                    grep -Fxq "$p" "$SUS_PATH_FILE" 2>/dev/null || echo "$p" >> "$SUS_PATH_FILE"
                fi
            fi
        done
    fi

    # Cach ly addon.d neu ton tai (co che OTA survival dac thu cua AOSP va Custom ROM)
    for addond in "/system/addon.d" "/system/system/addon.d" "/system_ext/addon.d" "/product/addon.d"; do
        if [ -d "$addond" ] || [ -e "$addond" ]; then
            $SUSFS_BIN add_sus_path "$addond" 2>/dev/null || true
            if [ -f "$SUS_PATH_FILE" ]; then
                grep -Fxq "$addond" "$SUS_PATH_FILE" 2>/dev/null || echo "$addond" >> "$SUS_PATH_FILE"
            fi
            for script in "$addond"/*; do
                if [ -e "$script" ]; then
                    $SUSFS_BIN add_sus_path "$script" 2>/dev/null || true
                    if [ -f "$SUS_PATH_FILE" ]; then
                        grep -Fxq "$script" "$SUS_PATH_FILE" 2>/dev/null || echo "$script" >> "$SUS_PATH_FILE"
                    fi
                fi
            done
        fi
    done

    # UID scheme 3 = chi danh cho cac app khong gian nguoi dung co uid >= 10000
    if [ -n "$TARGET_COMPAT_PROP" ]; then
        $SUSFS_BIN add_open_redirect /system/build.prop "$TARGET_COMPAT_PROP" 3 2>/dev/null || true
        SUS_REDIRECT_FILE="/data/adb/susfs4ksu/sus_open_redirect.txt"
        if [ -f "$SUS_REDIRECT_FILE" ]; then
            grep -Fq "/system/build.prop" "$SUS_REDIRECT_FILE" 2>/dev/null || \
                echo "/system/build.prop $TARGET_COMPAT_PROP 1 3" >> "$SUS_REDIRECT_FILE"
        fi
    fi
fi
