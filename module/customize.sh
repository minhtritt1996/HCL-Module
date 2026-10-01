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

if [ -n "$(getprop ro.miui.ui.version.name)" ] ||    [ -n "$(getprop ro.miui.version.code_time)" ] ||    [ -n "$(getprop ro.miui.ui.version.code)" ] ||    [ -f "/system/framework/framework-ext-res.apk" ] ||    [ -d "/system/priv-app/miui" ] ||    [ -d "/system/priv-app/MiuiHome" ]; then
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
        sed             -e '/^ro\.xiaomi\.developerid=/d'             -e '/^ro\.xiaomi\.eu\./d'             -e '/^ro\.\(tn\|hypertn\|eliterom\|mipa\|pulse\)\./d'             -e '/^ro\.modversion=/d'             "$SRC_PROP" > "$MODPATH/compat_build.prop"
    else
        sed             -e '/^ro\.\(lineage\|crdroid\|evolution\|pixelexperience\|havoc\|derp\|paranoid\)\./d'             -e '/^ro\.modversion=/d'             "$SRC_PROP" > "$MODPATH/compat_build.prop"
    fi

    chmod 0644 "$MODPATH/compat_build.prop"
    chcon u:object_r:system_file:s0 "$MODPATH/compat_build.prop" 2>/dev/null || true
    cp -f "$MODPATH/compat_build.prop" "$MODPATH/clean_build.prop" 2>/dev/null || true
    ui_print "- Compatibility build.prop generated [OK]"
else
    ui_print "- build.prop source not found; property compatibility view disabled"
fi

# 3. Discover optional ROM component paths.
: > "$MODPATH/compat_isolated_components.txt"

add_component() {
    path="$1"
    [ -e "$path" ] || return 0
    grep -Fxq "$path" "$MODPATH/compat_isolated_components.txt" 2>/dev/null ||         printf '%s\n' "$path" >> "$MODPATH/compat_isolated_components.txt"
}

if [ "$ROM_ENV" = "hyperos" ]; then
    for base in /product/priv-app /product/app /system_ext/priv-app /system_ext/app /system/priv-app /system/app; do
        [ -d "$base" ] || continue
        find "$base" -maxdepth 2 -type d \(             -iname "*xiaomieu*" -o             -iname "*extraphoto*" -o             -iname "*hypertn*" -o             -iname "*tntoolbox*" -o             -iname "*eliterom*" -o             -iname "*mipa*" -o             -iname "*pulse*"         \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
        done
    done
else
    for base in /product/app /product/priv-app /system_ext/app /system_ext/priv-app /system/app /system/priv-app; do
        [ -d "$base" ] || continue
        find "$base" -maxdepth 2 -type d \(             -iname "*lineage.updater*" -o             -iname "*crdroid.updater*"         \) 2>/dev/null | while IFS= read -r item; do
            add_component "$item"
        done
    done
fi

# addon.d is tracked as a whole directory so uninstall can remove only our entries.
for addond in /system/addon.d /system/system/addon.d /system_ext/addon.d /product/addon.d; do
    add_component "$addond"
done

cp -f "$MODPATH/compat_isolated_components.txt" "$MODPATH/owned_sus_paths.txt" 2>/dev/null || true
rm -f "$MODPATH/detected_paths.txt" 2>/dev/null || true

# No direct writes to shared SuSFS configuration are performed during install.
# service.sh applies runtime rules only after boot completion.

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

ui_print "************************************************"
ui_print "* Installation complete. Compatibility ready. *"
ui_print "************************************************"
