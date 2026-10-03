# Security Policy & Project Boundaries

## 1. Security Philosophy

**HyperOS & AOSP Compatibility Layer (HCL)** is developed as a local, transparent system compatibility layer for Xiaomi HyperOS and related custom ROM environments.

The project is 100% open source. All source code, shell scripts, and configuration logic are inspectable within this repository.

---

## 2. Project Security Boundaries

To ensure complete clarity regarding what this software does and does not do, our technical boundaries are explicitly defined:

### The Module DOES:
- **Multi-Partition Property Normalization:** Standardizes local Android system properties across all device partitions (`ro.${part}.build.fingerprint`, `ro.product.${part}.*`) in volatile memory (RAM) via `resetprop` to ensure cross-partition consistency.
- **Boot Integrity State Normalization:** Normalizes local RAM flags (bootloader locked state, `ro.boot.verifiedbootstate=green`, `ro.boot.secureboot=1`, vbmeta device state locked, `ro.secure=1`, `sys.oem_unlock_allowed=0`) to eliminate unlocked bootloader state leakage in userland.
- **Dynamic Kernel Uname Alignment:** Harmonizes `uname -r` release strings and build timestamps using SuSFS kernel hooks to strip unofficial or dirty kernel suffixes.
- **Attestation Matrix Coordination:** Synchronizes and manages hardware attestation targets (`target.txt`) and genuine Keystore protection mappings (`app_keybox.map` with `off` flag) to prevent banking and fintech applications from being hijacked into attestation spoofing.
- **Compatibility File Mapping:** Generates a sanitized `compat_build.prop` and provides a read-only compatibility view for userland processes (`uid >= 10000`) using kernel-level SuSFS `open_redirect`.
- **ROM Component Isolation:** Identifies auxiliary or non-standard vendor packages in `priv-app` and registers them into SuSFS `sus_path`, preventing file enumeration conflicts while leaving the core OS functioning.
- **Cold-Boot Safety Guarantee:** Strictly maintains the `post-fs-data` stage as a lightweight non-blocking stub, deferring system property and attestation sync to `service.sh` after `sys.boot_completed=1` to guarantee complete immunity against bootloops.

### The Module DOES NOT:
- **Modify Physical Firmware on Disk:** Does not reflash or modify physical bootloader, vbmeta, or system partition images on storage media. All property normalizations are volatile and exist only in RAM.
- **Access Credentials:** Does not read, monitor, intercept, or store login credentials, passwords, or PINs.
- **Intercept OTP:** Does not monitor SMS messages, notifications, or two-factor authentication tokens.
- **Modify Biometric Data:** Does not interface with Android biometric authentication hardware, TEE (Trusted Execution Environment), or biometric templates.
- **Communicate with Remote Authentication Servers:** Does not connect to, spoof, or interfere with remote backend authentication servers of any service.
- **Distribute Modified APKs:** Does not patch, reverse-engineer, or distribute modified third-party application binaries.
- **Distribute Proprietary Cryptographic Keys:** Does not extract, store, or redistribute proprietary Google or hardware cryptographic keyboxes.
- **Modify Third-Party Backend Systems:** Operates strictly on the local device runtime.

---

## 3. Network Communication Model

> **Network Policy:**  
> The compatibility service itself does not implement telemetry, phone-home requests, or application-level network communication. All configurations, synchronization routines, and WebUI operations run strictly locally on the device (`127.0.0.1` / local UNIX sockets).

No background processes spawn network connections, transmit device logs, or poll remote servers.

---

## 4. Runtime Safety Boundaries

- **On-Disk Immutability:** The module does not modify physical on-disk partition blocks (`/system`, `/vendor`, `/product`, `/boot`, `/vbmeta`).
- **Attestation Governance:** The module harmonizes attestation rules between the local device runtime and attestation modules without distributing proprietary cryptographic material or altering third-party user data.
- **State Reversibility:** Disabling or uninstalling the module releases all SuSFS redirection hooks and RAM properties upon the next reboot.

---

## 5. Reporting a Vulnerability

We welcome responsible security disclosures. If you discover a vulnerability or safety issue:

1. **Do NOT open a public GitHub issue.**
2. Report the vulnerability privately via GitHub Private Vulnerability Reporting on this repository.
3. Include detailed reproduction steps, target Android/HyperOS version, and suggested remediation if available.
4. We aim to review and respond to valid security reports as soon as practical.
