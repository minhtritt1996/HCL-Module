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
xiaomieu_vneid_cloak_v1.2.0.zip
├── META-INF/
│   └── com/google/android/
│       ├── update-binary          # KSU/Magisk installer entrypoint
│       └── updater-script         # Compatibility stub
├── module.prop                    # Module metadata (v1.2.0 Universal)
├── customize.sh                   # Install-time logic & dynamic priv-app scanner
├── service.sh                     # Boot-time dynamic property cleanup & SuSFS hooks
├── uninstall.sh                   # Cleanup on module removal
├── detected_paths.txt             # Dynamically discovered custom ROM priv-apps
└── clean_build.prop               # Generated clean build.prop (per-device)
```

---

## Layer 1: Dynamic Property Spoofing (resetprop)

Runs in `service.sh` after `boot_completed=1`.

### Properties Removed / Spoofed Dynamically

The module dynamically enumerates active system properties via `getprop` and automatically removes any matching signatures from known custom ROMs:

| Category | Targeted Properties / Signatures | Reason |
|---|---|---|
| **Xiaomi.eu** | `ro.xiaomi.developerid`, `ro.xiaomi.eu.*` | Xiaomi.eu developer identifier & OTA channels |
| **HyperTN / TN ToolBox** | `*hypertn*`, `*tntoolbox*` | HyperTN custom ROM identifiers |
| **EliteROM / MiPA / Pulse** | `*eliterom*`, `*mipa*`, `*pulse*` | Custom MIUI/HyperOS port identifiers |
| **LineageOS / AOSP** | `*lineage*`, `*modversion*` | LineageOS and AOSP custom build signatures |
| **Build Flags** | `ro.build.type` (userdebug → user), `ro.debuggable` (1 → 0) | Userdebug/debuggable builds trigger instant root detection |

### Properties Modified

| Property | Before (Example) | After |
|---|---|---|
| `ro.build.host` | `build-m2088.bpi.xiaomi.eu` | `c5-build-66.bj.xiaomi.com` |
| `ro.product.mod_device` | `mondrian_xiaomieu_global` | `mondrian_global` |

### Modem Safety & Dynamic Normalization

> [!IMPORTANT]
> The carrier region suffix (`_global`, `_eea_global`, `_in_global`, `_ru_global`) in `ro.product.mod_device` must be preserved.
>
> Xiaomi devices use this suffix to select the correct carrier configuration bundle:
> - `mondrian_global` → loads `CarrierConfig_Global.apk` (correct for VN/EU)
> - `mondrian` → loads `CarrierConfig_CN.apk` (China only — breaks VoLTE/dual-SIM LTE outside China)
>
> In v1.2.0, the module evaluates the current `ro.product.mod_device` dynamically:
> - If it contains `_in_global`, `_ru_global`, `_eea_global`, or `_global`, the clean device code retains the corresponding exact suffix.
> - Strips all mod tags (`_xiaomieu`, `_hypertn`, `_elite`, `_mipa`, `_pulse`, `_mod`, `_custom`).

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

During `customize.sh`, the module generates `clean_build.prop` from the live system using portable POSIX/Toybox-compatible `sed`:

```bash
sed -e "s/^ro\.build\.host=.*/ro.build.host=c5-build-66.bj.xiaomi.com/" \
    -e "/[Xx][Ii][Aa][Oo][Mm][Ii]\.[Ee][Uu]/d" \
    -e "/[Dd][Ee][Vv][Ee][Ll][Oo][Pp][Ee][Rr][Ii][Dd]/d" \
    -e "/[Hh][Yy][Pp][Ee][Rr][Tt][Nn]/d" \
    -e "/[Ee][Ll][Ii][Tt][Ee][Rr][Oo][Mm]/d" \
    -e "/[Mm][Ii][Pp][Aa]/d" \
    -e "/[Pp][Uu][Ll][Ss][Ee]/d" \
    -e "/[Ll][Ii][Nn][Ee][Aa][Gg][Ee]/d" \
    -e "s/_[Xx][Ii][Aa][Oo][Mm][Ii][Ee][Uu]//g" \
    -e "s/_[Hh][Yy][Pp][Ee][Rr][Tt][Nn]//g" \
    -e "s/_[Ee][Ll][Ii][Tt][Ee]//g" \
    -e "s/_[Mm][Ii][Pp][Aa]//g" \
    -e "s/^ro\.build\.type=userdebug/ro.build.type=user/" \
    -e "s/^ro\.debuggable=1/ro.debuggable=0/" \
    /system/build.prop > "$MODPATH/clean_build.prop"
```

This ensures the redirect file is dynamically tailored to the host system without retaining any signature of custom firmware.

---

## Layer 3: Dynamic sus_path Hiding

`ksu_susfs add_sus_path <path>` makes the specified path invisible to directory listings and `stat()` calls from userland processes.

In v1.2.0, instead of hardcoding specific paths, `customize.sh` dynamically scans the target partitions (`/product/priv-app`, `/system_ext/priv-app`, `/system/priv-app`) for any directories or APKs matching custom ROM fingerprints:
- Xiaomi.eu (`*xiaomieu*`, `*extraphoto*`)
- HyperTN / TN ToolBox (`*hypertn*`, `*tntoolbox*`)
- EliteROM (`*eliterom*`, `*elite*`)
- MiPA / Pulse (`*mipa*`, `*pulse*`)
- LineageOS (`*lineageparts*`)

Found items are saved to `detected_paths.txt` and automatically registered into SuSFS during boot (`service.sh`) and synced into `/data/adb/susfs4ksu/sus_path.txt`. VNeID and banking native scanners receive `ENOENT` (No such file or directory) while the system continues running normally.

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
