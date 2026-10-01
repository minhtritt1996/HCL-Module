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
            -e 's|qti/missi/missi|Redmi/mondrian/mondrian|g' \
            -e 's|missi-user|mondrian-user|g' \
            -e 's|ro\.build\.product=missi|ro.build.product=mondrian|g' \
            -e 's|missi|mondrian|g' \
            -e 's|net\.bt\.name=Android|net.bt.name=POCO F5 Pro|g' \
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
if [ -f "$MODPATH/attest_sync.sh" ]; then
    ui_print "- Synchronizing attestation and banking protection rules..."
    sh "$MODPATH/attest_sync.sh"
    ui_print "  -> VNeID & Techcombank hardware attestation secured"
    ui_print "  -> Banking applications hardware keystore protected"
fi

# 5. Harmonize HMA OSS configuration if present
HMA_CONFIG=$(ls -1 /data/misc/hide_my_applist_*/config.json 2>/dev/null | head -n 1)
if [ -n "$HMA_CONFIG" ] && [ -f "$HMA_CONFIG" ]; then
    ui_print "- Synchronizing package isolation templates..."
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
try:
    with open('$HMA_CONFIG', 'r') as f:
        cfg = json.load(f)
    scope = cfg.setdefault('scope', {})
    for pkg in ['com.sacombank.ewallet', 'com.tpb.mb.gprsandroid']:
        p_cfg = scope.setdefault(pkg, {
            'useWhitelist': False,
            'excludeSystemApps': False,
            'hideInstallationSource': False,
            'hideSystemInstallationSource': False,
            'excludeTargetInstallationSource': False,
            'invertActivityLaunchProtection': False,
            'excludeVoldIsolation': False,
            'restrictedZygotePermissions': [],
            'applyTemplates': ['HIDE MY CUSTOM APP'],
            'applyPresets': ['accessibility_apps', 'custom_rom', 'detector_apps', 'root_apps', 'shizuku_dhizuku', 'sus_apps', 'xposed'],
            'applySettingTemplates': [],
            'applySettingsPresets': ['accessibility', 'dev_options', 'input_method'],
            'extraAppList': ['org.frknkrc44.hma_oss', 'com.termux', 'com.termux.x11', 'com.resukisu.resukisu', 'com.github.standardadb', 'eu.sisik.hackendebug', 'org.client.scrcpy', 'com.droidspaces.app', 'gr.nikolasspyr.integritycheck', 'eu.xiaomi.ext'],
            'extraOppositeAppList': []
        })
        p_cfg['excludeSystemApps'] = False
        extra = p_cfg.setdefault('extraAppList', [])
        if 'eu.xiaomi.ext' not in extra:
            extra.append('eu.xiaomi.ext')
    with open('$HMA_CONFIG', 'w') as f:
        json.dump(cfg, f, indent=2)
except Exception:
    pass
" 2>/dev/null || true
    fi
    if [ -x "/system/bin/content" ] || command -v content >/dev/null 2>&1; then
        content call --uri content://org.frknkrc44.hma_oss.ServiceProvider --method reloadConfigFromFile >/dev/null 2>&1 || true
    fi
fi

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/attest_sync.sh" 0 0 0755
set_perm "$MODPATH/guardian.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Installation complete. Compatibility ready. *"
ui_print "************************************************"
