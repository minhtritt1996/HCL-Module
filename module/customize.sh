SKIPUNZIP=0

ui_print "************************************************"
ui_print "*       HyperOS Compatibility Layer v1.4       *"
ui_print "*    System Normalization & ROM Environment    *"
ui_print "************************************************"

# Legacy module migration is intentionally non-destructive.
LEGACY_MOD_DIR="/data/adb/modules/xiaomieu_vneid_cloak"
if [ -d "$LEGACY_MOD_DIR" ]; then
    ui_print "- Legacy module detected: xiaomieu_vneid_cloak"
    ui_print "  -> It will not be deleted automatically."
fi

# 1. Detect the ROM profile dynamically during installation.
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

DEVICE=$(getprop ro.product.vendor.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.name)

MODEL=$(getprop ro.product.vendor.model)
[ -z "$MODEL" ] && MODEL=$(getprop ro.product.odm.model)
[ -z "$MODEL" ] && MODEL=$(getprop ro.product.model)
[ -z "$MODEL" ] && MODEL="$DEVICE"

BRAND=$(getprop ro.product.vendor.brand)
[ -z "$BRAND" ] && BRAND=$(getprop ro.product.brand)
[ -z "$BRAND" ] && BRAND="Xiaomi"

ui_print "- ROM: $ROM_NAME [$ROM_ENV]"
ui_print "- Device: $DEVICE ($MODEL)"
ui_print "- Kernel: $(uname -r)"

# 2. Build a compatibility view dynamically without modifying physical system files.
SRC_PROP=""
if [ -f "/system/build.prop" ]; then
    SRC_PROP="/system/build.prop"
elif [ -f "/system/system/build.prop" ]; then
    SRC_PROP="/system/system/build.prop"
fi

if [ -n "$SRC_PROP" ]; then
    if [ "$ROM_ENV" = "hyperos" ]; then
        sed \
            -e '/^#.*xiaomi\.eu/Id' \
            -e '/^ro\.xiaomi\.developerid=/d' \
            -e '/^ro\.xiaomi\.eu\./d' \
            -e '/^ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\)\./d' \
            -e '/^ro\.modversion=/d' \
            -e "s|ro\.product\.mod_device=[^ ]*_xiaomieu|ro.product.mod_device=${DEVICE}|g" \
            -e "s|ro\.product\.mod_device=[^ ]*_eu|ro.product.mod_device=${DEVICE}|g" \
            -e "s|qti/missi/missi|${BRAND}/${DEVICE}/${DEVICE}|g" \
            -e "s|missi-user|${DEVICE}-user|g" \
            -e "s|ro\.build\.product=missi|ro.build.product=${DEVICE}|g" \
            -e "s|missi|${DEVICE}|g" \
            -e "s|qssi system image for arm64|${MODEL}|g" \
            -e "s|net\.bt\.name=Android|net.bt.name=${MODEL}|g" \
            -e "s|ro\.product\.system\.brand=Android|ro.product.system.brand=${BRAND}|g" \
            -e "s|ro\.product\.system\.device=generic|ro.product.system.device=${DEVICE}|g" \
            -e "s|ro\.product\.system\.model=mainline|ro.product.system.model=${MODEL}|g" \
            -e "s|ro\.product\.system\.name=mainline|ro.product.system.name=${DEVICE}|g" \
            -e 's|ro\.vendor\.qti\.va_aosp\.support=1|ro.vendor.qti.va_aosp.support=0|g' \
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
    ui_print "- Dynamic compatibility build.prop generated [OK]"
else
    ui_print "- build.prop source not found; property compatibility view disabled"
fi

# 3. Discover optional ROM component paths (directories and individual APKs).
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

    for fallback in \
        /product/priv-app/XiaomiEUExt \
        /product/priv-app/XiaomiEUExt/XiaomiEUExt.apk \
        /product/app/XiaomiEUInject \
        /product/app/XiaomiEUInject/XiaomiEUInject.apk \
        /system_ext/app/XiaomiEUInject \
        /system_ext/app/XiaomiEUInject/XiaomiEUInject.apk \
        /system/app/XiaomiEUInject \
        /system/app/XiaomiEUInject/XiaomiEUInject.apk \
        /product/priv-app/MiuiExtraPhoto \
        /product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk; do
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

for addond in /system/addon.d /system/system/addon.d /system_ext/addon.d /product/addon.d; do
    if [ -d "$addond" ] || [ -e "$addond" ]; then
        add_component "$addond"
        for script in "$addond"/*; do
            [ -e "$script" ] && add_component "$script"
        done
    fi
done

cp -f "$MODPATH/compat_isolated_components.txt" "$MODPATH/owned_sus_paths.txt" 2>/dev/null || true
rm -f "$MODPATH/detected_paths.txt" 2>/dev/null || true

# Prepare shared SuSFS redirection target safely
if [ -f "$MODPATH/compat_build.prop" ]; then
    if [ -d "/mnt/vendor/susfs4ksu" ] || mkdir -p /mnt/vendor/susfs4ksu 2>/dev/null; then
        cp -f "$MODPATH/compat_build.prop" /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chmod 0644 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chcon u:object_r:system_file:s0 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
    fi
    if [ -f "/data/adb/susfs4ksu/sus_open_redirect.txt" ]; then
        sed -i '/\/data\/adb\/susfs4ksu\/compat_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
        sed -i '/\/data\/adb\/susfs4ksu\/clean_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
    fi
fi

# 4. Initialize module configuration storage
CONF_DIR="/data/adb/hyperos_compat"
mkdir -p "$CONF_DIR" 2>/dev/null || true
if [ ! -f "$CONF_DIR/config.json" ] && [ -f "$MODPATH/config.json" ]; then
    cp -f "$MODPATH/config.json" "$CONF_DIR/config.json" 2>/dev/null || true
fi

# 5. Harmonize with attestation managers (tricky_store / AlwaysStrong / TEESimulator)
if [ -f "$MODPATH/attest_sync.sh" ]; then
    ui_print "- Synchronizing attestation and keystore protection rules..."
    sh "$MODPATH/attest_sync.sh"
    ui_print "  -> Keystore and attestation rules aligned"
fi

# 6. Set file permissions cleanly
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/attest_sync.sh" 0 0 0755
set_perm "$MODPATH/guardian.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

if [ -d "$MODPATH/scripts" ]; then
    for s in "$MODPATH/scripts/"*.sh; do
        [ -f "$s" ] && set_perm "$s" 0 0 0755
    done
fi

ui_print "************************************************"
ui_print "* Installation complete. Compatibility ready. *"
ui_print "************************************************"
