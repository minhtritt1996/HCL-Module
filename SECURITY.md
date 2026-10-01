# Security Policy & Project Boundaries

## 1. Security Philosophy

**HyperOS Compatibility Layer** is developed as a local, transparent system compatibility layer for Xiaomi HyperOS and related custom ROM environments.

The project is 100% open source. All source code, shell scripts, and configuration logic are inspectable within this repository.

---

## 2. Project Security Boundaries

To ensure complete clarity regarding what this software does and does not do, our technical boundaries are explicitly defined:

### The Module DOES:
- **Local System-Property Normalization:** Standardizes local Android system properties (`ro.product.*`, `ro.build.host`, `ro.build.type`, `ro.debuggable`) in RAM via `resetprop` to match official release baselines.
- **Compatibility File Mapping:** Generates a sanitized `compat_build.prop` and provides a read-only compatibility view for userland processes (`uid >= 10000`) using kernel-level SuSFS `open_redirect`.
- **ROM Component Isolation:** Identifies auxiliary or non-standard vendor packages in `priv-app` and registers them into SuSFS `sus_path`, preventing file enumeration conflicts while leaving the core OS functioning.
- **Runtime Configuration Normalization:** Safely applies configuration after system boot completion (`sys.boot_completed=1`) to protect modem radio services (`rild`).

### The Module DOES NOT:
- **Access Credentials:** Does not read, monitor, intercept, or store login credentials, passwords, or PINs.
- **Intercept OTP:** Does not monitor SMS messages, notifications, or two-factor authentication tokens.
- **Modify Biometric Data:** Does not interface with Android biometric authentication hardware, TEE (Trusted Execution Environment), or biometric templates.
- **Communicate with Remote Authentication Servers:** Does not connect to, spoof, or interfere with remote backend authentication servers of any service.
- **Distribute Modified APKs:** Does not patch, reverse-engineer, or distribute modified third-party application binaries.
- **Distribute Cryptographic Keys:** Does not extract, store, or redistribute proprietary Google or hardware cryptographic keyboxes.
- **Modify Third-Party Backend Systems:** Operates strictly on the local device runtime.

---

## 3. Network Communication Model

> **Network Policy:**  
> The compatibility service itself does not implement telemetry, phone-home requests, or application-level network communication. The optional Action button may launch the project webpage in the user's browser.

No background processes spawn network connections, transmit device logs, or poll remote servers.

---

## 4. Runtime Safety Boundaries

The module deliberately does **not** modify or synthesize:
- Bootloader lock state;
- Android Verified Boot state;
- OEM unlock state;
- Hardware-backed attestation keys;
- Third-party application data.

The module also does not modify configuration files belonging to other root modules.

## 5. Reporting a Vulnerability

We welcome responsible security disclosures. If you discover a vulnerability or safety issue:

1. **Do NOT open a public GitHub issue.**
2. Report the vulnerability privately via GitHub Private Vulnerability Reporting on this repository.
3. Include detailed reproduction steps, target Android/HyperOS version, and suggested remediation if available.
4. We aim to review and respond to valid security reports as soon as practical.
