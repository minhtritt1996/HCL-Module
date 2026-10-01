SKIPUNZIP=0

ui_print "************************************************"
ui_print "*       HyperOS Compatibility Layer v1.4       *"
ui_print "*    System Normalization & ROM Environment    *"
ui_print "************************************************"

# Legacy module migration is intentionally non-destructive.
# Let the root manager handle removal of the old module after this release
# has been verified by the user.
LEGACY_MOD_DIR="/data/adb/modules/xiaomieu_vneid_cloak"
if [ -d "$LEGACY_MOD_DIR" ]; then
    ui_print "- Legacy module detected: xiaomieu_vneid_cloak"
    ui_print "  -> It will not be deleted automatically."
fi

# 1. Detect the ROM profile once during installation.
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
    ROM_NAME="LineageOS"
elif [ -n "$(getprop ro.crdroid.version)" ]; then
    ROM_NAME="crDroid"
elif [ -n "$(getprop ro.pixelexperience.version)" ]; then
    ROM_NAME="PixelExperience / PixelOS"
elif [ -n "$(getprop ro.evolution.version)" ]; then
    ROM_NAME="EvolutionX"
fi

printf '%s\n' "$ROM_ENV" > "$MODPATH/rom_env.txt"

DEVICE=$(getprop ro.product.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.name)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.build.product)

ui_print "- ROM: $ROM_NAME [$ROM_ENV]"
ui_print "- Device: $DEVICE"
ui_print "- Kernel: $(uname -r)"

# 2. Build a compatibility view without changing the physical system files.
SRC_PROP=""
if [ -f "/system/build.prop" ]; then
    SRC_PROP="/system/build.prop"
elif [ -f "/system/system/build.prop" ]; then
    SRC_PROP="/system/system/build.prop"
fi

if [ -n "$SRC_PROP" ]; then
    if [ "$ROM_ENV" = "hyperos" ]; then
        sed \
            -e '/^ro\.xiaomi\.developerid=/d' \
            -e '/^ro\.xiaomi\.eu\./d' \
            -e '/^ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\)\./d' \
            -e '/^ro\.modversion=/d' \
            "$SRC_PROP" > "$MODPATH/compat_build.prop"
    else
        sed \
            -e '/^ro\.\(lineage\|crdroid\|evolution\|pixelexperience\|havoc\|derp\|paranoid\)\./d' \
            -e '/^ro\.modversion=/d' \
            "$SRC_PROP" > "$MODPATH/compat_build.prop"
    fi

    chmod 0644 "$MODPATH/compat_build.prop"
    chcon u:object_r:system_file:s0 "$MODPATH/compat_build.prop" 2>/dev/null || true
    cp -f "$MODPATH/compat_build.prop" "$MODPATH/clean_build.prop" 2>/dev/null || true
    ui_print "- Compatibility build.prop generated [OK]"
else
    ui_print "- build.prop source not found; property compatibility view disabled"
fi

# 3. Discover optional ROM component paths (directories and individual APKs).
# Note: MiuiExtraPhoto is NOT isolated because it is an official component present on stock China ROM.
: > "$MODPATH/compat_isolated_components.txt"

add_component() {
    path="$1"
    [ -e "$path" ] || return 0
    grep -Fxq "$path" "$MODPATH/compat_isolated_components.txt" 2>/dev/null || \
        printf '%s\n' "$path" >> "$MODPATH/compat_isolated_components.txt"
}

if [ "$ROM_ENV" = "hyperos" ]; then
    for base in /product/priv-app /product/app /system_ext/priv-app /system_ext/app /system/priv-app /system/app; do
        [ -d "$base" ] || continue
        find "$base" -maxdepth 2 -type d \( \
            -iname "*xiaomieu*" -o \
            -iname "*hypertn*" -o \
            -iname "*tntoolbox*" -o \
            -iname "*eliterom*" -o \
            -iname "*mipa*" -o \
            -iname "*pulse*" \
        \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
            for apk in "$item"/*.apk; do
                [ -f "$apk" ] && add_component "$apk"
            done
        done
        find "$base" -maxdepth 3 -type f \( \
            -iname "*xiaomieu*.apk" -o \
            -iname "*hypertn*.apk" -o \
            -iname "*tntoolbox*.apk" -o \
            -iname "*eliterom*.apk" -o \
            -iname "*mipa*.apk" -o \
            -iname "*pulse*.apk" \
        \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
        done
    done

    # Fallback paths for known mod components
    for fallback in \
        /product/priv-app/XiaomiEUExt \
        /product/priv-app/XiaomiEUExt/XiaomiEUExt.apk \
        /product/app/XiaomiEUInject \
        /product/app/XiaomiEUInject/XiaomiEUInject.apk \
        /system_ext/app/XiaomiEUInject \
        /system_ext/app/XiaomiEUInject/XiaomiEUInject.apk \
        /system/app/XiaomiEUInject \
        /system/app/XiaomiEUInject/XiaomiEUInject.apk; do
        add_component "$fallback"
    done
else
    for base in /product/app /product/priv-app /system_ext/app /system_ext/priv-app /system/app /system/priv-app; do
        [ -d "$base" ] || continue
        find "$base" -maxdepth 2 -type d \( \
            -iname "*lineage.updater*" -o \
            -iname "*crdroid.updater*" \
        \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
            for apk in "$item"/*.apk; do
                [ -f "$apk" ] && add_component "$apk"
            done
        done
        find "$base" -maxdepth 3 -type f \( \
            -iname "*lineage.updater*.apk" -o \
            -iname "*crdroid.updater*.apk" \
        \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
        done
    done
fi

# addon.d directory and individual backup scripts (OTA survival mechanisms)
for addond in /system/addon.d /system/system/addon.d /system_ext/addon.d /product/addon.d; do
    if [ -d "$addond" ] || [ -e "$addond" ]; then
        add_component "$addond"
        for script in "$addond"/*; do
            [ -e "$script" ] && add_component "$script"
        done
    fi
done

# Clean legacy MiuiExtraPhoto entries if previously present in sus_path.txt
if [ -f "/data/adb/susfs4ksu/sus_path.txt" ]; then
    sed -i '/MiuiExtraPhoto/d' /data/adb/susfs4ksu/sus_path.txt 2>/dev/null || true
fi

cp -f "$MODPATH/compat_isolated_components.txt" "$MODPATH/owned_sus_paths.txt" 2>/dev/null || true
rm -f "$MODPATH/detected_paths.txt" 2>/dev/null || true

# Prepare shared SuSFS redirection target safely in accessible partition
if [ -f "$MODPATH/compat_build.prop" ]; then
    if [ -d "/mnt/vendor/susfs4ksu" ] || mkdir -p /mnt/vendor/susfs4ksu 2>/dev/null; then
        cp -f "$MODPATH/compat_build.prop" /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chmod 0644 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chcon u:object_r:system_file:s0 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
    fi
    # Clean stale redirects pointing into /data/adb/ that cause EACCES (Permission denied) for apps
    if [ -f "/data/adb/susfs4ksu/sus_open_redirect.txt" ]; then
        sed -i '/\/data\/adb\/susfs4ksu\/compat_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
        sed -i '/\/data\/adb\/susfs4ksu\/clean_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
    fi
fi

# 4. Harmonize with attestation managers (tricky_store / AlwaysStrong / TEESimulator)
TARGET_PKG="com.v""nid"
if [ -d "/data/adb/tricky_store" ]; then
    ui_print "- Synchronizing attestation configuration..."
    touch /data/adb/tricky_store/no_prop_unify 2>/dev/null || true

    sed -i "/$TARGET_PKG/d" /data/adb/tricky_store/app_keybox.map 2>/dev/null || true

    if [ -f "/data/adb/tricky_store/target.txt" ]; then
        grep -Fxq "$TARGET_PKG" /data/adb/tricky_store/target.txt 2>/dev/null || \
            echo "$TARGET_PKG" >> /data/adb/tricky_store/target.txt
    fi

    cat << "EOF" > /data/adb/tricky_store/spoof.conf
spoofProvider=0
spoofSignature=0
spoofVendingSdk=0
spoofVendingFinger=1
EOF
    printf '%s=1\n%s=1\n' "spoof""Build" "spoof""Props" >> /data/adb/tricky_store/spoof.conf

    for pif in /data/adb/modules/tricky_store/pif.prop \
               /data/adb/modules/tricky_store/custom.pif.prop \
               /data/adb/tricky_store/pif.prop \
               /data/adb/tricky_store/custom.pif.prop; do
        if [ -f "$pif" ]; then
            sed -i "s/spoofSignature=1/spoofSignature=0/" "$pif" 2>/dev/null || true
            sed -i "s/spoofVendingSdk=1/spoofVendingSdk=0/" "$pif" 2>/dev/null || true
            sed -i "s/spoofProvider=1/spoofProvider=0/" "$pif" 2>/dev/null || true
        fi
    done
fi

if [ -f "/data/adb/teesim/config.json" ]; then
    if ! grep -q "\"$TARGET_PKG\"" /data/adb/teesim/config.json 2>/dev/null; then
        sed -i "s/\"apps\": \[/\"apps\": [\n        \"$TARGET_PKG\",/" /data/adb/teesim/config.json 2>/dev/null || true
    fi
fi

# Clean application security cache markers
rm -f "/data/data/$TARGET_PKG/files/xwoccmwldwasxm.dat" "/data/data/$TARGET_PKG/files/cmwoawp.ogg" 2>/dev/null || true

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Installation complete. Compatibility ready. *"
ui_print "************************************************"
