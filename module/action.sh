#!/system/bin/sh
# HyperOS Compatibility Layer - Diagnostic & Management Action
MODDIR=${0%/*}
CONF_DIR="/data/adb/hyperos_compat"
CONF_FILE="$CONF_DIR/config.json"
TRICKY_DIR="/data/adb/tricky_store"
PIDFILE="/dev/hcl_guardian.pid"

ARG="${1:-status}"

echo "================================================"
echo "    HyperOS Compatibility Layer (HCL) Action    "
echo "================================================"

case "$ARG" in
    --sync|-s)
        if [ -f "$MODDIR/attest_sync.sh" ]; then
            echo "[*] Synchronizing attestation and keystore policies..."
            sh "$MODDIR/attest_sync.sh"
            echo "[+] Synchronization completed successfully."
        fi
        ;;

    --clean-cache|-c)
        if [ -f "$MODDIR/scripts/cache_cleaner.sh" ]; then
            echo "[*] Launching security cache cleaner..."
            sh "$MODDIR/scripts/cache_cleaner.sh"
        fi
        ;;

    --toggle-guardian|-g)
        KILL_SWITCH="$CONF_DIR/disable_guardian"
        if [ -f "$KILL_SWITCH" ]; then
            rm -f "$KILL_SWITCH"
            echo "[+] Guardian daemon ENABLED. Starting daemon..."
            if [ -f "$MODDIR/guardian.sh" ]; then
                nohup /system/bin/sh "$MODDIR/guardian.sh" </dev/null >/dev/null 2>&1 &
            fi
        else
            touch "$KILL_SWITCH"
            if [ -f "$PIDFILE" ]; then
                kill "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null || true
                rm -f "$PIDFILE"
            fi
            echo "[-] Guardian daemon DISABLED."
        fi
        ;;

    status|*)
        echo "[*] Action Mode: Non-Destructive System Diagnostic"
        echo "------------------------------------------------"
        
        # 1. Device Info
        DEV=$(getprop ro.product.vendor.device)
        [ -z "$DEV" ] && DEV=$(getprop ro.product.device)
        MDL=$(getprop ro.product.vendor.model)
        [ -z "$MDL" ] && MDL=$(getprop ro.product.model)
        echo "[-] Hardware: $DEV ($MDL)"
        echo "[-] Kernel:   $(uname -r)"

        # 2. Bootloader and Verified Boot
        P_FLASH="ro.boot.flash"
        P_VBMETA="ro.boot.vbmeta"
        echo "[-] Integrity Normalization:"
        echo "    - ${P_FLASH}.locked = $(getprop ${P_FLASH}.locked 2>/dev/null || echo 'N/A')"
        echo "    - Verified Boot State = $(getprop ro.boot.verifiedbootstate 2>/dev/null || echo 'N/A')"
        echo "    - Secure Boot = $(getprop ro.boot.secureboot 2>/dev/null || echo 'N/A')"

        # 3. SuSFS Kernel State
        SUSFS_BIN=""
        for b in /data/adb/ksu/bin/ksu_susfs /data/adb/ksu/bin/susfs /data/adb/ap/bin/ap_susfs susfs; do
            if [ -x "$b" ]; then SUSFS_BIN="$b"; break; fi
        done
        if [ -n "$SUSFS_BIN" ]; then
            echo "[-] SuSFS Integration: Active ($($SUSFS_BIN show version 2>/dev/null || echo 'ready'))"
        else
            echo "[-] SuSFS Integration: Not detected (System property mode)"
        fi

        # 4. Guardian Daemon
        if [ -f "$PIDFILE" ] && [ -d "/proc/$(cat "$PIDFILE" 2>/dev/null)" ]; then
            echo "[-] Guardian Daemon: Running (PID: $(cat "$PIDFILE" 2>/dev/null))"
        elif [ -f "$CONF_DIR/disable_guardian" ]; then
            echo "[-] Guardian Daemon: Disabled (Kill-switch active)"
        else
            echo "[-] Guardian Daemon: Inactive"
        fi

        # 5. Attestation Matrix Overview
        HW_COUNT=0
        if [ -f "$TRICKY_DIR/target.txt" ]; then
            HW_COUNT=$(grep -c '[^[:space:]]' "$TRICKY_DIR/target.txt" 2>/dev/null || true)
            [ -z "$HW_COUNT" ] && HW_COUNT=0
        fi

        MAP_COUNT=0
        if [ -f "$TRICKY_DIR/app_keybox.map" ]; then
            MAP_COUNT=$(grep -c '[[:space:]]off' "$TRICKY_DIR/app_keybox.map" 2>/dev/null || true)
            [ -z "$MAP_COUNT" ] && MAP_COUNT=0
        fi
        echo "[-] Attestation Matrix:"
        echo "    - Hardware Attestation Targets: $HW_COUNT packages configured"
        echo "    - Genuine Keystore Protected:  $MAP_COUNT banking packages protected"

        echo "------------------------------------------------"
        echo "[TIP] Manage packages, overrides, and logs via the WebUI"
        echo "      in KernelSU / APatch / MMRL Manager."
        ;;
esac

echo "================================================"
