<div align="center">

# 🛡️ HyperOS & AOSP Compatibility Layer (HCL)

**Framework chuẩn hóa môi trường runtime, điều phối chứng thực bảo mật và tăng cường tính tương thích cho Xiaomi HyperOS cùng các bản ROM tùy biến AOSP (LineageOS, crDroid...).**

<p align="center">
  <a href="https://github.com/minhtritt1996/HCL-Module">
    <img src="https://img.shields.io/badge/GitHub-Kho_Mã_Nguồn-181717?style=for-the-badge&logo=github&logoColor=white" alt="Truy cập Repo" />
  </a>
  <a href="https://github.com/minhtritt1996/HCL-Module/releases/latest">
    <img src="https://img.shields.io/badge/Tải_Về_Mới_Nhất-v1.4.3-2ea44f?style=for-the-badge&logo=github&logoColor=white" alt="Tải về mới nhất" />
  </a>
</p>

[![Phiên bản](https://img.shields.io/badge/phiên_bản-v1.4.3-blue?style=flat-square)](https://github.com/minhtritt1996/HCL-Module/releases)
[![Giấy phép](https://img.shields.io/badge/giấy_phép-MIT-green?style=flat-square)](LICENSE)
[![Disclaimer](https://img.shields.io/badge/pháp_lý-Disclaimer-yellow?style=flat-square)](DISCLAIMER.md)
[![Security](https://img.shields.io/badge/bảo_mật-Security_Boundaries-blueviolet?style=flat-square)](SECURITY.md)
[![Privacy](https://img.shields.io/badge/quyền_riêng_tư-Zero_Telemetry-brightgreen?style=flat-square)](PRIVACY.md)
[![Root](https://img.shields.io/badge/root-KernelSU_%7C_APatch_%7C_Magisk-red?style=flat-square)](#-yêu-cầu-hệ-thống)

Dự án cung cấp cơ chế chuẩn hóa môi trường Android cục bộ thông minh (Smart Environment Detection & Multi-Partition Normalization), giải quyết triệt để sự sai lệch thuộc tính giữa các phân vùng, cách ly thành phần đặc thù của ROM tùy biến, tích hợp bảng điều khiển WebUI hiện đại và đồng bộ ma trận chứng thực phần cứng Keystore.

</div>

---

## 🌐 Phạm Vi Hỗ Trợ

```
Hệ Điều Hành & Bản ROM
├── Xiaomi HyperOS & MIUI
│   ├── Xiaomi.eu (HyperOS 1.0 / 2.0 / 3.0)
│   ├── HyperTN / TN ToolBox
│   ├── EliteROM
│   ├── MiPA
│   ├── Pulse
│   └── HyperOS Ports (Flagship cross-device ports)
└── AOSP & AOSP-based Custom ROMs
    ├── LineageOS (Android 12 – 16)
    ├── crDroid
    ├── PixelExperience / PixelOS
    ├── EvolutionX
    └── Generic AOSP / GSI (Treble)
```

---

## 🧪 Lĩnh Vực Kiểm Thử Tương Thích (Compatibility Testing)

HCL-Module được thiết kế nhằm phục vụ kiểm thử tính toàn vẹn và độ tương thích môi trường diện rộng:

```
Compatibility Testing
├── Identity applications (Định danh điện tử, dịch vụ công: VNeID...)
├── Banking & Fintech applications (Sacombank Pay, Vietcombank, Techcombank, MB Bank, MoMo...)
├── Enterprise applications (Phần mềm doanh nghiệp, VPN, quản trị nội bộ)
├── Device management applications (MDM, Work Profile, EMM tương thích)
└── Android system services (Google Play Services, WebView, Play Integrity baseline)
```

---

## 📖 Mục Lục

- [Mục Đích Dự Án](#-mục-đích-dự-án)
- [Kiến Trúc Kỹ Thuật Đa Tầng](#-kiến-trúc-kỹ-thuật-đa-tầng)
- [Tính Năng Nổi Bật](#-tính-năng-nổi-bật)
- [Bảng Điều Khiển WebUI](#-bảng-điều-khiển-webui)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Cài Đặt & Hướng Dẫn Sử Dụng](#-cài-đặt--hướng-dẫn-sử-dụng)
- [Kiểm Tra Nhanh Sau Khi Cài Đặt](#-kiểm-tra-nhanh-sau-khi-cài-đặt)
- [Thiết Bị Đã Thử Nghiệm Thực Tế](#-thiết-bị-đã-thử-nghiệm-thực-tế)
- [Câu Hỏi Thường Gặp (FAQ)](#-câu-hỏi-thường-gặp-faq)
- [Tài Liệu Kỹ Thuật Chi Tiết (docs/TECHNICAL.md)](docs/TECHNICAL.md)
- [Tuyên Bố Miễn Trừ Trách Nhiệm](DISCLAIMER.md)

---

## ❓ Mục Đích Dự Án

Trong các bản ROM tùy biến (cả **Xiaomi HyperOS** và **AOSP**), các bản dựng thường phát sinh các điểm dị thường so với thiết bị thương mại nguyên bản (Stock Firmware):
1. **Lệch thuộc tính chéo giữa các phân vùng:** Phân vùng `product` hoặc `system` mang tên mã build khác (`miproduct`, `mainline`, `generic`) so với `vendor` hoặc `system_ext`.
2. **Lệch Fingerprint phân vùng:** Một số phân vùng giữ fingerprint generic khiến các thư viện bảo vệ tính toàn vẹn cấp native đối soát và kích hoạt mã lỗi ROM tùy biến (ví dụ: `CA-E012`).
3. **Thành phần phụ trợ rò rỉ:** Các gói APK bổ trợ của bản mod (`XiaomiEUExt`, `XiaomiEUInject`, `MiuiExtraPhoto`, OTA Updaters, `addon.d`...) để lộ dấu vết ROM tùy biến.
4. **Xung đột chứng thực Keystore:** Các công cụ giả lập chứng thực phần cứng (Tricky Store / AlwaysStrong) thường tự động quét và đưa bừa bãi toàn bộ ứng dụng ngân hàng vào danh sách giả lập, gây lỗi xung đột khóa phần cứng.

**HyperOS & AOSP Compatibility Layer** ra đời nhằm giải quyết toàn diện các vấn đề trên mà không can thiệp đè lên phân vùng hệ thống vật lý.

---

## ⚙️ Kiến Trúc Kỹ Thuật Đa Tầng

```
┌────────────────────────────────────────────────────────────────────────┐
│                        KHÔNG GIAN ỨNG DỤNG NGƯỜI DÙNG                  │
│       (VNeID, Ngân Hàng Số, Ví Điện Tử, Dịch Vụ Doanh Nghiệp)          │
└──────────────────┬─────────────────────────────┬───────────────────────┘
                   │                             │
    Đọc qua SystemProperties          Đọc qua sys_open("/system/build.prop")
                   │                             │
┌──────────────────▼───────────────────┐ ┌───────▼────────────────────────┐
│ Lớp 1: Chuẩn Hóa Thuộc Tính Bộ Nhớ   │ │ Lớp 2: Góc Nhìn Tương Thích     │
│ • RAM volatile memory (resetprop)    │ │ • SuSFS open_redirect          │
│ • Đồng bộ Fingerprint mọi phân vùng  │ │ • UID Scheme 3 (uid ≥ 10000)   │
│ • Khử bỏ mainline, miproduct, qssi   │ │ • hyperos_compat_build.prop     │
│ • Chuẩn hóa Boot Security & Uname   │ │ • Daemon init/rild không bị ảnh │
│                                      │ │   hưởng                        │
└──────────────────────────────────────┘ └────────────────────────────────┘
                   │
    Truy vấn đường dẫn tệp trong /product, /system_ext, /system
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 3: Cách Ly Thành Phần ROM Tùy Biến (SuSFS sus_path)                │
│ • Quét động: XiaomiEUExt, XiaomiEUInject, MiuiExtraPhoto, addon.d...   │
│ • Trả về ENOENT cho scanner của ứng dụng trong khi HĐH vẫn hoạt động    │
└────────────────────────────────────────────────────────────────────────┘
                   │
    Yêu cầu chứng thực KeyStore / TEE Hardware Attestation
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 4: Ma Trận Điều Phối Chứng Thực (attest_sync.sh)                   │
│ • Giả lập phần cứng mục tiêu (target.txt) vượt Play Integrity          │
│ • Khóa bảo vệ Keystore gốc (app_keybox.map với cờ off) chặn giả lập bừa│
│ • Tự động nhận diện Fintech/Banking và đồng bộ spoof.conf              │
└────────────────────────────────────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────┐ ┌────────────────────────────────┐
│ Lớp 5: Daemon Giám Sát Nền           │ │ Lớp 6: Bảng Điều Khiển WebUI   │
│ • guardian.sh theo dõi packages.xml  │ │ • Quản lý trực quan Hot-Reload │
│ • Tự động đồng bộ khi cài/gỡ app     │ │ • Không cần reboot khi lưu     │
└──────────────────────────────────────┘ └────────────────────────────────┘
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 7: Khởi Động An Toàn Tuyệt Đối (post-fs-data.sh Stub)             │
│ • Stub siêu nhẹ non-blocking, bảo vệ 100% không bootloop / treo init   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🌟 Tính Năng Nổi Bật

- **Đồng bộ hóa Fingerprint đa phân vùng tuyệt đối:** Ép toàn bộ các phân vùng `system`, `system_ext`, `product`, `vendor`, `odm`, `bootimage`, `vendor_dlkm`, `odm_dlkm` về cùng một fingerprint chính thức.
- **Làm sạch định danh phần cứng:** Chuẩn hóa Model, Device, Name, Brand, Manufacturer, loại bỏ hoàn toàn các chuỗi lạ như `mainline`, `miproduct`, `missi`, `qssi`.
- **Bảo toàn trạng thái Bootloader & Integrity:** Thiết lập trạng thái bảo mật chuẩn (`bootloader locked`, `ro.boot.verifiedbootstate=green`, `ro.secure=1`, `sys.oem_unlock_allowed=0`).
- **Giả lập Kernel Uname thông minh:** Khử các đuôi tùy biến (như `dirty`, `lineage`, `wild`, `custom`) và đồng bộ ngày build theo thời gian chuẩn UTC.
- **Tách biệt 2 danh sách bảo mật rõ ràng:**
  - *Ứng dụng giả lập phần cứng (`target.txt`):* Dành cho các ứng dụng cần vượt kiểm tra tính toàn vẹn (Play Integrity, VNeID khóa bootloader...).
  - *Ứng dụng bảo vệ Keystore gốc (`app_keybox.map` gắn nhãn `off`):* Tấm khiên ngăn chặn các module như AlwaysStrong tự động quét và đưa các app ngân hàng nhạy cảm vào giả lập.
- **Cơ chế Hot-Reload không cần khởi động lại:** Khi lưu quy tắc trên WebUI, hệ thống tự động làm mới tiến trình (`am force-stop`) để áp dụng cấu hình ngay lập tức.
- **Chống Bootloop triệt để:** Script `post-fs-data.sh` không gọi bất kỳ lệnh framework Android nào (`pm`), loại bỏ hoàn toàn hiện tượng deadlock khởi động.

---

## 🖥️ Bảng Điều Khiển WebUI

Module tích hợp giao diện WebUI trực quan chạy trực tiếp bên trong trình quản lý KernelSU / APatch hoặc trình duyệt:

1. **Tab Tổng quan (Overview):**
   - Theo dõi trạng thái hoạt động của module và môi trường ROM (HyperOS / AOSP).
   - Kiểm tra trạng thái tiến trình Guardian Daemon.
   - Thống kê thời gian thực số lượng ứng dụng đang giả lập phần cứng và số lượng ứng dụng được bảo vệ Keystore gốc.
   - Hiển thị thông tin Kernel thực tế và phiên bản Uname đã được chuẩn hóa.

2. **Tab Chứng thực & Ứng dụng (Attestation & Apps):**
   - **Thanh Lưu & Áp dụng thay đổi:** Nút bấm trung tâm hỗ trợ lưu toàn bộ quy tắc vào `target.txt`, `app_keybox.map`, `config.json` và kích hoạt ngay mà không cần reboot.
   - **Khu vực Ứng dụng giả lập phần cứng:** Chọn app cài trong máy qua trình chọn trực quan (`+ Chọn từ máy`), nhập thủ công, chọn tất cả, xóa mục tiêu đã chọn.
   - **Khu vực Ứng dụng bảo vệ Keystore gốc:** Khóa các ứng dụng ngân hàng nhạy cảm để giữ nguyên Keystore phần cứng của máy.

3. **Tab Phần cứng & Hệ thống (Hardware & System):**
   - Tùy chỉnh thông số thiết bị thủ công (`custom_device`, `custom_model`).
   - Bật/tắt chuẩn hóa Uname Kernel.
   - Cấu hình chu kỳ quét và bật/tắt tiến trình giám sát Guardian Daemon.
   - Tùy chọn tự động nhận diện ứng dụng tài chính / fintech.

4. **Tab Nhật ký (Live Logs):**
   - Xem toàn bộ nhật ký thực thi thời gian thực của module.
   - Hỗ trợ sao chép log nhanh để phục vụ chẩn đoán và gỡ lỗi.

---

## 📋 Yêu Cầu Hệ Thống

| Thành phần | Yêu cầu | Ghi chú |
|---|---|---|
| **Root Solution** | KernelSU / KernelSU Next / APatch / Magisk (v26+) | Quản lý quyền root và thực thi dịch vụ nền |
| **Zygisk** | Zygisk Next (khuyến nghị) hoặc Magisk Zygisk | Cách ly môi trường thực thi ứng dụng |
| **Kernel SuSFS** *(Khuyến nghị)* | Kernel hỗ trợ SuSFS (Wild Kernel, ShirkNeko...) | Cung cấp Lớp 2 (Chuyển hướng tệp) và Lớp 3 (Cách ly thành phần) |
| **susfs4ksu** | Module susfs4ksu (nếu dùng kernel SuSFS) | Tự động đồng bộ các quy tắc cấu hình kernel |
| **Hệ điều hành** | Xiaomi HyperOS 1.0 – 3.0 / AOSP / LineageOS / crDroid (Android 12 – 16) | Tự động nhận diện hồ sơ ROM phù hợp |

---

## 🚀 Cài Đặt & Hướng Dẫn Sử Dụng

### 1. Cài đặt qua Root Manager
1. Tải bản phát hành mới nhất [HCL-Module v1.4.3 ZIP](https://github.com/minhtritt1996/HCL-Module/releases/latest).
2. Mở trình quản lý root (KernelSU / APatch / Magisk) → mục **Modules** → chọn **Cài đặt từ bộ nhớ**.
3. Chọn tệp ZIP vừa tải và hoàn tất cài đặt.
4. Khởi động lại thiết bị.

### 2. Sử dụng qua WebUI hoặc Menu CLI
- **Mở WebUI:** Mở KernelSU / APatch Manager → vào module **HyperOS Compatibility Layer** → nhấn nút **WebUI** (hoặc mở biểu tượng giao diện web).
- **Menu CLI (Action Key):** Nhấn nút [Action] trong danh sách module hoặc chạy lệnh trong terminal:
  ```bash
  su -c "sh /data/adb/modules/hyperos_compat/action.sh"
  ```

---

## 🔍 Kiểm Tra Nhanh Sau Khi Cài Đặt

Kiểm tra sự đồng bộ và tương thích qua Termux / ADB:

```bash
# 1. Kiểm tra tính đồng nhất của Fingerprint trên các phân vùng
su -c "getprop | grep -E 'ro\.(product\.[a-z_]+\.model|build\.fingerprint)'"

# 2. Kiểm tra thuộc tính model và mod_device
su -c "getprop ro.product.model"
su -c "getprop ro.product.mod_device"

# 3. Kiểm tra tính toàn vẹn trạng thái khởi động
su -c "getprop ro.boot.verifiedbootstate"

# 4. Kiểm tra quy tắc SuSFS (nếu dùng Kernel SuSFS)
su -c "ksu_susfs show version"
su -c "cat /data/adb/susfs4ksu/sus_open_redirect.txt"
su -c "cat /data/adb/susfs4ksu/sus_path.txt"
```

---

## 📱 Thiết Bị Đã Thử Nghiệm Thực Tế

| Thiết bị | Codename | Hệ điều hành & ROM | Môi trường Root | Kernel SuSFS | Trạng thái kiểm thử |
|---|---|---|---|---|---|
| **POCO F5 Pro** | `mondrian` | Xiaomi.eu HyperOS 3.0 (Android 15) | KernelSU + Wild Kernel | Có | **Hoạt động hoàn hảo (VNeID + Sacombank Pay OK)** |

---

## ❓ Câu Hỏi Thường Gặp (FAQ)

<details>
<summary><b>1. Vì sao danh sách "Ứng dụng giả lập phần cứng" lại giống danh sách của AlwaysStrong?</b></summary>

Cả HCL-Module và AlwaysStrong đều cùng đọc và tương tác trên tệp trung tâm `/data/adb/tricky_store/target.txt`. HCL-Module đóng vai trò là bảng điều khiển WebUI trực quan và tầng lọc bảo vệ, giúp bạn dễ dàng chọn/xóa app và ngăn ngừa các xung đột khóa bảo mật.
</details>

<details>
<summary><b>2. Tại sao tôi xóa hết ứng dụng rồi reboot thì danh sách lại tự khôi phục?</b></summary>

Module AlwaysStrong có tiến trình nền `aswatcher` tự động quét các app bên thứ 3 và thêm lại vào `target.txt`, TRỪ KHI app đó được gắn cờ `off` trong `app_keybox.map`. Khi bạn xóa sạch cả danh sách "Bảo vệ Keystore gốc", AlwaysStrong sẽ tự động quét và khôi phục lại danh sách giả lập. Để giữ app dùng Keystore gốc vĩnh viễn, hãy luôn để app đó trong danh sách "Ứng dụng bảo vệ Keystore gốc".
</details>

<details>
<summary><b>3. Module có nguy cơ gây bootloop không?</b></summary>

Không. Kể từ phiên bản v1.4.3, script `post-fs-data.sh` được tinh gọn thành stub siêu nhẹ (`mkdir -p`), tuyệt đối không gọi `pm` hay framework trước khi `system_server` sẵn sàng. Mọi quy tắc chuẩn hóa đều thực thi an toàn sau khi Android báo hoàn tất khởi động (`sys.boot_completed=1`).
</details>

---

## ⚠️ Tuyên Bố Miễn Trừ Trách Nhiệm (Disclaimer)

> [!WARNING]
> **HyperOS Compatibility Layer là một dự án phần mềm mã nguồn mở độc lập.**
> - Dự án **không liên kết, không được bảo trợ hoặc ủy quyền** bởi Xiaomi Inc., Google LLC, Bộ Công An, Sacombank hay bất kỳ tổ chức nào.
> - Dự án được phát triển phục vụ mục đích nghiên cứu, tối ưu hóa tương thích hệ thống trên thiết bị cá nhân thuộc sở hữu hợp pháp của người dùng.
> - Tham khảo thêm chi tiết tại:
>   - [Tuyên Bố Miễn Trừ Trách Nhiệm (DISCLAIMER.md)](DISCLAIMER.md)
>   - [Ranh Giới An Toàn & Threat Model (SECURITY.md)](SECURITY.md)
>   - [Chính Sách Quyền Riêng Tư (PRIVACY.md)](PRIVACY.md)
>   - [Thông Báo Nhãn Hiệu (TRADEMARKS.md)](docs/TRADEMARKS.md)

---

## 🤝 Đóng Góp & Hợp Tác

Mọi đóng góp từ cộng đồng nhằm mở rộng hỗ trợ các dòng máy và bản ROM mới đều được chào đón! Vui lòng đọc kỹ [CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## 📄 Giấy Phép Mã Nguồn

Dự án được phân phối dưới giấy phép **[MIT License](LICENSE)** — Bản quyền © 2026 [minhtritt1996](https://github.com/minhtritt1996).
