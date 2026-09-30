# Tài Liệu Kỹ Thuật (Technical Documentation)

**HyperOS Compatibility Layer** — Framework kỹ thuật chuẩn hóa môi trường runtime và tăng cường tính tương thích cho Xiaomi HyperOS và các bản ROM tùy biến.

---

## 📖 Mục Lục 12 Chuyên Mục

1. [Kiến Trúc Tổng Quan (Architecture Overview)](#1-kiến-trúc-tổng-quan-architecture-overview)
2. [Khác Biệt Môi Trường Trên Custom HyperOS (HyperOS Environment Differences)](#2-khác-biệt-môi-trường-trên-custom-hyperos-hyperos-environment-differences)
3. [Chuẩn Hóa Thuộc Tính Hệ Thống (Property Normalization)](#3-chuẩn-hóa-thuộc-tính-hệ-thống-property-normalization)
4. [Góc Nhìn Tệp Cấu Hình Tương Thích (Compatibility Build.prop View)](#4-góc-nhìn-tệp-cấu-hình-tương-thích-compatibility-buildprop-view)
5. [Tích Hợp SuSFS Cấp Kernel (SuSFS Integration)](#5-tích-hợp-susfs-cấp-kernel-susfs-integration)
6. [Cách Ly Thành Phần Phụ Trợ Của ROM (ROM Component Isolation)](#6-cách-ly-thành-phần-phụ-trợ-của-rom-rom-component-isolation)
7. [Vòng Đời Khởi Động & An Toàn Modem (Boot Lifecycle & Modem Safety)](#7-vòng-đời-khởi-động--an-toàn-modem-boot-lifecycle--modem-safety)
8. [Tự Động Nhận Diện Nền Tảng Root (Root Backend Detection)](#8-tự-động-nhận-diện-nền-tảng-root-root-backend-detection)
9. [Mô Hình An Toàn Hệ Thống (Safety Model)](#9-mô-hình-an-toàn-hệ-thống-safety-model)
10. [Cơ Chế Phục Hồi & Gỡ Bỏ (Rollback / Uninstall)](#10-cơ-chế-phục-hồi--gỡ-bỏ-rollback--uninstall)
11. [Chẩn Đoán & Gỡ Lỗi An Toàn (Debugging & Diagnostics)](#11-chẩn-đoán--gỡ-lỗi-an-toàn-debugging--diagnostics)
12. [Ma Trận Tương Thích (Compatibility Matrix)](#12-ma-trận-tương-thích-compatibility-matrix)

---

## 1. Kiến Trúc Tổng Quan (Architecture Overview)

Dự án được cấu trúc theo mô hình **3 lớp tương thích độc lập nhưng bổ trợ lẫn nhau**, vận hành hoàn toàn trong không gian người dùng và kernel hook mà không can thiệp vào các phân vùng lưu trữ vật lý:

```
┌──────────────────────────────────────────────────────────────────┐
│                   USER-SPACE APPLICATIONS                        │
│   (Identity, Banking, Enterprise, MDM, Standard Android Apps)    │
└──────────────────┬─────────────────────────────┬─────────────────┘
                   │                             │
    Reads via SystemProperties        Reads via open("/system/build.prop")
                   │                             │
┌──────────────────▼───────────────┐ ┌───────────▼─────────────────┐
│ Lớp 1: Property Normalization    │ │ Lớp 2: Compatibility View   │
│ - volatile memory (RAM)          │ │ - SuSFS open_redirect       │
│ - resetprop property engine      │ │ - UID Scheme 3 (uid ≥ 10000)│
│ - matches official stock release │ │ - delivers compat_build.prop│
└──────────────────────────────────┘ └─────────────────────────────┘
                   │
    File Enumeration in /product/priv-app
                   │
┌──────────────────▼───────────────────────────────────────────────┐
│ Lớp 3: ROM Component Isolation                                   │
│ - SuSFS sus_path filter                                          │
│ - dynamic isolation of auxiliary ROM packages (XiaomiEUExt...)   │
│ - returns ENOENT to userland scanners while core OS functions    │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Khác Biệt Môi Trường Trên Custom ROM (HyperOS & AOSP Differences)

Trong các bản ROM tùy biến, các nhà phát triển thường điều chỉnh nhiều thuộc tính hệ thống vì lý do kỹ thuật. Dưới đây là phân tích chi tiết theo hai nhánh môi trường chính:

### Nhánh 1: Custom HyperOS (Xiaomi.eu, HyperTN, EliteROM, MiPA, Pulse...)
| Thuộc tính | Giá trị trên Stock Firmware | Giá trị trên Custom HyperOS | Nguyên nhân kỹ thuật phát sinh khác biệt |
|---|---|---|---|
| `ro.build.type` | `user` | Thường bị đổi thành `userdebug` | Giúp dev bật adb root, xem log chi tiết khi port ROM. |
| `ro.debuggable` | `0` | Thường bị đổi thành `1` | Cho phép gỡ lỗi tiến trình qua JDWP/ADB. |
| `ro.build.host` | Server chính thức Xiaomi (`c5-build-*.bj.xiaomi.com`) | Server của team port (`build-*.xiaomi.eu`, `hypertn-builder`...) | Máy chủ thực tế biên dịch bản build ROM tùy biến. |
| `ro.product.mod_device` | `mondrian_global`, `ishtar_eea_global` | `mondrian_xiaomieu_global`, `mondrian_hypertn` | Dùng để phân định biến thể ROM và định tuyến cập nhật OTA riêng. |
| `ro.xiaomi.developerid` | Không tồn tại | Định danh của dev biên dịch | Chữ ký định danh cá nhân của lập trình viên ROM. |
| `ro.xiaomi.eu.*` | Không tồn tại | Các cờ tính năng bổ trợ của Xiaomi.eu | Kích hoạt bản dịch đa ngôn ngữ và các bản vá nội bộ. |

### Nhánh 2: Custom AOSP (LineageOS, crDroid, PixelExperience, EvolutionX...)
| Thuộc tính | Giá trị trên AOSP Stock | Giá trị trên Custom AOSP | Nguyên nhân kỹ thuật phát sinh khác biệt |
|---|---|---|---|
| `ro.build.type` | `user` | Thường mặc định `userdebug` | Cho phép developer truy cập root qua ADB debugging. |
| `ro.debuggable` | `0` | Thường mặc định `1` | Cho phép debuggable ART runtime và attach profiler. |
| `ro.lineage.*` | Không tồn tại | `ro.lineage.version`, `ro.lineage.device`... | Nhận diện phiên bản LineageOS và hỗ trợ Lineage Settings. |
| `ro.crdroid.*` | Không tồn tại | `ro.crdroid.version`, `ro.crdroid.build.version` | Khai báo bản phát hành của cộng đồng crDroid. |
| `ro.modversion` | Không tồn tại | Tên và số phiên bản của bản ROM tùy biến | Thuộc tính legacy được nhiều ứng dụng bảo mật dùng làm cờ phát hiện ROM. |

---

## 3. Nhận Diện Môi Trường Thông Minh & Chuẩn Hóa Thuộc Tính (Smart Environment Detection & Normalization)

Để đảm bảo an toàn tuyệt đối và tính tự nhiên của môi trường, module áp dụng cơ chế **Smart Environment Detection** trong cả `customize.sh` và `service.sh`:

```sh
# Tự động nhận diện nhánh ROM
if [ -n "$(getprop ro.miui.ui.version.name)" ] || [ -f "/system/framework/framework-ext-res.apk" ]; then
    ROM_ENV="hyperos"
else
    ROM_ENV="aosp"
fi
```

### Hồ Sơ 1: HyperOS Profile
Khi hoạt động trên môi trường Xiaomi HyperOS / MIUI:
1. **Chuẩn hóa hạ tầng Xiaomi:** Khôi phục `ro.build.host` về máy chủ chính thức của Xiaomi (`c5-build-66.bj.xiaomi.com`).
2. **Chuẩn hóa mã máy Xiaomi:** Khôi phục `ro.product.mod_device` về mã thương mại gốc (ví dụ: `mondrian_global`), giữ nguyên hậu tố phân vùng mạng (`_global`, `_eea_global`, `_in_global`) để bảo vệ kết nối radio/modem.
3. **Làm sạch thuộc tính mod:** Tự động loại bỏ các thuộc tính chứa chữ ký: `ro.xiaomi.eu.*`, `ro.hypertn.*`, `ro.eliterom.*`, `ro.mipa.*`, `ro.pulse.*`, `developerid`.

### Hồ Sơ 2: AOSP Profile
Khi hoạt động trên môi trường AOSP thuần, LineageOS hoặc crDroid:
1. **Bảo toàn thiết bị gốc:** Tuyệt đối **KHÔNG** cấy `ro.product.mod_device` hay thay đổi `ro.build.host` thành server Xiaomi, tránh tạo ra dị thường cấu hình (anomalous build machine).
2. **Làm sạch thuộc tính rò rỉ:** Tự động xóa các thuộc tính đặc thù qua `resetprop -d`:
   - `ro.lineage.version`, `ro.lineage.build.version`, `ro.lineage.device`, `ro.lineage.display.version`
   - `ro.crdroid.version`, `ro.crdroid.build.version`, `ro.crdroid.device`
   - `ro.evolution.*`, `ro.pixelexperience.*`, `ro.havoc.*`, `ro.derp.*`
   - `ro.modversion`
3. **Đồng bộ cờ sản xuất (Chung cho mọi môi trường):**
   - Đưa `ro.build.type` về `user`.
   - Đưa `ro.debuggable` về `0`.

---

## 4. Góc Nhìn Tệp Cấu Hình Tương Thích (Compatibility Build.prop View)

Nhiều thư viện native (C/C++) không gọi API Java `SystemProperties.get()` mà mở trực tiếp tệp `/system/build.prop` bằng lời gọi hệ thống `open()`.

Để xử lý trường hợp này:
1. Trong quá trình cài đặt (`customize.sh`), module tự động tạo ra tệp `compat_build.prop` thích ứng riêng theo môi trường đã nhận diện:
   - **Trên HyperOS:** Lọc bỏ cờ ROM Xiaomi.eu/HyperTN, chuẩn hóa host và mod_device;
   - **Trên AOSP:** Lọc bỏ các dòng `ro.lineage.*`, `ro.crdroid.*`, `ro.modversion`, chuẩn hóa `ro.build.type=user`, `ro.debuggable=0` mà không thêm các trường lạ của Xiaomi.
2. Quá trình lọc sử dụng lệnh `sed` tương thích chuẩn POSIX/Toybox:
   - Ghi kết quả vào `$MODPATH/compat_build.prop`.
3. Tệp này được cấp quyền đọc `0644` và gán nhãn SELinux `u:object_r:system_file:s0`.

---

## 5. Tích Hợp SuSFS Cấp Kernel (SuSFS Integration)

SuSFS (Suspicious Filesystem Hook) cung cấp khả năng can thiệp cấp kernel mà không làm thay đổi nội dung trên đĩa cứng:

### Kỹ thuật `open_redirect`
Lệnh `ksu_susfs add_open_redirect /system/build.prop <target> 3`:
- Chặn syscall `sys_openat` trong kernel khi tiến trình cố gắng mở `/system/build.prop`.
- **UID Scheme 3:** Kernel kiểm tra UID của tiến trình gọi. Nếu `UID >= 10000` (ứng dụng không gian người dùng), kernel sẽ trả về tệp `compat_build.prop`.
- Các daemon hệ thống (`init`, `vold`, `rild`) có `UID < 10000` tiếp tục đọc tệp gốc mà không bị ảnh hưởng.

---

## 6. Cách Ly Thành Phần Phụ Trợ Của ROM (ROM Component Isolation)

Các bản ROM tùy biến thường đính kèm các gói APK phụ trợ trong `/product/priv-app/`, `/system_ext/priv-app/` hoặc `/system/priv-app/`:
1. **Quét động theo hồ sơ môi trường:**
   - **Hồ sơ HyperOS:** Tự động quét và phát hiện các thành phần đặc thù của ROM Xiaomi mod: `XiaomiEUExt`, `XiaomiEUInject`, `HyperTN`, `TNToolbox`, `EliteROM`, `MiPA`...
   - **Hồ sơ AOSP / LineageOS:** Tự động phát hiện các ứng dụng cập nhật OTA (`lineage.updater`, `crdroid.updater`), cùng toàn bộ cơ chế lưu vết nâng cấp `/system/addon.d` (`/system/system/addon.d`, `/system_ext/addon.d`, `/product/addon.d`). Module chủ động **loại trừ các thành phần thiết yếu của hệ điều hành** (như `LineageParts.apk`) để bảo đảm toàn vẹn giao diện Cài đặt và tính năng phần cứng của LineageOS.
2. **Lưu trữ danh sách & Đồng bộ SuSFS:** Ghi nhận các đường dẫn tìm thấy vào `compat_isolated_components.txt` và tự động ghi đè danh sách vĩnh viễn vào `/data/adb/susfs4ksu/sus_path.txt`.
3. **Cách ly qua SuSFS:** `service.sh` nạp các đường dẫn này vào `ksu_susfs add_sus_path <path>` trên mỗi lần khởi động lại máy.
4. **Kết quả kỹ thuật:** Lệnh `readdir()` hoặc `stat()` từ không gian ứng dụng người dùng nhận mã lỗi `ENOENT` (File not found), trong khi hệ thống Android vẫn thực thi tiến trình bình thường.

---

## 7. Vòng Đời Khởi Động & An Toàn Modem (Boot Lifecycle & Modem Safety)

```
Giai đoạn boot       Hoạt động Module               Lý do an toàn
─────────────────────────────────────────────────────────────────────────────
early-init           Không can thiệp                Tránh race condition phần cứng
post-fs-data         Không can thiệp                Bảo vệ rild (Modem SSR)
boot_completed = 1   service.sh kích hoạt           Bảo đảm toàn bộ hệ thống đã ổn định
```

> [!IMPORTANT]
> **Bài học về an toàn Modem (RIL Safety):**  
> Việc can thiệp vào `build.prop` hoặc thực thi redirection trước khi modem partition sẵn sàng sẽ khiến tiến trình `rild` đọc sai cấu hình radio, gây ra hiện tượng **Modem Subsystem Restart (SSR)** dẫn đến bootloop. Bằng cách trì hoãn thực thi đến khi `sys.boot_completed=1` và áp dụng UID Scheme 3, module loại trừ hoàn toàn nguy cơ này.

---

## 8. Tự Động Nhận Diện Nền Tảng Root (Root Backend Detection)

Module tự động phát hiện môi trường thực thi và lựa chọn nhị phân tương ứng:

```bash
# resetprop detection
if [ -f "/data/adb/ksu/bin/resetprop" ]; then
    RESETPROP="/data/adb/ksu/bin/resetprop"
elif [ -f "/data/adb/ap/bin/resetprop" ]; then
    RESETPROP="/data/adb/ap/bin/resetprop"
elif [ -f "/data/adb/magisk/magisk" ]; then
    RESETPROP="/data/adb/magisk/magisk --resetprop"
else
    RESETPROP="resetprop"
fi

# SuSFS binary detection
if [ -f "/data/adb/ksu/bin/ksu_susfs" ]; then
    SUSFS_BIN="/data/adb/ksu/bin/ksu_susfs"
elif [ -f "/data/adb/ksu/bin/susfs" ]; then
    SUSFS_BIN="/data/adb/ksu/bin/susfs"
elif [ -f "/data/adb/ap/bin/ap_susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/ap_susfs"
elif [ -f "/data/adb/ap/bin/susfs" ]; then
    SUSFS_BIN="/data/adb/ap/bin/susfs"
elif command -v ksu_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ksu_susfs"
elif command -v ap_susfs >/dev/null 2>&1; then
    SUSFS_BIN="ap_susfs"
elif command -v susfs >/dev/null 2>&1; then
    SUSFS_BIN="susfs"
fi
```

---

## 9. Mô Hình An Toàn Hệ Thống (Safety Model)

1. **Tính Bất Biến Của Phân Vùng:** Không ghi đè hay chỉnh sửa bất kỳ tệp tin nào trên `/system`, `/vendor`, `/product`.
2. **Chế Độ Mount Không Phụ Thuộc:** Khai báo cấu hình script thuần túy, không yêu cầu overlay filesystem ảo (Magic Mount).
3. **Phân Quyền Chặt Chẽ:** Tệp cấu hình tạm tạo ra trong `/mnt/vendor/susfs4ksu/` hoặc `/data/adb/susfs4ksu/` được giới hạn quyền `0644`.
4. **Không Thu Thập Dữ Liệu:** Không lưu trữ nhật ký hoạt động của người dùng, không tạo kết nối mạng ra ngoài.

---

## 10. Cơ Chế Phục Hồi & Gỡ Bỏ (Rollback / Uninstall)

Khi người dùng thực hiện gỡ cài đặt module qua trình quản lý root:
- `uninstall.sh` được kích hoạt tự động;
- Xóa bỏ các quy tắc chuyển hướng trong `/data/adb/susfs4ksu/sus_open_redirect.txt`;
- Xóa bỏ các đường dẫn cách ly trong `/data/adb/susfs4ksu/sus_path.txt`;
- Xóa tệp tạm `compat_build.prop` và `clean_build.prop` khỏi `/mnt/vendor/` và `/data/adb/`;
- Sau khi khởi động lại, kernel và framework trở về trạng thái nguyên bản 100%.

---

## 11. Chẩn Đoán & Gỡ Lỗi An Toàn (Debugging & Diagnostics)

Để kiểm tra trạng thái hoạt động mà không làm rò rỉ dữ liệu cá nhân:

```bash
# 1. Kiểm tra trạng thái thuộc tính đã chuẩn hóa
su -c "getprop ro.build.type"      # Mong đợi: user
su -c "getprop ro.debuggable"      # Mong đợi: 0
su -c "getprop ro.build.host"      # Mong đợi: c5-build-66.bj.xiaomi.com

# 2. Kiểm tra SuSFS open_redirect
su -c "ksu_susfs show open_redirect"

# 3. Kiểm tra SuSFS sus_path
su -c "ksu_susfs show sus_path"
```

---

## 12. Ma Trận Tương Thích (Compatibility Matrix)

| Biến thể ROM / Hệ Điều Hành | Phiên bản Android | Hồ Sơ Chuẩn Hóa | Trạng Thái SuSFS Kernel | Đánh Giá Vận Hành |
|---|---|---|---|---|
| **Xiaomi.eu HyperOS 1.0** | Android 14 | HyperOS Profile | Tương thích (nếu kernel có SuSFS) | Ổn định |
| **Xiaomi.eu HyperOS 2.0** | Android 15 | HyperOS Profile | Tương thích (nếu kernel có SuSFS) | Ổn định |
| **Xiaomi.eu HyperOS 3.0** | Android 15 / 16 | HyperOS Profile | Tương thích (Wild Kernel / ShirkNeko) | Đã thử nghiệm thực tế (POCO F5 Pro) |
| **HyperTN / TN ToolBox** | Android 14 / 15 | HyperOS Profile | Tương thích | Ổn định |
| **EliteROM / MiPA / Pulse** | Android 14 / 15 | HyperOS Profile | Tương thích | Ổn định |
| **HyperOS Flagship Ports** | Android 14 / 15 | HyperOS Profile | Tương thích | Ổn định |
| **LineageOS (Official / Unofficial)** | Android 13 – 16 | AOSP Profile | Tương thích (Bảo vệ LineageParts) | Ổn định |
| **crDroid Android** | Android 13 – 16 | AOSP Profile | Tương thích | Ổn định |
| **PixelExperience / PixelOS** | Android 13 – 15 | AOSP Profile | Tương thích | Ổn định |
| **EvolutionX** | Android 13 – 15 | AOSP Profile | Tương thích | Ổn định |
| **Generic AOSP / GSI (Treble)** | Android 12 – 16 | AOSP Profile | Tương thích | Ổn định |
