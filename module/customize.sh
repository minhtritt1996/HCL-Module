SKIPUNZIP=0

ui_print "************************************************"
ui_print "*     Universal ROM Cloak & VNeID Fix v1.2     *"
ui_print "*       Dynamic Scan & Safe Boot Protection    *"
ui_print "************************************************"

# 1. Nhan dien thiet bi va chuan hoa ma may (Bao toan duoi khu vuc _global/_in...)
CURR_DEVICE=$(getprop ro.product.device)
[ -z "$CURR_DEVICE" ] && CURR_DEVICE=$(getprop ro.product.name)
[ -z "$CURR_DEVICE" ] && CURR_DEVICE=$(getprop ro.build.product)

CURR_MOD_DEV=$(getprop ro.product.mod_device)

# Chuan hoa ro.product.mod_device ve ma may chuan cua Xiaomi
if echo "$CURR_MOD_DEV" | grep -qi "_in_global"; then
    CLEAN_MOD_DEV="${CURR_DEVICE}_in_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_ru_global"; then
    CLEAN_MOD_DEV="${CURR_DEVICE}_ru_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_eea_global"; then
    CLEAN_MOD_DEV="${CURR_DEVICE}_eea_global"
elif echo "$CURR_MOD_DEV" | grep -qi "_global"; then
    CLEAN_MOD_DEV="${CURR_DEVICE}_global"
elif [ -n "$CURR_MOD_DEV" ]; then
    CLEAN_MOD_DEV=$(echo "$CURR_MOD_DEV" | sed -e 's/_\(xiaomieu\|eu\|hypertn\|tn\|elite\|eliterom\|mipa\|pulse\|mod\|custom\)//g')
    [ -z "$CLEAN_MOD_DEV" ] && CLEAN_MOD_DEV="$CURR_DEVICE"
else
    CLEAN_MOD_DEV="$CURR_DEVICE"
fi

ui_print "- Thiet bi: $CURR_DEVICE"
ui_print "- Mod Device goc: $CURR_MOD_DEV"
ui_print "- Mod Device chuan hoa: $CLEAN_MOD_DEV"
ui_print "- Kernel: $(uname -r)"

# 2. Kiem tra ho tro SuSFS o cap kernel
if [ -d "/sys/fs/susfs" ]; then
    ui_print "- SuSFS: DA HO TRO (Kernel co SuSFS) [OK]"
else
    ui_print "- SuSFS: Khong tim thay /sys/fs/susfs (Chay che do property cloak)"
fi

# 3. Tao clean_build.prop dong tu /system/build.prop cua thiet bi
ui_print "- Dang tao clean_build.prop dong tu he thong..."
SRC_PROP=""
if [ -f "/system/build.prop" ]; then
    SRC_PROP="/system/build.prop"
elif [ -f "/system/system/build.prop" ]; then
    SRC_PROP="/system/system/build.prop"
fi

if [ -n "$SRC_PROP" ]; then
    sed \
        -e 's/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/' \
        -e 's/^ro\.build\.type=userdebug/ro.build.type=user/' \
        -e 's/^ro\.debuggable=1/ro.debuggable=0/' \
        -e "s/^ro\.product\.mod_device=.*/ro.product.mod_device=$CLEAN_MOD_DEV/" \
        -e '/# ADDED BY/d' \
        -e '/MIUIOS\.CZ/d' \
        -e '/MIUIPOLSKA\.PL/d' \
        -e '/ro\.xiaomi\.developerid/d' \
        -e '/ro\.xiaomi\.eu/d' \
        -e '/ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\|lineage\|crdroid\)\./d' \
        -e '/ro\.modversion/d' \
        -e 's/_\(xiaomieu\|eu\|hypertn\|elite\|mipa\|pulse\)//g' \
        "$SRC_PROP" > "$MODPATH/clean_build.prop"
    chmod 644 "$MODPATH/clean_build.prop"
    chcon u:object_r:system_file:s0 "$MODPATH/clean_build.prop" 2>/dev/null || true
    ui_print "  -> Da loai bo cac chu ky ROM mod trong build.prop [OK]"
fi

# 4. Quet dong toan bo cac APK mod la trong cac phan vung he thong
ui_print "- Dang quet dong cac priv-app la (Xiaomi.eu, HyperTN, Elite, Port)..."
FOUND_PATHS=""
for base in "/product/priv-app" "/system_ext/priv-app" "/system/priv-app"; do
    if [ -d "$base" ]; then
        matched=$(find "$base" -maxdepth 2 \( \
            -iname "*xiaomieu*" -o \
            -iname "*extraphoto*" -o \
            -iname "*hypertn*" -o \
            -iname "*tntoolbox*" -o \
            -iname "*eliterom*" -o \
            -iname "*mipa*" -o \
            -iname "*lineageparts*" \
        \) 2>/dev/null)
        if [ -n "$matched" ]; then
            for item in $matched; do
                FOUND_PATHS="$FOUND_PATHS $item"
            done
        fi
    fi
done

# Luu danh sach path da quet duoc de service.sh su dung
rm -f "$MODPATH/detected_paths.txt"
for p in $FOUND_PATHS; do
    echo "$p" >> "$MODPATH/detected_paths.txt"
    ui_print "  + Phat hien priv-app can an: $p"
done

# Dong bo vao susfs4ksu neu co
if [ -d "/data/adb/susfs4ksu" ]; then
    ui_print "- Dang dong bo quy tac vao susfs4ksu..."
    SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
    
    if [ -f "$MODPATH/detected_paths.txt" ]; then
        while read -r p; do
            [ -z "$p" ] && continue
            if [ -e "$p" ] && ! grep -q "$p" "$SUS_PATH_FILE" 2>/dev/null; then
                echo "$p" >> "$SUS_PATH_FILE"
            fi
        done < "$MODPATH/detected_paths.txt"
    fi

    cp -f "$MODPATH/clean_build.prop" /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
    chmod 644 /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
    chcon u:object_r:system_file:s0 /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
fi

# 5. Don dep script cu neu co
rm -f /data/adb/service.d/hide_custom_rom.sh 2>/dev/null || true

# Phan quyen thuc thi (khong dung post-fs-data de an toan tuyet doi cho modem)
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Cai dat hoan tat! Tu dong thich ung moi ROM. *"
ui_print "************************************************"
