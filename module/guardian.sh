#!/system/bin/sh
MODDIR=${0%/*}
TRICKY_DIR="/data/adb/tricky_store"

PIDFILE="/dev/hcl_guardian.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && [ -d "/proc/$OLD_PID" ]; then
        exit 0
    fi
fi
echo "$$" > "$PIDFILE" 2>/dev/null || true

while true; do
    sleep 10
    if [ -d "$TRICKY_DIR" ]; then
        NEED_FIX=0
        [ ! -f "$TRICKY_DIR/no_prop_unify" ] && NEED_FIX=1
        grep -q "spoofProvider=1" "$TRICKY_DIR/spoof.conf" 2>/dev/null && NEED_FIX=1
        grep -q -E "com\.vnpay\.bidv|com\.mbmobile|com\.VCB|com\.vietinbank\.ipay" "$TRICKY_DIR/target.txt" 2>/dev/null && NEED_FIX=1
        grep -q "^com\.v""nid$" "$TRICKY_DIR/target.txt" 2>/dev/null || NEED_FIX=1
        grep -q "^vn\.com\.techcombank\.bb\.app$" "$TRICKY_DIR/target.txt" 2>/dev/null || NEED_FIX=1

        if [ "$NEED_FIX" -eq 1 ]; then
            if [ -f "$MODDIR/attest_sync.sh" ]; then
                sh "$MODDIR/attest_sync.sh" >/dev/null 2>&1
            fi
        fi
    fi
done
