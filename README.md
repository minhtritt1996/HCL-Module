<div align="center">

# 🛡️ Universal ROM Cloak & Banking/VNeID Fix

**Universal ROM Cloak — Module cho Magisk / KernelSU / APatch**

[![Phiên bản](https://img.shields.io/badge/phiên_bản-v1.2.0-blue?style=flat-square)](https://github.com/minhtritt1996/VNeID-Fix-Module/releases)
[![Giấy phép](https://img.shields.io/badge/giấy_phép-MIT-green?style=flat-square)](LICENSE)
[![Đã thử nghiệm](https://img.shields.io/badge/đã_thử-POCO_F5_Pro_%7C_HyperOS_3-orange?style=flat-square)](#thiết-bị-đã-thử-nghiệm)
[![Root](https://img.shields.io/badge/root-KernelSU_%7C_APatch_%7C_Magisk-red?style=flat-square)](#yêu-cầu)

Module phổ quát dành cho người dùng cài **Custom ROM (Xiaomi.eu, HyperTN, EliteROM, MiPA, Pulse, LineageOS / AOSP ports...)**, giúp tự động quét động và che giấu hoàn toàn dấu vết ROM tùy chỉnh để các ứng dụng nhạy cảm của Việt Nam hoạt động bình thường — bao gồm **VNeID** (`com.vnid`), **BIDV SmartBanking** (`com.vnpay.bidv`) và **MB Bank** (`com.mbmobile`).

</div>

---

## 📖 Mục Lục

- [Vấn đề cần giải quyết](#-vấn-đề-cần-giải-quyết)
- [Cách hoạt động](#-cách-hoạt-động)
- [Yêu cầu](#-yêu-cầu)
- [Cài đặt](#-cài-đặt)
- [Cấu hình sau khi cài](#-cấu-hình-sau-khi-cài)
- [Kiểm tra nhanh](#-kiểm-tra-nhanh)
- [Thiết bị đã thử nghiệm](#-thiết-bị-đã-thử-nghiệm)
- [Câu hỏi thường gặp](#-câu-hỏi-thường-gặp)
- [Tài liệu kỹ thuật](docs/TECHNICAL.md)
- [Đóng góp](docs/CONTRIBUTING.md)

---

## ❓ Vấn Đề Cần Giải Quyết

Khi cài **ROM Xiaomi.eu** (bản ROM Global không chính thức của Xiaomi) hoặc **Custom HyperOS / MIUI port**, các ứng dụng quan trọng sau đây sẽ từ chối khởi động:

| Ứng dụng | Thông báo lỗi |
|---|---|
| **VNeID** (`com.vnid`) | *"Thiết bị của bạn đã bị bẻ khóa / cài ROM không chính thức"* |
| **BIDV SmartBanking** (`com.vnpay.bidv`) | *"Thiết bị di động đã bị bẻ khóa và KHÔNG đủ điều kiện an toàn theo Thông tư 77/2025/TT-NHNN"* |
| **MB Bank** (`com.mbmobile`) | *"Phát hiện thiết bị root hoặc jailbreak"* |
| Các ứng dụng ngân hàng khác | Phát hiện môi trường bị can thiệp |

**Nguyên nhân gốc rễ:**

ROM Xiaomi.eu nhúng các định danh đặc trưng vào `build.prop` và cài sẵn hai APK hệ thống riêng (`XiaomiEUExt.apk`, `MiuiExtraPhoto.apk`). Các ứng dụng như VNeID sử dụng cả **Java reflection** lẫn **mã C/C++ native** để quét trực tiếp hệ thống tệp — do đó các phương pháp ẩn thông thường chỉ dựa vào `resetprop` là chưa đủ.

---

## ⚙️ Cách Hoạt Động

Module sử dụng **3 lớp che giấu thông minh** — tự động thích ứng với mọi bản ROM tùy chỉnh, không sửa phân vùng hệ thống, không overlay, hoàn toàn có thể gỡ bỏ:

```
┌──────────────────────────────────────────────────────────────────┐
│  Lớp 1: Giả mạo thuộc tính hệ thống động (RAM, resetprop)        │
│  • Quét động và xóa sạch ro.xiaomi.eu.*, ro.hypertn.*,           │
│    ro.eliterom.*, ro.mipa.*, ro.lineage.*, developerid...        │
│  • Tự động chuyển ro.build.type=user và ro.debuggable=0          │
│  • Chuẩn hóa ro.product.mod_device về chuẩn gốc Xiaomi           │
│  • Khôi phục ro.build.host về máy chủ build chính thức Xiaomi    │
│  • Giữ nguyên hậu tố vùng (_global, _eea_global...) bảo vệ sóng  │
├──────────────────────────────────────────────────────────────────┤
│  Lớp 2: Chuyển hướng đọc file build.prop (SuSFS cấp kernel)      │
│  • Tạo clean_build.prop đã lọc sạch mọi tag ROM mod khi cài đặt  │
│  • Khi app đọc /system/build.prop, kernel tự động trả về         │
│    clean_build.prop thay thế                                      │
│  • UID Scheme 3: chỉ ảnh hưởng app người dùng (uid ≥ 10000)      │
│  • KHÔNG ảnh hưởng init, rild (daemon sóng viễn thông)           │
├──────────────────────────────────────────────────────────────────┤
│  Lớp 3: Quét động và ẩn APK hệ thống mod (SuSFS cấp kernel)      │
│  • Tự động quét priv-app để tìm mọi APK mod lạ (XiaomiEUExt,     │
│    MiuiExtraPhoto, HyperTN, TNToolbox, EliteROM, MiPA,           │
│    LineageParts...) và nạp động vào sus_path                      │
│  • Ẩn hoàn toàn khỏi trình quét tệp native (C/C++) của VNeID     │
└──────────────────────────────────────────────────────────────────┘
```

> **Cơ chế khởi động an toàn:** Toàn bộ hook chỉ chạy trong `service.sh` **sau khi** `sys.boot_completed=1`. Không có gì chạy trong `post-fs-data.sh`. Điều này ngăn daemon sóng viễn thông (`rild`) bị crash, tránh bootloop và mất sóng SIM.

---

## 📋 Yêu Cầu

| Thành phần | Yêu cầu |
|---|---|
| **Root** | KernelSU / KernelSU Next / APatch / Magisk (v26+) |
| **Zygisk** | Zygisk Next (khuyến nghị) hoặc Magisk Zygisk tích hợp |
| **SuSFS** *(tùy chọn nhưng khuyến nghị)* | Kernel có hỗ trợ SuSFS (Wild Kernel, ShirkNeko, v.v.) |
| **HMA-OSS** | Hide My Applist (bản OSS Zygisk) |
| **Play Integrity** *(tùy theo ROM)* | Xem ghi chú bên dưới |
| **susfs4ksu** | Nếu dùng kernel có SuSFS |
| **Android** | Android 12 trở lên |

> **Không có SuSFS:** Module vẫn hoạt động qua `resetprop` (Lớp 1), nhưng các app dùng mã native để đọc trực tiếp `build.prop` (như VNeID v2.2.x+) có thể vẫn phát hiện ROM. Kernel có SuSFS cho phép che giấu hoàn toàn ở cấp kernel.

> **Play Integrity — ROM nào cần cài thêm gì?**
> - **ROM đã tích hợp keybox sẵn** (ví dụ: HyperTN, các bản port có TN ToolBox): **Không cần cài thêm** AlwaysStrong hay TrickyStore. ROM đã tự lo phần chứng thực Play Integrity.
> - **ROM chưa có keybox** (ví dụ: Xiaomi.eu, AOSP port thuần): Cần cài thêm **AlwaysStrong** (bao gồm cả TrickyStore + keybox) để đạt `MEETS_STRONG_INTEGRITY`.

---

## 🚀 Cài Đặt

### Bước 1 — Cài các module nền tảng

Cài các module này trước qua KernelSU / Magisk Manager:

1. **Zygisk Next** — [GitHub](https://github.com/Dr-TSNG/ZygiskNext)
2. **HMA-OSS** (Hide My Applist) — [GitHub](https://github.com/Dr-TSNG/Hide-My-Applist)
3. **susfs4ksu** — [GitHub](https://github.com/sidex15/susfs4ksu-module) *(nếu kernel hỗ trợ SuSFS)*
4. **AlwaysStrong** (TrickyStore + keybox) — [GitHub](https://github.com/evoker0/AlwaysStrong) *(chỉ cần cài nếu ROM **chưa có keybox tích hợp sẵn**, ví dụ Xiaomi.eu. Các ROM như HyperTN đã có TN ToolBox keybox — **bỏ qua bước này**)*

### Bước 2 — Cài VNeID Fix Module

1. Tải phiên bản mới nhất: [`VNeID-Fix-Module-v1.2.0.zip`](https://github.com/minhtritt1996/VNeID-Fix-Module/releases/latest)
2. Mở KernelSU / APatch / Magisk Manager → **Modules** → **Cài từ bộ nhớ**
3. Chọn file ZIP vừa tải
4. Khởi động lại máy


---

## ⚙️ Cấu Hình Sau Khi Cài

### HMA-OSS (Hide My Applist)

Cấu hình cho **VNeID, BIDV và MB Bank** trong HMA-OSS:

1. Mở HMA-OSS → chọn ứng dụng cần bảo vệ (`com.vnid`, `com.vnpay.bidv`, `com.mbmobile`) → bật **Chế độ Danh sách trắng (Whitelist)**.
2. Áp dụng các mẫu (Presets): `Custom ROM`, `Detector Apps`, `Root Apps`, `Shizuku/Dhizuku`, `Sus Apps`, `Xposed`, `Dev Options`.
3. **Ứng dụng được phép nhìn thấy** (Extra App List):
   - `com.google.android.webview`
   - `com.google.android.gms`
   - `com.android.vending`

> [!TIP]
> Bạn có thể vào mục **Quản lý mẫu** trong HMA-OSS để tạo một mẫu Whitelist dùng chung (ví dụ: `Banking_Shield` chứa 3 app Google ở trên). Với các app ngân hàng cài sau này, chỉ cần chọn áp dụng mẫu là xong, không phải chọn lại từng app.

### Lưu ý quan trọng với module AlwaysStrong & App Ngân Hàng

Module AlwaysStrong có cơ chế tự động quét và thêm tất cả ứng dụng trên máy vào `/data/adb/tricky_store/target.txt`.
- Các ứng dụng ngân hàng như **BIDV** (`com.vnpay.bidv`) và **MB Bank** (`com.mbmobile`) có cơ chế tự kiểm tra chứng chỉ KeyStore phần cứng. Khi bị Tricky Store can thiệp keybox ảo, app sẽ báo *"Thiết bị bị bẻ khóa"* hoặc lỗi xác thực (`KeyPermanentlyInvalidatedException`).
- **Cách xử lý:** Nếu sau khi cài AlwaysStrong mà BIDV hoặc MB Bank báo bẻ khóa, bạn chỉ cần mở file `/data/adb/tricky_store/target.txt` và **xóa dòng `com.vnpay.bidv` và `com.mbmobile`** đi.
- **Về Tùy chọn nhà phát triển (Developer Options) & ADB:** Nhờ đã áp dụng preset `dev_options` trong HMA-OSS, hệ thống sẽ tự động giả lập báo Tùy chọn nhà phát triển và Gỡ lỗi ADB ở trạng thái TẮT cho các app này. Bạn hoàn toàn có thể **bật Developer Options / USB Debugging** trên máy để dùng bình thường mà không bị MB Bank phát hiện!

### BIDV & MB Bank — Loại trừ TN ToolBox (ROM có tích hợp Keybox)

Nếu ROM có tính năng TN ToolBox Keybox, chạy lệnh sau để loại trừ cả BIDV và MB Bank:

```bash
su -c "settings put global tn_keybox_out \
  \"\$(settings get global tn_keybox_out),com.vnpay.bidv,com.mbmobile\""
```

---

## ✅ Kiểm Tra Nhanh

| Mục kiểm tra | Kết quả cần đạt | Lệnh kiểm tra |
|---|---|---|
| **SELinux** | `Enforcing` | `su -c "getenforce"` |
| **Play Integrity** | MEETS_DEVICE & STRONG | App Play Integrity Checker |
| **Build host** | `c5-build-66.bj.xiaomi.com` | `su -c "getprop ro.build.host"` |
| **Dấu vết Xiaomi.eu** | Không có | `su -c "getprop \| grep -i xiaomi.eu"` |
| **XiaomiEUExt** | Đã ẩn | `su -c "ls /product/priv-app/XiaomiEUExt"` → báo lỗi |
| **Tùy chọn nhà phát triển & ADB** | Được HMA ẩn | Tự động ẩn qua preset `dev_options` (không cần tắt trong Cài đặt) |

---

## 📱 Thiết Bị Đã Thử Nghiệm

| Thiết bị | Codename | ROM | Root | SuSFS | VNeID | BIDV | MB Bank |
|---|---|---|---|---|---|---|---|
| POCO F5 Pro | `mondrian` | Xiaomi.eu HyperOS 3.0 (Android 15) | KernelSU + Wild Kernel | ✅ v2.3.0 | ✅ | ✅ | ✅ |

> Muốn thêm thiết bị của bạn? Xem [CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## ❓ Câu Hỏi Thường Gặp

<details>
<summary><b>Module có hoạt động không nếu máy không có SuSFS?</b></summary>

Có, nhưng bảo vệ sẽ không đầy đủ. Không có SuSFS, chỉ Lớp 1 (`resetprop`) được áp dụng. Các app dùng mã native để `open()` và đọc trực tiếp `/system/build.prop` (như scanner C trong VNeID v2.2.x+) vẫn sẽ thấy file gốc. Kernel có SuSFS cung cấp lớp bảo vệ đầy đủ ở cấp kernel.
</details>

<details>
<summary><b>Tại sao module không có thư mục /system? (cảnh báo mount: false)</b></summary>

Đây là thiết kế có chủ ý. Nếu có thư mục `/system`, module sẽ yêu cầu một metamodule (như Magic Mount) và hiện cảnh báo *"module không được mount vì metamodule chưa cài"* trong KernelSU/ReSukiSU. Module này hoạt động thuần script (`mount: false`), xử lý mọi thứ qua `resetprop` và SuSFS hook — không cần overlay filesystem.
</details>

<details>
<summary><b>Tôi bị bootloop sau khi cài!</b></summary>

Điều này không nên xảy ra với v1.1.0. Nếu có:
1. Khởi động vào Recovery
2. Vào thư mục `/data/adb/modules/xiaomieu_vneid_cloak/`
3. Tạo file rỗng tên `disable`
4. Khởi động lại

Nguyên nhân bootloop từng gặp ở phiên bản cũ là chạy `open_redirect` trong `post-fs-data.sh` trước khi phân vùng modem sẵn sàng. v1.1.0 chỉ chạy mọi thứ trong `service.sh` sau khi boot hoàn tất.
</details>

<details>
<summary><b>SIM mất sóng sau khi cài!</b></summary>

Đảm bảo module không xóa hậu tố `_global` khỏi `ro.product.mod_device`. Với các máy Global (như POCO F5 Pro `mondrian_global`), module giữ nguyên `_global` để cấu hình carrier (Viettel, VinaPhone, MobiFone) không bị sai. Nếu bạn gặp vấn đề này, xem [docs/TECHNICAL.md](docs/TECHNICAL.md#modem-safety).
</details>

<details>
<summary><b>Kết quả Play Integrity hiện UNEVALUATED là sao?</b></summary>

`UNEVALUATED` xuất hiện khi Google Play Services không kết nối được đến máy chủ xác thực của Google — thường xảy ra khi mạng chưa ổn định, vừa thay SIM, hoặc vừa bật/tắt chế độ máy bay. Không liên quan đến module này. Kiểm tra lại khi mạng ổn định là sẽ về `MEETS_DEVICE_INTEGRITY` / `MEETS_STRONG_INTEGRITY` bình thường.
</details>

<details>
<summary><b>Module này có dùng được trên HyperTN, EliteROM, LineageOS hoặc các ROM mod khác không?</b></summary>

**Có! Từ phiên bản v1.2.0 Universal**, module đã được thiết kế hoàn toàn động để tương thích với tất cả các bản ROM:
- **Tự động quét động priv-app:** Tự động tìm kiếm các app đặc thù của ROM mod (`*xiaomieu*`, `*extraphoto*`, `*hypertn*`, `*tntoolbox*`, `*eliterom*`, `*mipa*`, `*lineageparts*`...) và thêm vào `sus_path`.
- **Tự động làm sạch properties:** Tự động lọc và xóa mọi prop của ROM mod (`ro.hypertn.*`, `ro.eliterom.*`, `ro.mipa.*`, `ro.lineage.*`, `ro.xiaomi.eu.*`...).
- **Xử lý ROM Userdebug / Debuggable:** Tự động ép `ro.build.type` về `user` và `ro.debuggable` về `0` (vốn là dấu hiệu đặc trưng khiến app ngân hàng chặn trên LineageOS/AOSP).
- **Chuẩn hóa mod_device thông minh:** Tự động nhận diện thiết bị và giữ nguyên cấu hình modem carrier (`_global`, `_eea_global`, `_in_global`...).
</details>

---

## 🤝 Đóng Góp

Mọi Pull Request đều được chào đón! Vui lòng đọc [CONTRIBUTING.md](docs/CONTRIBUTING.md) trước.

- Tìm thấy lỗi? [Mở issue](https://github.com/minhtritt1996/VNeID-Fix-Module/issues)
- Đã thử nghiệm trên thiết bị mới? Gửi PR thêm thiết bị vào bảng tương thích
- Muốn thêm hỗ trợ LineageOS? Xem các issue đang mở

---

## 📄 Giấy Phép

[MIT License](LICENSE) — © 2026 [minhtritt1996](https://github.com/minhtritt1996)
