SKIPUNZIP=0

ui_print "************************************************"
ui_print "*       HyperOS Compatibility Layer v1.3       *"
ui_print "*    System Normalization & ROM Environment    *"
ui_print "************************************************"

# 0. Kiem tra va di chuyen tu module cu (Legacy Module Migration)
LEGACY_MOD_DIR="/data/adb/modules/xiaomieu_vneid_cloak"
if [ -d "$LEGACY_MOD_DIR" ]; then
    ui_print "- Phat hien phien ban module tien nhiem (v1.2.x)..."
    # Vo hieu hoa ngay uninstall script de tranh bi go sach sus_path.txt tren lan khoi dong ke tiep
    rm -f "$LEGACY_MOD_DIR/uninstall.sh" 2>/dev/null || true
    rm -rf "$LEGACY_MOD_DIR" 2>/dev/null || true
    ui_print "  -> Da di chuyen va don dep module cu hoan tat [OK]"
fi

# 1. Nhan dien thiet bi va moi truong he dieu hanh (Smart Environment Detection)
ROM_ENV="aosp"
ROM_NAME="Generic AOSP / Custom ROM"

if [ -n "$(getprop ro.miui.ui.version.name)" ] || \
   [ -n "$(getprop ro.miui.version.code_time)" ] || \
   [ -n "$(getprop ro.miui.ui.version.code)" ] || \
   [ -f "/system/framework/framework-ext-res.apk" ] || \
   [ -d "/system/priv-app/miui" ] || \
   [ -d "/system/priv-app/MiuiHome" ]; then
    ROM_ENV="hyperos"
    ROM_NAME="Xiaomi HyperOS / MIUI"
elif [ -n "$(getprop ro.lineage.version)" ]; then
    ROM_NAME="LineageOS ($(getprop ro.lineage.version))"
elif [ -n "$(getprop ro.crdroid.version)" ]; then
    ROM_NAME="crDroid ($(getprop ro.crdroid.version))"
elif [ -n "$(getprop ro.pixelexperience.version)" ]; then
    ROM_NAME="PixelExperience"
elif [ -n "$(getprop ro.evolution.version)" ]; then
    ROM_NAME="EvolutionX"
fi

echo "$ROM_ENV" > "$MODPATH/rom_env.txt"

HYPEROS_DEVICE=$(getprop ro.product.device)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.product.name)
[ -z "$HYPEROS_DEVICE" ] && HYPEROS_DEVICE=$(getprop ro.build.product)

HYPEROS_RAW_MOD_DEVICE=$(getprop ro.product.mod_device)

ui_print "- Moi truong ROM: $ROM_NAME [$ROM_ENV]"
ui_print "- Thiet bi: $HYPEROS_DEVICE"

if [ "$ROM_ENV" = "hyperos" ]; then
    # Chuan hoa ro.product.mod_device ve ma may chuan cua Xiaomi
    if echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_in_global"; then
        HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_in_global"
    elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_ru_global"; then
        HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_ru_global"
    elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_eea_global"; then
        HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_eea_global"
    elif echo "$HYPEROS_RAW_MOD_DEVICE" | grep -qi "_global"; then
        HYPEROS_NORM_MOD_DEVICE="${HYPEROS_DEVICE}_global"
    elif [ -n "$HYPEROS_RAW_MOD_DEVICE" ]; then
        HYPEROS_NORM_MOD_DEVICE=$(echo "$HYPEROS_RAW_MOD_DEVICE" | sed -e 's/_\(xiaomieu\|eu\|hypertn\|tn\|elite\|eliterom\|mipa\|pulse\|mod\|custom\)//g')
        [ -z "$HYPEROS_NORM_MOD_DEVICE" ] && HYPEROS_NORM_MOD_DEVICE="$HYPEROS_DEVICE"
    else
        HYPEROS_NORM_MOD_DEVICE="$HYPEROS_DEVICE"
    fi

    ui_print "- Mod Device goc: $HYPEROS_RAW_MOD_DEVICE"
    ui_print "- Mod Device chuan hoa: $HYPEROS_NORM_MOD_DEVICE"
else
    ui_print "- Ho so: AOSP Normalization (khong can thiep vao Xiaomi properties)"
fi
ui_print "- Kernel: $(uname -r)"

# 2. Kiem tra ho tro SuSFS o cap kernel
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

SUSFS_VER=""
if [ -n "$SUSFS_BIN" ] && [ -x "$SUSFS_BIN" ]; then
    SUSFS_VER=$($SUSFS_BIN show version 2>/dev/null)
fi

if [ -n "$SUSFS_VER" ]; then
    ui_print "- SuSFS: DA HO TRO (Kernel SuSFS $SUSFS_VER) [OK]"
else
    ui_print "- SuSFS: Khong tim thay SuSFS kernel (Chay che do chuan hoa property)"
fi

# 3. Tao compat_build.prop dong tu /system/build.prop cua thiet bi
ui_print "- Dang tao compat_build.prop tu he thong..."
SRC_PROP=""
if [ -f "/system/build.prop" ]; then
    SRC_PROP="/system/build.prop"
elif [ -f "/system/system/build.prop" ]; then
    SRC_PROP="/system/system/build.prop"
fi

if [ -n "$SRC_PROP" ]; then
    if [ "$ROM_ENV" = "hyperos" ]; then
        sed \
            -e 's/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/' \
            -e 's/^ro\.build\.type=userdebug/ro.build.type=user/' \
            -e 's/^ro\.debuggable=1/ro.debuggable=0/' \
            -e "s/^ro\.product\.mod_device=.*/ro.product.mod_device=$HYPEROS_NORM_MOD_DEVICE/" \
            -e '/# ADDED BY/d' \
            -e '/MIUIOS\.CZ/d' \
            -e '/MIUIPOLSKA\.PL/d' \
            -e '/ro\.xiaomi\.developerid/d' \
            -e '/ro\.xiaomi\.eu/d' \
            -e '/ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\)\./d' \
            -e '/ro\.modversion/d' \
            -e 's/_\(xiaomieu\|eu\|hypertn\|elite\|mipa\|pulse\)//g' \
            "$SRC_PROP" > "$MODPATH/compat_build.prop"
    else
        # Profile AOSP: Chi loai bo cac co custom ROM, khong cấy gia tri cua Xiaomi
        sed \
            -e 's/^ro\.build\.type=userdebug/ro.build.type=user/' \
            -e 's/^ro\.debuggable=1/ro.debuggable=0/' \
            -e '/ro\.\(lineage\|crdroid\|evolution\|pixelexperience\|havoc\|derp\|paranoid\)\./d' \
            -e '/ro\.modversion/d' \
            "$SRC_PROP" > "$MODPATH/compat_build.prop"
    fi
    chmod 644 "$MODPATH/compat_build.prop"
    chcon u:object_r:system_file:s0 "$MODPATH/compat_build.prop" 2>/dev/null || true
    # Giu alias clean_build.prop cho tuong thich nguoc
    cp -f "$MODPATH/compat_build.prop" "$MODPATH/clean_build.prop" 2>/dev/null || true
    ui_print "  -> Da chuan hoa thong so ROM trong build.prop [OK]"
fi

# 4. Quet dong toan bo cac APK phu tro ROM mod trong cac phan vung he thong
ROM_COMPONENT_PATHS=""
if [ "$ROM_ENV" = "hyperos" ]; then
    ui_print "- Dang quet dong cac thanh phan ROM mod Xiaomi (Xiaomi.eu, HyperTN, Elite, Port)..."
    for base in "/product/priv-app" "/system_ext/priv-app" "/system/priv-app"; do
        if [ -d "$base" ]; then
            matched=$(find "$base" -maxdepth 2 \( \
                -iname "*xiaomieu*" -o \
                -iname "*extraphoto*" -o \
                -iname "*hypertn*" -o \
                -iname "*tntoolbox*" -o \
                -iname "*eliterom*" -o \
                -iname "*mipa*" \
            \) 2>/dev/null)
            if [ -n "$matched" ]; then
                for item in $matched; do
                    ROM_COMPONENT_PATHS="$ROM_COMPONENT_PATHS $item"
                done
            fi
        fi
    done
else
    ui_print "- Dang quet dong cac thanh phan can cach ly tren AOSP/LineageOS..."
    for base in "/product/app" "/product/priv-app" "/system_ext/priv-app" "/system/priv-app"; do
        if [ -d "$base" ]; then
            matched=$(find "$base" -maxdepth 2 \( \
                -iname "*lineage.updater*" -o \
                -iname "*crdroid.updater*" \
            \) 2>/dev/null)
            if [ -n "$matched" ]; then
                for item in $matched; do
                    ROM_COMPONENT_PATHS="$ROM_COMPONENT_PATHS $item"
                done
            fi
        fi
    done
fi

# Luu danh sach path da quet duoc de service.sh su dung
rm -f "$MODPATH/compat_isolated_components.txt" "$MODPATH/detected_paths.txt"
for p in $ROM_COMPONENT_PATHS; do
    echo "$p" >> "$MODPATH/compat_isolated_components.txt"
    echo "$p" >> "$MODPATH/detected_paths.txt"
    ui_print "  + Phat hien thanh phan can cach ly: $p"
done

# Dong bo vao susfs4ksu neu co
if [ -d "/data/adb/susfs4ksu" ]; then
    ui_print "- Dang dong bo quy tac vao susfs4ksu..."
    SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
    
    if [ -f "$MODPATH/compat_isolated_components.txt" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            if [ -e "$p" ] && ! grep -q "$p" "$SUS_PATH_FILE" 2>/dev/null; then
                echo "$p" >> "$SUS_PATH_FILE"
            fi
        done < "$MODPATH/compat_isolated_components.txt"
    fi

    cp -f "$MODPATH/compat_build.prop" /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true
    chmod 644 /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true
    chcon u:object_r:system_file:s0 /data/adb/susfs4ksu/compat_build.prop 2>/dev/null || true
    # Legacy sync
    cp -f "$MODPATH/compat_build.prop" /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true

    SUS_REDIRECT_FILE="/data/adb/susfs4ksu/sus_open_redirect.txt"
    if [ -f "$SUS_REDIRECT_FILE" ]; then
        if ! grep -q "compat_build\.prop" "$SUS_REDIRECT_FILE" 2>/dev/null; then
            echo "/system/build.prop /data/adb/susfs4ksu/compat_build.prop 1 3" >> "$SUS_REDIRECT_FILE"
        fi
    fi
fi

# 5. Don dep script cu neu co
rm -f /data/adb/service.d/hide_custom_rom.sh 2>/dev/null || true

# Phan quyen thuc thi (khong dung post-fs-data de an toan tuyet doi cho modem)
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Cai dat hoan tat! Thiet lap tuong thich xong. *"
ui_print "************************************************"
