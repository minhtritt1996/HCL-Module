# Privacy Policy & Data Handling

This policy outlines data handling practices for the **HyperOS Compatibility Layer** project.

---

## 1. Data Collection Policy

> **Core Principle:**  
> The module itself does not implement telemetry or data collection.

Specifically, HyperOS Compatibility Layer does not collect, log, store, or transmit:
- **Account credentials:** Usernames, email addresses, passwords, PIN codes, or security tokens.
- **Authentication factors:** One-time passwords (OTP), two-factor authentication secrets, or push notification payloads.
- **Biometric data:** Facial recognition scans, fingerprint templates, or biometric matching scores.
- **Device identifiers:** Hardware serial numbers, IMEI/MEID numbers, phone numbers (MSISDN), Android IDs, or MAC addresses.
- **Financial & Banking information:** Account numbers, payment card data, balances, or transaction histories.
- **Identity information:** National identity records, citizen identification numbers, personal profile data, or government registry details.

All system property normalizations and configuration hooks execute locally on the device file system and in volatile memory (RAM).

---

## 2. Community Contributions & Diagnostics Policy

When users participate in community discussions, open GitHub Issues, or submit Pull Requests:

- **Redaction Requirement:** Contributors must redact or exclude sensitive identifiers (IMEI, phone numbers, account tokens, personal names, unredacted logcat outputs) before submitting logs or diagnostic reports.
- **Diagnostic Information:** Only non-personal system diagnostic parameters are appropriate for issue troubleshooting:
  - Device codename (`ro.product.device`)
  - HyperOS / Android release version
  - Kernel release (`uname -r`)
  - SELinux operating state (`getenforce`)
  - Root solution name and version
- Any user contribution inadvertently containing sensitive personal data will be edited or removed promptly by maintainers.

---

## 3. Contact & Inquiries

For privacy-related questions or requests regarding the project repository, please open an administrative inquiry via GitHub Issues or contact the maintainer directly.
