#!/system/bin/sh
# HyperOS Compatibility Layer - System Service & State Normalization
MODDIR=${0%/*}
CONF_DIR="/data/adb/hyperos_compat"
CONF_FILE="$CONF_DIR/config.json"

# Run after Android reports boot completion.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Safe JSON value extractor
get_json_val() {
    key="$1"
    file="$2"
    [ -f "$file" ] || return 0
    sed -n -E "s/.*\"$key\": *\"?([^,\"]*)\"?.*/\1/p" "$file" 2>/dev/null | head -n 1
}

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

# Dynamically resolve real device identity
DEVICE=$(getprop ro.product.vendor.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.device)
[ -z "$DEVICE" ] && DEVICE=$(getprop ro.product.name)

REAL_MODEL=$(getprop ro.product.vendor.model)
[ -z "$REAL_MODEL" ] && REAL_MODEL=$(getprop ro.product.odm.model)
[ -z "$REAL_MODEL" ] && REAL_MODEL=$(getprop ro.product.model)

# Apply user overrides from config if defined
if [ -f "$CONF_FILE" ]; then
    CFG_DEV=$(get_json_val "custom_device" "$CONF_FILE")
    [ -n "$CFG_DEV" ] && DEVICE="$CFG_DEV"
    CFG_MOD=$(get_json_val "custom_model" "$CONF_FILE")
    [ -n "$CFG_MOD" ] && REAL_MODEL="$CFG_MOD"
fi

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

    # Fingerprint normalization: ensure all partitions match the current OS release version
    SYS_FP=$(getprop ro.build.fingerprint)
    VENDOR_FP=$(getprop ro.vendor.build.fingerprint)
    REL_VER=$(getprop ro.build.version.release)
    [ -z "$REL_VER" ] && REL_VER="15"

    TARGET_FP=""
    if [ -n "$SYS_FP" ] && ! printf '%s\n' "$SYS_FP" | grep -qiE 'test-keys|lineage|crdroid|evolution|aosp' && printf '%s\n' "$SYS_FP" | grep -q ":${REL_VER}/"; then
        TARGET_FP="$SYS_FP"
    elif [ -n "$VENDOR_FP" ] && ! printf '%s\n' "$VENDOR_FP" | grep -qiE 'test-keys|lineage|crdroid|evolution|aosp' && printf '%s\n' "$VENDOR_FP" | grep -q ":${REL_VER}/"; then
        TARGET_FP="$VENDOR_FP"
    elif [ -n "$SYS_FP" ] && ! printf '%s\n' "$SYS_FP" | grep -qiE 'test-keys|lineage|crdroid|evolution|aosp'; then
        TARGET_FP="$SYS_FP"
    elif [ -n "$VENDOR_FP" ] && ! printf '%s\n' "$VENDOR_FP" | grep -qiE 'test-keys|lineage|crdroid|evolution|aosp'; then
        TARGET_FP="$VENDOR_FP"
    fi

    if [ -n "$TARGET_FP" ]; then
        for part in system system_ext product vendor odm bootimage vendor_dlkm odm_dlkm; do
            CUR_PART_FP=$(getprop "ro.${part}.build.fingerprint")
            if [ -z "$CUR_PART_FP" ] || [ "$CUR_PART_FP" != "$TARGET_FP" ]; then
                $RESETPROP -n -v "ro.${part}.build.fingerprint" "$TARGET_FP" 2>/dev/null || true
            fi
        done
    fi

    # Normalize device properties dynamically
    $RESETPROP -n -v ro.build.product "$DEVICE" 2>/dev/null || true
    $RESETPROP -n -v ro.build.flavor "${DEVICE}-user" 2>/dev/null || true

    BRAND=$(getprop ro.product.vendor.brand)
    [ -z "$BRAND" ] || [ "$BRAND" = "Android" ] && BRAND=$(getprop ro.product.odm.brand)
    [ -z "$BRAND" ] || [ "$BRAND" = "Android" ] && BRAND=$(getprop ro.product.brand)
    [ -z "$BRAND" ] || [ "$BRAND" = "Android" ] && BRAND="POCO"

    MANUFACTURER=$(getprop ro.product.vendor.manufacturer)
    [ -z "$MANUFACTURER" ] || [ "$MANUFACTURER" = "unknown" ] && MANUFACTURER=$(getprop ro.product.odm.manufacturer)
    [ -z "$MANUFACTURER" ] || [ "$MANUFACTURER" = "unknown" ] && MANUFACTURER=$(getprop ro.product.manufacturer)
    [ -z "$MANUFACTURER" ] || [ "$MANUFACTURER" = "unknown" ] && MANUFACTURER="Xiaomi"

    for part in product vendor_dlkm odm_dlkm system_ext odm system bootimage vendor; do
        if [ -n "$REAL_MODEL" ]; then
            CUR_M=$(getprop "ro.product.${part}.model")
            if [ -z "$CUR_M" ] || [ "$CUR_M" != "$REAL_MODEL" ]; then
                $RESETPROP -n -v "ro.product.${part}.model" "$REAL_MODEL" 2>/dev/null || true
            fi
        fi
        CUR_D=$(getprop "ro.product.${part}.device")
        if [ -z "$CUR_D" ] || [ "$CUR_D" != "$DEVICE" ]; then
            $RESETPROP -n -v "ro.product.${part}.device" "$DEVICE" 2>/dev/null || true
        fi
        CUR_N=$(getprop "ro.product.${part}.name")
        if [ -z "$CUR_N" ] || [ "$CUR_N" != "$DEVICE" ]; then
            $RESETPROP -n -v "ro.product.${part}.name" "$DEVICE" 2>/dev/null || true
        fi
        CUR_B=$(getprop "ro.product.${part}.brand")
        if [ -z "$CUR_B" ] || [ "$CUR_B" != "$BRAND" ]; then
            $RESETPROP -n -v "ro.product.${part}.brand" "$BRAND" 2>/dev/null || true
        fi
        CUR_MF=$(getprop "ro.product.${part}.manufacturer")
        if [ -z "$CUR_MF" ] || [ "$CUR_MF" != "$MANUFACTURER" ]; then
            $RESETPROP -n -v "ro.product.${part}.manufacturer" "$MANUFACTURER" 2>/dev/null || true
        fi
    done

    # Top-level product properties normalization
    if [ -n "$REAL_MODEL" ]; then
        $RESETPROP -n -v ro.product.model "$REAL_MODEL" 2>/dev/null || true
    fi
    if [ -n "$DEVICE" ]; then
        $RESETPROP -n -v ro.product.device "$DEVICE" 2>/dev/null || true
        $RESETPROP -n -v ro.product.name "$DEVICE" 2>/dev/null || true
    fi
    if [ -n "$BRAND" ]; then
        $RESETPROP -n -v ro.product.brand "$BRAND" 2>/dev/null || true
    fi
    if [ -n "$MANUFACTURER" ]; then
        $RESETPROP -n -v ro.product.manufacturer "$MANUFACTURER" 2>/dev/null || true
    fi

    CUR_DESC=$(getprop ro.build.description)
    if [ -z "$CUR_DESC" ] || printf '%s\n' "$CUR_DESC" | grep -qiE 'generic|gsi|missi|qssi|test-keys'; then
        BUILD_ID=$(getprop ro.build.id)
        [ -z "$BUILD_ID" ] && BUILD_ID="AQ3A.250226.002"
        $RESETPROP -n -v ro.build.description "${DEVICE}-user ${REL_VER} ${BUILD_ID} OS3.0.8.0.VMNCNXM release-keys" 2>/dev/null || true
    fi

    # Clean generic vendor/AOSP compatibility quirks
    $RESETPROP -n -v ro.vendor.qti.va_aosp.support 0 2>/dev/null || true
    $RESETPROP --delete vendor.miwild.enabled 2>/dev/null || true

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

# Prepare compatibility file for optional SuSFS integration.
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

if [ -n "$SUSFS_BIN" ]; then
    if "$SUSFS_BIN" show version >/dev/null 2>&1; then
        SUS_PATH_FILE="/data/adb/susfs4ksu/sus_path.txt"
        OWNED_PATHS="$MODDIR/owned_sus_paths.txt"

        if [ -f "$OWNED_PATHS" ] && [ -d "/data/adb/susfs4ksu" ]; then
            touch "$SUS_PATH_FILE" 2>/dev/null || true
            while IFS= read -r path; do
                [ -n "$path" ] || continue
                [ -e "$path" ] || continue
                "$SUSFS_BIN" add_sus_path "$path" 2>/dev/null || true
                grep -Fxq "$path" "$SUS_PATH_FILE" 2>/dev/null || \
                    printf '%s\n' "$path" >> "$SUS_PATH_FILE"
            done < "$OWNED_PATHS"
        fi

        if [ -n "$TARGET_COMPAT_PROP" ]; then
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

        # Dynamic Kernel uname normalization (defaults to true for banking/security compatibility)
        SPOOF_UNAME=$(get_json_val "spoof_uname" "$CONF_FILE")
        [ -z "$SPOOF_UNAME" ] && SPOOF_UNAME="true"

        if [ "$SPOOF_UNAME" = "true" ]; then
            CUR_UNAME=$(uname -r)
            SER_HASH=$(getprop ro.boot.serialno | head -c 8)
            [ -z "$SER_HASH" ] && SER_HASH="87b95388"
            # Normalize uname release dynamically by stripping dirty/custom suffixes or replacing custom kernel names
            BASE_KERNEL=$(printf '%s\n' "$CUR_UNAME" | sed -E "s/(android[0-9]+)-[A-Za-z0-9_.]*(wild|dirty|custom|lineage|crdroid|mod)[A-Za-z0-9_.]*/\1-9-g${SER_HASH}/Ig; s/-[A-Za-z0-9_.]*(dirty|lineage|crdroid|evolution|custom|wild|zen|arter|mod|plus|unofficial|star0|dsfork)[A-Za-z0-9_.]*//Ig")
            [ -z "$BASE_KERNEL" ] && BASE_KERNEL="$CUR_UNAME"

            BUILD_DATE_UTC=$(getprop ro.build.date.utc)
            if [ -n "$BUILD_DATE_UTC" ] && command -v date >/dev/null 2>&1; then
                KERNEL_DATE=$(date -u -d "@$BUILD_DATE_UTC" '+%a %b %-d %T UTC %Y' 2>/dev/null || date -u '+%a %b %-d %T UTC %Y')
            else
                KERNEL_DATE=$(date -u '+%a %b %-d %T UTC %Y')
            fi
            "$SUSFS_BIN" set_uname "$BASE_KERNEL" "#1 SMP PREEMPT $KERNEL_DATE" 2>/dev/null || true
        fi
    fi
fi

# Reload HMA configuration if installed
if [ -f "$MODDIR/scripts/hma_sync.sh" ]; then
    sh "$MODDIR/scripts/hma_sync.sh" >/dev/null 2>&1 || true
elif [ -x "/system/bin/content" ] || command -v content >/dev/null 2>&1; then
    content call --uri content://org.frknkrc44.hma_oss.ServiceProvider --method reloadConfigFromFile >/dev/null 2>&1 || true
fi

# Harmonize runtime attestation configuration with tricky_store / AlwaysStrong
if [ -f "$MODDIR/attest_sync.sh" ]; then
    sh "$MODDIR/attest_sync.sh" >/dev/null 2>&1
fi

# Launch background compatibility guardian daemon
if [ -f "$MODDIR/guardian.sh" ]; then
    nohup /system/bin/sh "$MODDIR/guardian.sh" </dev/null >/dev/null 2>&1 &
fi
