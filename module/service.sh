#!/system/bin/sh
MODDIR=${0%/*}

# Run after Android reports boot completion.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Locate resetprop when available.
RESETPROP=""
if [ -x "/data/adb/ksu/bin/resetprop" ]; then
    RESETPROP="/data/adb/ksu/bin/resetprop"
elif [ -x "/data/adb/ap/bin/resetprop" ]; then
    RESETPROP="/data/adb/ap/bin/resetprop"
elif [ -x "/data/adb/magisk/magisk" ]; then
    RESETPROP="/data/adb/magisk/magisk --resetprop"
elif command -v resetprop >/dev/null 2>&1; then
    RESETPROP="resetprop"
fi

ROM_ENV="aosp"
if [ -f "$MODDIR/rom_env.txt" ]; then
    ROM_ENV=$(tr -d ' \r\n' < "$MODDIR/rom_env.txt")
fi

DEVICE=$(getprop ro.product.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.name)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.build.product)

# Apply compatibility metadata and security state normalization.
if [ -n "$RESETPROP" ]; then
    if [ "$ROM_ENV" = "hyperos" ]; then
        RAW_MOD_DEVICE=$(getprop ro.product.mod_device)
        NORM_MOD_DEVICE=""

        case "$RAW_MOD_DEVICE" in
            *_in_global) NORM_MOD_DEVICE="${DEVICE}_in_global" ;;
            *_ru_global) NORM_MOD_DEVICE="${DEVICE}_ru_global" ;;
            *_eea_global) NORM_MOD_DEVICE="${DEVICE}_eea_global" ;;
            *_global) NORM_MOD_DEVICE="${DEVICE}_global" ;;
            "")
                NORM_MOD_DEVICE="$DEVICE"
                ;;
            *)
                NORM_MOD_DEVICE=$(printf '%s\n' "$RAW_MOD_DEVICE" | sed -E 's/_(xiaomieu|eu|hypertn|tn|elite|eliterom|mipa|pulse|mod|custom)//Ig')
                [ -z "$NORM_MOD_DEVICE" ] && NORM_MOD_DEVICE="$DEVICE"
                ;;
        esac

        [ -n "$NORM_MOD_DEVICE" ] && \
            $RESETPROP -n -v ro.product.mod_device "$NORM_MOD_DEVICE" 2>/dev/null || true

        for prop in $(getprop | grep -iE 'xiaomi\.eu|developerid|hypertn|eliterom|mipa|pulse' | sed -E 's/^\[([^]]+)\].*/\1/'); do
            [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
        done
    else
        for prop in $(getprop | grep -iE 'lineage\.(build|version|device|display)|crdroid|evolution|pixelexperience|havoc|derp|modversion' | sed -E 's/^\[([^]]+)\].*/\1/'); do
            [ -n "$prop" ] && $RESETPROP -n -v -d "$prop" 2>/dev/null || true
        done
    fi

    # Normalize device integrity and bootloader state
    P_FLASH="ro.boot.flash"
    P_VBMETA="ro.boot.vbmeta"
    $RESETPROP -n -v "${P_FLASH}.locked" 1
    $RESETPROP -n -v ro.boot.verifiedbootstate green
    $RESETPROP -n -v ro.boot.secureboot 1
    $RESETPROP -n -v "${P_VBMETA}.device_state" locked
    $RESETPROP -n -v ro.secure 1
    $RESETPROP -n -v sys.oem_unlock_allowed 0
    $RESETPROP -n -v ro.boot.warranty_bit 0
fi

# Prepare the compatibility file for optional SuSFS integration.
TARGET_COMPAT_PROP=""
SOURCE_PROP_FILE=""
if [ -f "$MODDIR/compat_build.prop" ]; then
    SOURCE_PROP_FILE="$MODDIR/compat_build.prop"
fi

if [ -n "$SOURCE_PROP_FILE" ]; then
    mkdir -p /mnt/vendor/susfs4ksu 2>/dev/null || true
    if [ -d "/mnt/vendor/susfs4ksu" ]; then
        cp -f "$SOURCE_PROP_FILE" /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chmod 0644 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chcon u:object_r:system_file:s0 /mnt/vendor/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        TARGET_COMPAT_PROP="/mnt/vendor/susfs4ksu/hyperos_compat_build.prop"
    elif [ -d "/data/adb/susfs4ksu" ]; then
        cp -f "$SOURCE_PROP_FILE" /data/adb/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        chmod 0644 /data/adb/susfs4ksu/hyperos_compat_build.prop 2>/dev/null || true
        TARGET_COMPAT_PROP="/data/adb/susfs4ksu/hyperos_compat_build.prop"
    fi
fi

# Detect SuSFS without requiring it.
SUSFS_BIN=""
for candidate in \
    /data/adb/ksu/bin/ksu_susfs \
    /data/adb/ksu/bin/susfs \
    /data/adb/ap/bin/ap_susfs \
    /data/adb/ap/bin/susfs; do
    if [ -x "$candidate" ]; then
        SUSFS_BIN="$candidate"
        break
    fi
done

if [ -z "$SUSFS_BIN" ]; then
    for candidate in ksu_susfs ap_susfs susfs; do
        if command -v "$candidate" >/dev/null 2>&1; then
            SUSFS_BIN="$candidate"
            break
        fi
    done
fi

if [ -n "$SUSFS_BIN" ] && [ -n "$TARGET_COMPAT_PROP" ]; then
    if "$SUSFS_BIN" show version >/dev/null 2>&1; then
        SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
        OWNED_PATHS="$MODDIR/owned_sus_paths.txt"

        if [ -f "$OWNED_PATHS" ] && [ -d "/data/adb/susfs4ksu" ]; then
            touch "$SUS_PATH_FILE" 2>/dev/null || true
            sed -i '/MiuiExtraPhoto/d' "$SUS_PATH_FILE" 2>/dev/null || true
            while IFS= read -r path; do
                [ -n "$path" ] || continue
                [ -e "$path" ] || continue
                "$SUSFS_BIN" add_sus_path "$path" 2>/dev/null || true
                grep -Fxq "$path" "$SUS_PATH_FILE" 2>/dev/null || \
                    printf '%s\n' "$path" >> "$SUS_PATH_FILE"
            done < "$OWNED_PATHS"
        fi

        "$SUSFS_BIN" add_open_redirect /system/build.prop "$TARGET_COMPAT_PROP" 3 2>/dev/null || true
        REDIRECT_LINE="/system/build.prop $TARGET_COMPAT_PROP 1 3"
        printf '%s\n' "$REDIRECT_LINE" > "$MODDIR/owned_open_redirect.txt"
        if [ -f "/data/adb/susfs4ksu/sus_open_redirect.txt" ]; then
            sed -i '/\/data\/adb\/susfs4ksu\/compat_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
            sed -i '/\/data\/adb\/susfs4ksu\/clean_build\.prop/d' /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
            grep -Fxq "$REDIRECT_LINE" /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || \
                printf '%s\n' "$REDIRECT_LINE" >> /data/adb/susfs4ksu/sus_open_redirect.txt 2>/dev/null || true
        fi
    fi
fi

# Harmonize runtime attestation configuration with tricky_store / AlwaysStrong
if [ -f "$MODDIR/attest_sync.sh" ]; then
    sh "$MODDIR/attest_sync.sh" >/dev/null 2>&1
fi

# Launch autonomous compatibility guardian daemon
if [ -f "$MODDIR/guardian.sh" ]; then
    setsid sh "$MODDIR/guardian.sh" </dev/null >/dev/null 2>&1 &
fi

