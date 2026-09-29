SKIPUNZIP=0

ui_print "************************************************"
ui_print "*        Xiaomi.eu Cloak & VNeID Fix v1.1      *"
ui_print "*         Safe Boot-Completed Protection       *"
ui_print "************************************************"

# 1. Nhan dien thiet bi va ma may dong (Bao toan duoi _global neu co)
CURR_DEVICE=$(getprop ro.product.device)
[ -z "$CURR_DEVICE" ] && CURR_DEVICE=$(getprop ro.product.name)
[ -z "$CURR_DEVICE" ] && CURR_DEVICE=$(getprop ro.build.product)
CURR_MOD_DEV=$(getprop ro.product.mod_device)
# Chi xoa chu _xiaomieu hoac _eu, GIU NGUYEN chuoi _global de khong loi song/modem
CLEAN_MOD_DEV=$(echo "$CURR_MOD_DEV" | sed -E 's/_(xiaomieu|eu)//g')
[ -z "$CLEAN_MOD_DEV" ] && CLEAN_MOD_DEV="$CURR_DEVICE"

ui_print "- Thiet bi: $CURR_DEVICE"
ui_print "- Mod Device: $CURR_MOD_DEV -> Sach: $CLEAN_MOD_DEV"
ui_print "- Kernel: $(uname -r)"

# 2. Kiem tra ho tro SuSFS o cap kernel
if [ -d "/sys/fs/susfs" ]; then
    ui_print "- SuSFS: DA HO TRO (Kernel co SuSFS) [OK]"
else
    ui_print "- SuSFS: Khong tim thay /sys/fs/susfs (Chay che do property cloak)"
fi

# 3. Tao clean_build.prop dong tu /system/build.prop cua thiet bi
ui_print "- Dang tao clean_build.prop tu he thong..."
SRC_PROP=""
if [ -f "/system/build.prop" ]; then
    SRC_PROP="/system/build.prop"
elif [ -f "/system/system/build.prop" ]; then
    SRC_PROP="/system/system/build.prop"
fi

if [ -n "$SRC_PROP" ]; then
    sed -e "s/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/" \
        -e "/# ADDED BY XIAOMI\.EU/d" \
        -e "/MIUIOS\.CZ/d" \
        -e "/MIUIPOLSKA\.PL/d" \
        -e "/^ro\.xiaomi\.developerid=/d" \
        -e "/^ro\.xiaomi\.eu\./d" \
        -e "s/_xiaomieu//g" \
        "$SRC_PROP" > "$MODPATH/clean_build.prop"
    chmod 644 "$MODPATH/clean_build.prop"
    chcon u:object_r:system_file:s0 "$MODPATH/clean_build.prop" 2>/dev/null || true
    ui_print "  -> Da loai bo cac chu ky xiaomi.eu trong build.prop [OK]"
fi

# 4. Dong bo quy tac an toan vao susfs4ksu (neu co module)
if [ -d "/data/adb/susfs4ksu" ]; then
    ui_print "- Dang dong bo quy tac an toan vao susfs4ksu..."
    SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
    SUS_REDIRECT_FILE="/data/adb/susfs4ksu/sus_open_redirect.txt"
    
    for p in "/product/priv-app/XiaomiEUExt" \
             "/product/priv-app/XiaomiEUExt/XiaomiEUExt.apk" \
             "/product/priv-app/MiuiExtraPhoto" \
             "/product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk"; do
        if [ -e "$p" ] && ! grep -q "$p" "$SUS_PATH_FILE" 2>/dev/null; then
            echo "$p" >> "$SUS_PATH_FILE"
            ui_print "  + Da them sus_path: $p"
        fi
    done

    cp -f "$MODPATH/clean_build.prop" /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
    chmod 644 /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
    chcon u:object_r:system_file:s0 /data/adb/susfs4ksu/clean_build.prop 2>/dev/null || true
fi

# 5. Don dep script cu neu co
rm -f /data/adb/service.d/hide_custom_rom.sh 2>/dev/null || true

# Phan quyen thuc thi (khong co post-fs-data de tuyet doi khong bootloop)
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Cai dat hoan tat! An toan 100% cho he thong. *"
ui_print "************************************************"
