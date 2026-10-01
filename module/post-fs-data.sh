#!/system/bin/sh
MODDIR=${0%/*}

# Synchronize attestation and banking isolation policies before zygote and apps start
if [ -f "$MODDIR/attest_sync.sh" ]; then
    sh "$MODDIR/attest_sync.sh" >/dev/null 2>&1
fi
