#!/system/bin/sh
MODDIR=${0%/*}

# Early post-fs-data stage
# Runtime directories preparation (must remain lightweight and non-blocking)
mkdir -p /data/adb/hyperos_compat 2>/dev/null || true

