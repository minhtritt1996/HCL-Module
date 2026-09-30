<div align="center">

# 🛡️ HyperOS & AOSP Compatibility Layer

**Compatibility layer dành cho Xiaomi HyperOS và các ROM tùy biến AOSP (LineageOS, crDroid...).**

<p align="center">
  <a href="https://github.com/minhtritt1996/HCL-Module">
    <img src="https://img.shields.io/badge/GitHub-Kho_Mã_Nguồn-181717?style=for-the-badge&logo=github&logoColor=white" alt="Truy cập Repo" />
  </a>
  <a href="https://github.com/minhtritt1996/HCL-Module/releases/latest">
    <img src="https://img.shields.io/badge/Tải_Về_Mới_Nhất-v1.3.4-2ea44f?style=for-the-badge&logo=github&logoColor=white" alt="Tải về mới nhất" />
  </a>
</p>

[![Phiên bản](https://img.shields.io/badge/phiên_bản-v1.3.4-blue?style=flat-square)](https://github.com/minhtritt1996/HCL-Module/releases)
[![Giấy phép](https://img.shields.io/badge/giấy_phép-MIT-green?style=flat-square)](LICENSE)
[![Disclaimer](https://img.shields.io/badge/pháp_lý-Disclaimer-yellow?style=flat-square)](DISCLAIMER.md)
[![Security](https://img.shields.io/badge/bảo_mật-Security_Boundaries-blueviolet?style=flat-square)](SECURITY.md)
[![Privacy](https://img.shields.io/badge/quyền_riêng_tư-Zero_Telemetry-brightgreen?style=flat-square)](PRIVACY.md)
[![Root](https://img.shields.io/badge/root-KernelSU_%7C_APatch_%7C_Magisk-red?style=flat-square)](#-yêu-cầu-hệ-thống)

Dự án cung cấp cơ chế chuẩn hóa môi trường Android cục bộ (Smart Environment Detection) nhằm giảm khác biệt giữa ROM stock và các bản ROM tùy biến (HyperOS-based & AOSP-based), nâng cao độ tin cậy và tính tương thích cho các ứng dụng người dùng.

</div>

---

## 🌐 Phạm Vi Hỗ Trợ

```
Hệ Điều Hành & Bản ROM
├── Xiaomi HyperOS & MIUI
│   ├── Xiaomi.eu
│   ├── HyperTN
│   ├── EliteROM
│   ├── MiPA
│   ├── Pulse
│   └── HyperOS Ports (Flagship ports, cross-device ports)
└── AOSP & AOSP-based Custom ROMs
    ├── LineageOS
    ├── crDroid
    ├── PixelExperience / PixelOS
    ├── EvolutionX
    └── Generic AOSP / GSI (Treble)
```

---

## 🧪 Lĩnh Vực Kiểm Thử Tương Thích (Compatibility Testing)

Thay vì tập trung vào một ứng dụng riêng lẻ, khuôn khổ tương thích được thiết kế phục vụ kiểm thử diện rộng cho nhiều nhóm ứng dụng đòi hỏi tính toàn vẹn môi trường cao:

```
Compatibility Testing
├── Identity applications (Định danh điện tử, dịch vụ công)
├── Banking applications (Ứng dụng tài chính & ngân hàng số)
├── Enterprise applications (Phần mềm doanh nghiệp & quản trị nội bộ)
├── Device management applications (MDM, Work Profile, Knox/EMM tương thích)
└── Android system applications (Google Play Services, WebView, CTS Baseline)
```

---

## 📖 Mục Lục

- [Mục Đích Dự Án](#-mục-đích-dự-án)
- [Kiến Trúc Kỹ Thuật 3 Lớp](#-kiến-trúc-kỹ-thuật-3-lớp)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Cài Đặt & Nâng Cấp](#-cài-đặt--nâng-cấp)
- [Cấu Hình Môi Trường Ứng Dụng](#-cấu-hình-môi-trường-ứng-dụng)
- [Kiểm Tra Nhanh Tính Tương Thích](#-kiểm-tra-nhanh-tính-tương-thích)
- [Thiết Bị & Môi Trường Đã Thử Nghiệm](#-thiết-bị--môi-trường-đã-thử-nghiệm)
- [Câu Hỏi Thường Gặp (FAQ)](#-câu-hỏi-thường-gặp-faq)
- [Tài Liệu Kỹ Thuật Chi Tiết (12 Chuyên Mục)](docs/TECHNICAL.md)
- [Quy Định Đóng Góp (Contributing)](docs/CONTRIBUTING.md)
- [Tuyên Bố Sở Hữu Trí Tuệ (Trademarks)](docs/TRADEMARKS.md)
- [Tuyên Bố Miễn Trừ Trách Nhiệm](DISCLAIMER.md)

---

## ❓ Mục Đích Dự Án

Trong các bản ROM tùy biến (cả **Xiaomi HyperOS-based** như Xiaomi.eu, HyperTN, EliteROM... và **AOSP-based** như LineageOS, crDroid, EvolutionX...), quá trình phát triển thường để lại các thuộc tính cấu hình không đồng nhất so với bản phát hành thương mại chính thức (Stock Firmware):
- Cờ kiểm thử của nhà phát triển ROM (`ro.build.type=userdebug`, `ro.debuggable=1`).
- Máy chủ biên dịch không thuộc hạ tầng chính thức (`ro.build.host`), hoặc các thuộc tính mang dấu hiệu nhận diện bản mod (`ro.lineage.*`, `ro.crdroid.*`, `ro.product.mod_device`, `ro.modversion`...).
- Tích hợp thêm các tiện ích hệ thống riêng của bản mod (`XiaomiEUExt`, `XiaomiEUInject`, `TNToolbox`, OTA updaters...).

Những khác biệt này khiến môi trường thực thi thiếu tính nhất quán so với tiêu chuẩn Android Compatibility Definition Document (CDD). **HyperOS & AOSP Compatibility Layer** tích hợp cơ chế **Nhận diện môi trường thông minh (Smart Environment Detection)**, tự động nhận biết hệ điều hành đang chạy để áp dụng hồ sơ chuẩn hóa tương ứng mà không gây xung đột hay cấy nhầm thông số giữa các dòng ROM.

---

## ⚙️ Kiến Trúc Kỹ Thuật 3 Lớp Thích Ứng

Dự án giữ vững kiến trúc 3 lớp kỹ thuật lõi, vận hành tự động thích ứng thông minh theo từng cấu hình hệ điều hành:

```
┌──────────────────────────────────────────────────────────────────┐
│  Lớp 1: System Property Normalization (RAM, resetprop)           │
│  • Tự động nhận diện môi trường: HyperOS Profile vs AOSP Profile  │
│  • HyperOS: Chuẩn hóa ro.build.host (c5-build-66), dọn dẹp       │
│    ro.xiaomi.eu.*, ro.hypertn.*, ro.eliterom.*, bảo toàn mod_device│
│  • AOSP/LineageOS: Dọn dẹp ro.lineage.*, ro.crdroid.*, modversion │
│    mà KHÔNG cấy thuộc tính Xiaomi hay can thiệp vào máy chủ gốc  │
│  • Đồng bộ cờ phát hành chuẩn: ro.build.type=user, ro.debuggable=0 │
├──────────────────────────────────────────────────────────────────┤
│  Lớp 2: Compatibility File View (SuSFS open_redirect)            │
│  • Tạo compat_build.prop đã được chuẩn hóa tự động khi cài đặt   │
│  • Cung cấp compatibility view nhất quán cho user-space          │
│    applications khi đọc /system/build.prop                       │
│  • Áp dụng UID Scheme 3: Chỉ ảnh hưởng ứng dụng người dùng       │
│    (uid ≥ 10000), không làm gián đoạn init hoặc rild daemon      │
├──────────────────────────────────────────────────────────────────┤
│  Lớp 3: ROM Component Isolation (SuSFS sus_path)                 │
│  • Quét động các gói APK phụ trợ riêng biệt theo từng dòng ROM    │
│    (HyperOS: XiaomiEUExt, XiaomiEUInject, TNToolbox...           │
│     AOSP: Lineage Updater, crDroid Updater...)                   │
│  • Tự động bảo vệ các thành phần thiết yếu (như LineageParts)     │
│    để không làm gián đoạn giao diện cài đặt hệ thống             │
│  • Tự động ghi nhớ và đồng bộ vĩnh viễn vào kernel SuSFS         │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📋 Yêu Cầu Hệ Thống

| Thành phần | Yêu cầu | Ghi chú |
|---|---|---|
| **Root Solution** | KernelSU / KernelSU Next / APatch / Magisk (v26+) | Dùng để thực thi script chuẩn hóa thuộc tính hệ thống |
| **Zygisk** | Zygisk Next (khuyến nghị) hoặc Magisk Zygisk | Cách ly môi trường thực thi ứng dụng |
| **Kernel SuSFS** *(Tùy chọn)* | Kernel hỗ trợ SuSFS (Wild Kernel, ShirkNeko...) | Cung cấp Lớp 2 (Chuyển hướng tệp) và Lớp 3 (Cách ly thành phần) |
| **susfs4ksu** | Module susfs4ksu (nếu dùng kernel SuSFS) | Tự động đồng bộ các quy tắc cấu hình kernel |
| **HMA-OSS** | Hide My Applist (bản mã nguồn mở Zygisk) | Quản lý danh sách ứng dụng theo cơ chế Whitelist |
| **Hệ điều hành** | Xiaomi HyperOS 1.0 – 3.0 / AOSP / LineageOS / crDroid (Android 12 – 16) | Tự động nhận diện hồ sơ ROM phù hợp |

---

## 🚀 Cài Đặt & Nâng Cấp

### 1. Chuẩn bị môi trường nền tảng
Cài đặt các module nền tảng qua trình quản lý root:
- **Zygisk Next** — [GitHub Releases](https://github.com/LSPosed/ZygiskNext/releases)
- **HMA-OSS** — [GitHub Releases](https://github.com/frknkrc44/HMA-OSS/releases)
- **susfs4ksu** — [GitHub Releases](https://github.com/sidex15/susfs4ksu-module) *(nếu dùng kernel có hỗ trợ SuSFS)*

### 2. Cài đặt HyperOS & AOSP Compatibility Layer
1. Tải bản phát hành mới nhất: [`HyperOS-Compatibility-Layer-v1.3.4.zip`](https://github.com/minhtritt1996/HCL-Module/releases/latest)
2. Mở KernelSU / APatch / Magisk Manager → **Modules** → **Cài đặt từ bộ nhớ**.
3. Chọn gói ZIP vừa tải và tiến hành cài đặt.
4. Khởi động lại thiết bị.

> [!NOTE]
> **Nâng cấp từ phiên bản tiền nhiệm (v1.2.x / v1.3.x):**
> Module tích hợp sẵn bộ chuyển đổi thông minh (Migration Logic). Khi cài đặt bản `v1.3.4`, hệ thống sẽ tự động phát hiện, vô hiệu hóa và dọn dẹp cấu hình của module cũ, đồng thời tự động bảo toàn danh sách cấu hình SuSFS trên mọi lần khởi động lại máy.

---

## ⚙️ Cấu Hình Môi Trường Ứng Dụng

### Quản lý danh sách ứng dụng với HMA-OSS (Whitelist)

Để tối ưu hóa sự tương thích và tránh các ứng dụng đọc danh sách phần mềm không liên quan:
1. Mở HMA-OSS → Chọn ứng dụng cần cấu hình kiểm thử → Bật **Chế độ Danh sách trắng (Whitelist Mode)**.
2. Áp dụng các mẫu (Presets): `Custom ROM`, `Root Apps`, `Xposed`, `Dev Options`.
3. **Thêm vào danh sách ứng dụng được phép thấy (Extra App List):**
   - `com.google.android.webview`
   - `com.google.android.gms`
   - `com.android.vending`

### Lưu ý về Xác thực KeyStore Phần Cứng

Các ứng dụng bảo mật cao (ngân hàng số, chứng thư điện tử) dựa trên cơ chế đối soát khóa phần cứng (Hardware-backed KeyStore) liên kết trực tiếp với TEE của vi xử lý:
- Không nên can thiệp hoặc áp dụng các chứng chỉ keybox ảo lên các ứng dụng này, vì việc giả lập khóa không khớp với phần cứng thực tế có thể dẫn đến lỗi xác thực khóa (`KeyPermanentlyInvalidatedException`).
- Giữ nguyên trạng thái phần cứng tự nhiên kết hợp với lớp chuẩn hóa thuộc tính của module là giải pháp an toàn và ổn định nhất.

---

## ✅ Kiểm Tra Nhanh Tính Tương Thích

| Mục kiểm tra | Trạng thái tiêu chuẩn | Lệnh kiểm tra qua Terminal / ADB |
|---|---|---|
| **Trạng thái SELinux** | `Enforcing` | `su -c "getenforce"` |
| **Máy chủ Build** | Máy chủ chính thức Xiaomi | `su -c "getprop ro.build.host"` |
| **Cờ kiểm thử (Debug)** | `ro.debuggable=0`, `ro.build.type=user` | `su -c "getprop ro.build.type"` |
| **Thuộc tính ROM mod** | Đã được chuẩn hóa | `su -c "getprop \| grep -iE 'xiaomi\.eu\|hypertn\|eliterom'"` |
| **Thành phần phụ trợ ROM** | Đã được cách ly qua SuSFS | `su -c "ls /product/priv-app/XiaomiEUExt"` → báo không tồn tại |

---

## 📱 Thiết Bị & Môi Trường Đã Thử Nghiệm

| Thiết bị | Codename | Hệ điều hành & ROM | Môi trường Root | Kernel SuSFS | Trạng thái kiểm thử tương thích |
|---|---|---|---|---|---|
| **POCO F5 Pro** | `mondrian` | Xiaomi.eu HyperOS 3.0 (Android 15) | KernelSU + Wild Kernel | Có | **Tương thích hoàn toàn** (Định danh điện tử, Ngân hàng số, Google Services) |

---

## ❓ Câu Hỏi Thường Gặp (FAQ)

<details>
<summary><b>1. Module có hoạt động nếu kernel không có SuSFS?</b></summary>

Có. Cơ chế Lớp 1 (chuẩn hóa thuộc tính qua `resetprop`) hoạt động ổn định trên mọi giải pháp root. Kernel có SuSFS bổ sung thêm khả năng cách ly đường dẫn và chuyển hướng đọc tệp ở cấp kernel cho các ứng dụng thực hiện kiểm tra sâu qua C/C++ native.
</details>

<details>
<summary><b>2. Module có gây nguy cơ bootloop hoặc ảnh hưởng đến sóng di động không?</b></summary>

Tuyệt đối an toàn. Module tuân thủ nguyên tắc thiết kế nghiêm ngặt:
1. Chỉ kích hoạt sau khi hệ thống hoàn tất khởi động (`sys.boot_completed=1`), không can thiệp giai đoạn sớm (`post-fs-data`).
2. Tự động nhận diện và bảo toàn nguyên vẹn hậu tố phân vùng mạng (`_global`, `_eea_global`, `_in_global`) trong `ro.product.mod_device`.
3. Chỉ áp dụng chuyển hướng tệp cho ứng dụng không gian người dùng (`uid >= 10000`).
</details>

<details>
<summary><b>3. Module có thực hiện kết nối mạng hoặc thu thập dữ liệu không?</b></summary>

Không. Dịch vụ tương thích chạy hoàn toàn cục bộ, không có telemetry, không có cơ chế gửi log hay kết nối mạng ngầm. Xem thêm [PRIVACY.md](PRIVACY.md) và [SECURITY.md](SECURITY.md).
</details>

---

## ⚠️ Tuyên Bố Miễn Trừ Trách Nhiệm (Disclaimer)

> [!WARNING]
> **HyperOS Compatibility Layer là một dự án phần mềm mã nguồn mở độc lập.**
> - Dự án **không liên kết, không được bảo trợ hoặc ủy quyền** bởi Xiaomi Inc., Google LLC, hay bất kỳ cơ quan chính phủ, ngân hàng hoặc tổ chức tài chính nào.
> - Dự án cung cấp công cụ tương thích và chuẩn hóa môi trường cho thiết bị cá nhân thuộc quyền sở hữu của người dùng.
> - Tính tương thích với các ứng dụng bên thứ ba không được cam kết tuyệt đối và có thể thay đổi khi các ứng dụng đó cập nhật chính sách bảo mật hoặc cấu hình máy chủ.
> 
> Vui lòng tham khảo các tài liệu pháp lý & an toàn:
> - [Tuyên Bố Miễn Trừ Trách Nhiệm (DISCLAIMER.md)](DISCLAIMER.md)
> - [Ranh Giới An Toàn & Threat Model (SECURITY.md)](SECURITY.md)
> - [Chính Sách Quyền Riêng Tư (PRIVACY.md)](PRIVACY.md)
> - [Thông Báo Nhãn Hiệu (TRADEMARKS.md)](docs/TRADEMARKS.md)

---

## 🤝 Đóng Góp & Hợp Tác

Mọi đóng góp nhằm hỗ trợ thêm các phiên bản HyperOS mới, các bản ROM mới và hoàn thiện tài liệu đều được chào đón! Vui lòng đọc kỹ [CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## 📄 Giấy Phép Mã Nguồn

Dự án được phân phối dưới giấy phép **[MIT License](LICENSE)** — Bản quyền © 2026 [minhtritt1996](https://github.com/minhtritt1996).
