# Contributing to VNeID Fix Module

Thank you for considering a contribution! Here's how to get started.

---

## Ways to Contribute

- **Test on a new device** and submit a compatibility report
- **Fix a bug** — check the [issue tracker](https://github.com/minhtritt1996/VNeID-Fix-Module/issues)
- **Add ROM support** (LineageOS, crDroid, EvolutionX, etc.)
- **Improve documentation**

---

## Adding Device Compatibility

1. Fork the repository
2. Test the module on your device, confirm VNeID and your banking apps work
3. Submit a PR editing the **Tested Devices** table in `README.md`:

```markdown
| Your Device | codename | ROM version | Root method | SuSFS? | VNeID | Banking |
```

Please include in the PR description:
- `getprop ro.build.fingerprint` output
- Kernel version (`uname -r`)
- Root manager version
- Whether SuSFS was active

---

## Adding ROM Support

To add support for a new ROM type (e.g. LineageOS), the changes needed are in `customize.sh` and `service.sh`:

### LineageOS example

In `service.sh`, add after the existing `resetprop` block:

```bash
# LineageOS-specific cloaking
if getprop ro.lineage.version > /dev/null 2>&1; then
    $RESETPROP -n ro.build.type user
    $RESETPROP -n ro.build.tags release-keys
    $RESETPROP -n ro.debuggable 0
    $RESETPROP -n ro.secure 1
    $RESETPROP -n -v -d ro.lineage.version
    $RESETPROP -n -v -d ro.lineage.build.version
    $RESETPROP -n -v -d ro.lineage.display.version
    $RESETPROP -n -v -d ro.modversion
fi
```

In `customize.sh`, extend the `sed` filter in step 3:

```bash
sed -e "..." \
    -e "/^ro\.lineage\./d" \
    -e "/^ro\.modversion=/d" \
    -e "s/userdebug/user/g" \
    "$SRC_PROP" > "$MODPATH/clean_build.prop"
```

---

## Code Style

- Shell scripts: POSIX `sh` compatible (no `bash`-specific syntax)
- Use `|| true` after non-critical commands to prevent script abort
- Never write to `/system`, `/vendor`, or any system partition
- Never run anything in `post-fs-data.sh` that touches modem-related paths

---

## PR Checklist

- [ ] Tested on actual hardware (not emulator)
- [ ] No bootloop after install + reboot
- [ ] SIM signal intact after reboot (if dual-SIM device)
- [ ] VNeID opens without warnings
- [ ] Module shows `mount: false` in KernelSU manager

---

## Opening an Issue

Please include:
- Device model + codename
- ROM version + Android version
- Root solution (KernelSU / APatch / Magisk) + version
- Kernel version (`uname -r`)
- Module version
- Logcat output: `su -c "logcat -d | grep -iE 'vnid|vnpay|susfs|resetprop'"` 
