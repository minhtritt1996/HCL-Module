<div align="center">

# 🛡️ VNeID Fix Module

**Xiaomi.eu Cloak & VNeID Fix — Magisk / KernelSU / APatch Module**

[![Version](https://img.shields.io/badge/version-v1.1.0-blue?style=flat-square)](https://github.com/minhtritt1996/VNeID-Fix-Module/releases)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Tested On](https://img.shields.io/badge/tested%20on-POCO%20F5%20Pro%20%7C%20HyperOS%203-orange?style=flat-square)](#tested-devices)
[![Root](https://img.shields.io/badge/root-KernelSU%20%7C%20APatch%20%7C%20Magisk-red?style=flat-square)](#requirements)

A universal Magisk/KernelSU/APatch module that cloaks **Xiaomi.eu / Custom HyperOS ROM signatures** to allow **VNeID** (`com.vnid`) and Vietnamese banking apps (e.g. **BIDV SmartBanking** `com.vnpay.bidv`) to pass security checks — including **Circular 77/2025/TT-NHNN** device integrity verification.

</div>

---

## 📖 Table of Contents

- [Problem Statement](#-problem-statement)
- [How It Works](#-how-it-works)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Tested Devices](#-tested-devices)
- [FAQ](#-faq)
- [Technical Details](docs/TECHNICAL.md)
- [Contributing](#-contributing)
- [License](#-license)

---

## ❓ Problem Statement

When running **Xiaomi.eu ROM** (unofficial Xiaomi Global ROM) or any **Custom HyperOS / MIUI port**, several critical Vietnamese government and banking apps refuse to launch:

| App | Error |
|---|---|
| **VNeID** (`com.vnid`) | *"Thiết bị của bạn đã bị bẻ khóa / cài ROM không chính thức"* |
| **BIDV SmartBanking** (`com.vnpay.bidv`) | *"Thiết bị di động đã bị bẻ khóa và KHÔNG đủ điều kiện an toàn theo Thông tư 77/2025/TT-NHNN"* |
| Other banking apps | Security tampering detected |

**Root cause:** Xiaomi.eu injects custom identifiers into `build.prop` and ships exclusive system APKs (`XiaomiEUExt.apk`, `MiuiExtraPhoto.apk`) that are detected by these apps via both Java reflection and native C/C++ code scanning.

---

## ⚙️ How It Works

The module uses a **3-layer cloaking strategy** — no system partition modification, no overlay mount, fully reversible:

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 1: Property Spoofing (RAM-level, via resetprop)       │
│  • Removes ro.xiaomi.eu.*, ro.xiaomi.developerid             │
│  • Strips _xiaomieu suffix from ro.product.mod_device        │
│  • Restores ro.build.host to official Xiaomi build server    │
│  • Preserves _global suffix (prevents modem/SIM breakage)   │
├──────────────────────────────────────────────────────────────┤
│  Layer 2: build.prop File Redirect (SuSFS kernel-level)      │
│  • Generates a clean_build.prop during install               │
│  • When an app reads /system/build.prop, the kernel          │
│    transparently returns clean_build.prop instead            │
│  • UID scheme 3: only affects userland apps (uid ≥ 10000)   │
│  • Does NOT affect init, rild, or system daemons             │
├──────────────────────────────────────────────────────────────┤
│  Layer 3: sus_path Hiding (SuSFS kernel-level)               │
│  • Hides /product/priv-app/XiaomiEUExt from app scanners    │
│  • Hides /product/priv-app/MiuiExtraPhoto                   │
└──────────────────────────────────────────────────────────────┘
```

> **Safe execution model:** All hooks run in `service.sh` **after** `sys.boot_completed=1`. Nothing runs in `post-fs-data.sh`. This prevents modem (`rild`) crashes, bootloops, and SIM signal loss.

---

## 📋 Requirements

| Component | Requirement |
|---|---|
| **Root** | KernelSU / KernelSU Next / APatch / Magisk (v26+) |
| **Zygisk** | Zygisk Next (recommended) or built-in Magisk Zygisk |
| **SuSFS** *(optional but recommended)* | Kernel with SuSFS support (e.g. Wild Kernel, ShirkNeko) |
| **HMA-OSS** | Hide My Applist (OSS Zygisk variant) |
| **Tricky Store** | AlwaysStrong build with valid `keybox.xml` |
| **susfs4ksu** | If using SuSFS kernel |
| **Android** | Android 12 or higher |

> **Without SuSFS:** The module still works via `resetprop` only. Apps using native `/proc/self/maps` or direct file reads of `build.prop` may still detect the ROM. SuSFS provides kernel-level isolation for full cloaking.

---

## 🚀 Installation

### Step 1 — Install required modules

Install these modules first via your root manager (KernelSU / Magisk):

1. **Zygisk Next** — [GitHub](https://github.com/Dr-TSNG/ZygiskNext)
2. **HMA-OSS** (Hide My Applist) — [GitHub](https://github.com/Dr-TSNG/Hide-My-Applist)
3. **Tricky Store** (AlwaysStrong build) — [Telegram @keyboxstrong](https://t.me/keyboxstrong)
4. **susfs4ksu** — [GitHub](https://github.com/sidex15/susfs4ksu-module) *(if your kernel supports SuSFS)*

### Step 2 — Install VNeID Fix Module

1. Download the latest release: [`xiaomieu_vneid_cloak_v1.1.0.zip`](https://github.com/minhtritt1996/VNeID-Fix-Module/releases/latest)
2. Open your root manager → **Modules** → **Install from storage**
3. Select the downloaded ZIP
4. Reboot

### Step 3 — Verify installation

```bash
# Check module is active (mount: false = correct, no metamodule needed)
su -c "cat /data/adb/modules/xiaomieu_vneid_cloak/module.prop"

# Verify build.host is clean
su -c "getprop ro.build.host"
# Expected: c5-build-66.bj.xiaomi.com

# Verify Xiaomi.eu identifiers are gone
su -c "getprop | grep -i xiaomi.eu"
# Expected: empty output
```

---

## ⚙️ Configuration

### HMA-OSS (Hide My Applist)

Configure **both** VNeID and BIDV in HMA-OSS:

1. Open HMA-OSS → select **VNeID** (`com.vnid`) → enable **Whitelist mode**
2. Apply presets: `Custom ROM`, `Detector Apps`, `Root Apps`, `Shizuku/Dhizuku`, `Sus Apps`, `Xposed`, `Dev Options`
3. **Extra App List** (apps VNeID is allowed to see):
   - `com.google.android.webview`
   - `com.google.android.gms`
   - `com.android.vending`
4. Repeat the same configuration for **BIDV** (`com.vnpay.bidv`)

### Tricky Store (`target.txt`)

```bash
# Add VNeID to target list (requires hardware-backed keybox attestation)
echo "com.vnid" | su -c "tee -a /data/adb/tricky_store/target.txt"

# ⚠️ DO NOT add com.vnpay.bidv to target.txt
# BIDV uses DexProtector which conflicts with simulated keybox keys
# (causes KeyPermanentlyInvalidatedException)
```

### BIDV SmartBanking — TN ToolBox exclusion (Xiaomi.eu only)

If your ROM has the Xiaomi.eu TN ToolBox keybox feature, exclude BIDV:

```bash
su -c "settings put global tn_keybox_out \
  \"\$(settings get global tn_keybox_out),com.vnpay.bidv\""
```

---

## ✅ Tested Devices

| Device | Codename | ROM | Root | SuSFS | VNeID | BIDV |
|---|---|---|---|---|---|---|
| POCO F5 Pro | `mondrian` | Xiaomi.eu HyperOS 3.0 (Android 15) | KernelSU + Wild Kernel | ✅ v2.3.0 | ✅ | ✅ |

> Want to add your device? See [CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## ❓ FAQ

<details>
<summary><b>Q: Does this work without SuSFS?</b></summary>

Yes, but with limited protection. Without SuSFS, only the `resetprop` layer (Layer 1) applies. Apps using native code to directly `open()` and `read()` `/system/build.prop` (like VNeID's internal C scanner) will still see the original file. A SuSFS-capable kernel provides full kernel-level redirect.
</details>

<details>
<summary><b>Q: Why doesn't the module have a /system folder? (mount: false warning)</b></summary>

This is by design. Including a `/system` directory would require a metamodule (e.g. Magic Mount) and would show a *"module not mounted because metamodule not installed"* warning in KernelSU/ReSukiSU. This module is script-only (`mount: false`) and handles everything via `resetprop` and SuSFS hooks — no overlay filesystem needed.
</details>

<details>
<summary><b>Q: I got a bootloop after installing!</b></summary>

This should not happen with v1.1.0. If it does:
1. Boot into Recovery
2. Navigate to `/data/adb/modules/xiaomieu_vneid_cloak/`
3. Create an empty file named `disable`
4. Reboot

The known cause of bootloops in earlier versions was running `open_redirect` in `post-fs-data.sh` before the modem partition was accessible. v1.1.0 exclusively runs everything in `service.sh` after boot completes.
</details>

<details>
<summary><b>Q: My SIM lost signal after installing!</b></summary>

Make sure the module is NOT modifying `ro.product.mod_device` in a way that strips `_global` from your device codename. For Global devices (e.g. `mondrian_global`), the module preserves the `_global` suffix to keep carrier config correct. If you're on a China model flashed with Global ROM, see [docs/TECHNICAL.md](docs/TECHNICAL.md#modem-safety).
</details>

<details>
<summary><b>Q: Can I use this on LineageOS?</b></summary>

Not directly — LineageOS has different ROM identifiers. The main changes needed are:
- Replace Xiaomi.eu `build.prop` filters with `lineage.*` property removal
- Add `resetprop ro.build.type user` (LineageOS defaults to `userdebug`)
- Remove `ro.debuggable=1` spoofing
- Skip `mod_device` and `XiaomiEUExt` handling

A LineageOS variant is planned. See [Issue tracker](https://github.com/minhtritt1996/VNeID-Fix-Module/issues).
</details>

---

## 🤝 Contributing

Pull requests are welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) first.

- Found a bug? [Open an issue](https://github.com/minhtritt1996/VNeID-Fix-Module/issues)
- Tested on a new device? Submit a PR adding your device to the compatibility table
- Want to add LineageOS support? Check the open issues for a tracking issue

---

## 📄 License

[MIT License](LICENSE) — © 2026 [minhtritt1996](https://github.com/minhtritt1996)
