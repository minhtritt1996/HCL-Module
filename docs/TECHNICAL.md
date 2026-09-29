# Technical Documentation

## Architecture Overview

### Execution Lifecycle

```
Boot Phase              Module Activity
──────────────────────────────────────────────────────
early-init              (nothing — avoids modem race)
post-fs-data            (nothing — avoids rild crash)
late-start              (nothing)
boot_completed = 1  ──► service.sh activates
                        ├─ resetprop Layer 1
                        ├─ SuSFS sus_path Layer 3
                        └─ SuSFS open_redirect Layer 2
```

### File Structure

```
xiaomieu_vneid_cloak_v1.1.0.zip
├── META-INF/
│   └── com/google/android/
│       ├── update-binary          # KSU/Magisk installer entrypoint
│       └── updater-script         # Compatibility stub
├── module.prop                    # Module metadata
├── customize.sh                   # Install-time logic
├── service.sh                     # Boot-time property & SuSFS hooks
├── uninstall.sh                   # Cleanup on module removal
└── clean_build.prop               # Generated clean build.prop (per-device)
```

---

## Layer 1: Property Spoofing (resetprop)

Runs in `service.sh` after `boot_completed=1`.

### Properties Removed

| Property | Value (Example) | Reason |
|---|---|---|
| `ro.xiaomi.developerid` | `miuios` | Xiaomi.eu developer identifier |
| `ro.xiaomi.eu.ota_device` | `mondrian_xiaomieu_global` | OTA channel identifier |
| `ro.xiaomi.eu.version.code_time` | `20240912` | Build timestamp marker |

### Properties Modified

| Property | Before | After |
|---|---|---|
| `ro.build.host` | `build-m2088.bpi.xiaomi.eu` | `c5-build-66.bj.xiaomi.com` |
| `ro.product.mod_device` | `mondrian_xiaomieu_global` | `mondrian_global` |

### Modem Safety

> [!IMPORTANT]
> The `_global` suffix in `ro.product.mod_device` must be preserved.
>
> Xiaomi devices use this suffix to select the correct carrier configuration bundle:
> - `mondrian_global` → loads `CarrierConfig_Global.apk` (correct for VN/EU)
> - `mondrian` → loads `CarrierConfig_CN.apk` (China only — breaks VoLTE/dual-SIM LTE outside China)
>
> The module uses `sed -E 's/_(xiaomieu|eu)//g'` which strips **only** the Xiaomi.eu suffix, leaving `_global` intact.

---

## Layer 2: build.prop File Redirect (SuSFS)

### How open_redirect works

`ksu_susfs add_open_redirect <src> <dest> <uid_scheme>` installs a kernel hook in the `open()` syscall handler:

- When any process calls `open("/system/build.prop", ...)`, the hook intercepts the call
- If the caller's UID matches the scheme, it returns a file descriptor to `<dest>` instead
- The process never knows it received a different file

### UID Scheme 3

```
Scheme 0 = all processes
Scheme 1 = su processes only
Scheme 2 = all non-su processes (DANGEROUS — affects init, rild, adbd)
Scheme 3 = userland apps only (uid >= 10000)
```

**This module uses Scheme 3 exclusively.**

> [!CAUTION]
> Scheme 2 redirects `open()` for ALL non-root processes, including `rild` (radio daemon). If `rild` cannot read a valid `build.prop` before the modem partition is mounted, it triggers a **Modem Subsystem Restart (SSR)** → kernel watchdog → bootloop at the first vendor logo.
>
> This was the root cause of bootloops in early testing. Always use Scheme 3.

### clean_build.prop Generation

During `customize.sh`, the module generates `clean_build.prop` from the live system:

```bash
sed -e "s/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/" \
    -e "/# ADDED BY XIAOMI\.EU/d" \
    -e "/MIUIOS\.CZ/d" \
    -e "/MIUIPOLSKA\.PL/d" \
    -e "/^ro\.xiaomi\.developerid=/d" \
    -e "/^ro\.xiaomi\.eu\./d" \
    -e "s/_xiaomieu//g" \
    /system/build.prop > "$MODPATH/clean_build.prop"
```

This ensures the redirect file is always generated from the actual device's `build.prop` — making the module portable across any device without hardcoded values.

---

## Layer 3: sus_path Hiding

`ksu_susfs add_sus_path <path>` makes the specified path invisible to directory listings and `stat()` calls from userland processes:

```bash
ksu_susfs add_sus_path /product/priv-app/XiaomiEUExt
ksu_susfs add_sus_path /product/priv-app/XiaomiEUExt/XiaomiEUExt.apk
ksu_susfs add_sus_path /product/priv-app/MiuiExtraPhoto
ksu_susfs add_sus_path /product/priv-app/MiuiExtraPhoto/MiuiExtraPhoto.apk
```

VNeID's native C scanner enumerates `/product/priv-app/` looking for Xiaomi.eu APKs. With `sus_path` active, these entries return `ENOENT` (No such file or directory) to the scanner even though the APKs are still physically present on the partition.

---

## Detection Vectors Mitigated

| Detection Method | Mitigation |
|---|---|
| Java `Build.HOST` field | Layer 1: `resetprop ro.build.host` |
| Java `SystemProperties.get("ro.xiaomi.*")` | Layer 1: `resetprop --delete` |
| Native `open("/system/build.prop")` + `grep xiaomi.eu` | Layer 2: SuSFS `open_redirect` |
| Native `readdir("/product/priv-app/")` | Layer 3: SuSFS `sus_path` |
| `PackageManager.getInstalledPackages()` | HMA-OSS Whitelist (external config) |
| Play Integrity API `appRecognitionVerdict` | Tricky Store + valid `keybox.xml` |
| AVC SELinux denials (root detection) | SELinux Enforcing preserved (not weakened) |

---

## Known Limitations

1. **No SuSFS kernel:** Layers 2 and 3 are inactive. `resetprop` alone may not be sufficient for apps with aggressive native scanning (VNeID v2.2.x+).

2. **Magisk Zygisk (built-in):** Fully supported, but Zygisk Next is recommended for better denylist isolation.

3. **BIDV SmartBanking:** Must NOT be added to Tricky Store `target.txt`. DexProtector validates that hardware-backed keys match the device's actual biometric enrollment. A simulated keybox causes `KeyPermanentlyInvalidatedException` during login. Exclude BIDV from keybox emulation and let HMA-OSS handle app list hiding instead.

4. **Play Integrity `UNEVALUATED`:** This verdict appears when Google Play Services cannot reach Google's attestation servers — typically during network outages or immediately after SIM changes. It resolves automatically once network connectivity is stable. It is not caused by this module.

---

## resetprop Compatibility

The module auto-detects the correct `resetprop` binary for the active root solution:

```bash
# KernelSU
/data/adb/ksu/bin/resetprop

# APatch
/data/adb/ap/bin/resetprop

# Magisk
/data/adb/magisk/magisk --resetprop

# Fallback (PATH)
resetprop
```
