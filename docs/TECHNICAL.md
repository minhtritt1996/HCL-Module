# Tài Liệu Kỹ Thuật (Technical Documentation)

**HyperOS & AOSP Compatibility Layer (HCL)** — Framework kỹ thuật chuẩn hóa môi trường runtime, điều phối chứng thực bảo mật và bảo vệ tính toàn vẹn hệ thống cho Xiaomi HyperOS cùng các bản ROM tùy biến AOSP.

---

## 📖 Mục Lục Chuyên Mục

1. [Kiến Trúc Kỹ Thuật Đa Tầng (Multi-Layer Architecture)](#1-kiến-trúc-kỹ-thuật-đa-tầng-multi-layer-architecture)
2. [Phân Tích Dị Thường Trên Custom ROM (ROM Discrepancy Analysis)](#2-phân-tích-dị-thường-trên-custom-rom-rom-discrepancy-analysis)
3. [Chuẩn Hóa Thuộc Tính Đa Phân Vùng Toàn Diện (Multi-Partition Normalization)](#3-chuẩn-hóa-thuộc-tính-đa-phân-vùng-toàn-diện-multi-partition-normalization)
4. [Góc Nhìn Tệp Cấu Hình Tương Thích (Compatibility Build.prop View)](#4-góc-nhìn-tệp-cấu-hình-tương-thích-compatibility-buildprop-view)
5. [Cách Ly Thành Phần Phụ Trợ Của ROM (ROM Component Isolation)](#5-cách-ly-thành-phần-phụ-trợ-của-rom-rom-component-isolation)
6. [Ma Trận Điều Phối Chứng Thực & Bảo Vệ Keystore Gốc (Attestation & Keystore Matrix)](#6-ma-trận-điều-phối-chứng-thực--bảo-vệ-keystore-gốc-attestation--keystore-matrix)
7. [Tiến Trình Giám Sát Nền & Tự Động Đồng Bộ (Guardian Daemon Engine)](#7-tiến-trình-giám-sát-nền--tự-động-đồng-bộ-guardian-daemon-engine)
8. [Trung Tâm Điều Khiển WebUI & Cơ Chế Hot-Reload (WebUI Dashboard & Hot-Reload)](#8-trung-tâm-điều-khiển-webui--cơ-chế-hot-reload-webui-dashboard--hot-reload)
9. [Vòng Đời Khởi Động & Miễn Nhiễm Bootloop (Boot Lifecycle & Bootloop Immunity)](#9-vòng-đời-khởi-động--miễn-nhiễm-bootloop-boot-lifecycle--bootloop-immunity)
10. [Tích Hợp Tiện Ích Bổ Trợ (HMA Sync, Cache Cleaner, Action CLI)](#10-tích-hợp-tiện-ích-bổ-trợ-hma-sync-cache-cleaner-action-cli)
11. [Cơ Chế Phục Hồi & Gỡ Bỏ (Uninstall & Rollback)](#11-cơ-chế-phục-hồi--gỡ-bỏ-uninstall--rollback)
12. [Ma Trận Tương Thích & Kiểm Thử Thực Tế (Compatibility Matrix)](#12-ma-trận-tương-thích--kiểm-thử-thực-tế-compatibility-matrix)

---

## 1. Kiến Trúc Kỹ Thuật Đa Tầng (Multi-Layer Architecture)

Dự án vận hành trên mô hình **đa tầng thích ứng**, kết hợp giữa bộ nhớ biến tính (RAM volatile properties), can thiệp cấp nhân (Kernel SuSFS), ma trận phân định khóa bảo mật (Keystore Matrix) và tiến trình giám sát trạng thái thời gian thực:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        USER-SPACE APPLICATIONS                         │
│            (Identity Apps, Banking, Fintech, Enterprise)               │
└──────────────────┬─────────────────────────────┬───────────────────────┘
                   │                             │
    Đọc qua SystemProperties          Đọc qua sys_open("/system/build.prop")
                   │                             │
┌──────────────────▼───────────────────┐ ┌───────▼────────────────────────┐
│ Lớp 1: Chuẩn Hóa Thuộc Tính Bộ Nhớ   │ │ Lớp 2: Góc Nhìn Tương Thích     │
│ • RAM volatile memory (resetprop)    │ │ • SuSFS open_redirect          │
│ • Đồng bộ Fingerprint mọi phân vùng  │ │ • UID Scheme 3 (uid ≥ 10000)   │
│ • Khử bỏ mainline, miproduct, qssi   │ │ • hyperos_compat_build.prop     │
│ • Chuẩn hóa Boot Security & Uname   │ │ • Daemon init/rild giữ nguyên   │
└──────────────────────────────────────┘ └────────────────────────────────┘
                   │
    Truy vấn đường dẫn tệp trong /product, /system_ext, /system
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 3: Cách Ly Thành Phần Phụ Trợ (SuSFS sus_path)                     │
│ • XiaomiEUExt, XiaomiEUInject, MiuiExtraPhoto, addon.d...              │
│ • Trả về ENOENT cho scanner mà không ảnh hưởng chức năng HĐH           │
└────────────────────────────────────────────────────────────────────────┘
                   │
    Yêu cầu chứng thực KeyStore / TEE Hardware Attestation
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 4: Ma Trận Điều Phối Chứng Thực (attest_sync.sh)                   │
│ • Giả lập chứng thực phần cứng mục tiêu (target.txt)                   │
│ • Khóa bảo vệ Keystore gốc (app_keybox.map với nhãn off)              │
│ • Tự động nhận diện Fintech/Banking và chuẩn hóa spoof.conf            │
└────────────────────────────────────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────┐ ┌────────────────────────────────┐
│ Lớp 5: Daemon Giám Sát Nền           │ │ Lớp 6: Bảng Điều Khiển WebUI   │
│ • guardian.sh theo dõi packages.xml  │ │ • Giao diện quản lý trực quan  │
│ • Tự động đồng bộ khi cài/gỡ app     │ │ • Áp dụng quy tắc Hot-Reload   │
└──────────────────────────────────────┘ └────────────────────────────────┘
                   │
┌──────────────────▼─────────────────────────────────────────────────────┐
│ Lớp 7: Khởi Động An Toàn Tuyệt Đối (post-fs-data.sh Stub)             │
│ • Stub siêu nhẹ non-blocking, miễn nhiễm hoàn toàn với bootloop        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Phân Tích Dị Thường Trên Custom ROM (ROM Discrepancy Analysis)

Các bản ROM tùy biến thường để lại các dấu vết kỹ thuật khiến các thư viện bảo vệ tính toàn vẹn cấp native phát hiện:

### 2.1. Lệch Fingerprint giữa các phân vùng
- **Hiện tượng:** Phân vùng `ro.build.fingerprint` được đặt theo chuẩn thương mại (`Redmi/mondrian/mondrian:15/...`), nhưng phân vùng `ro.product.build.fingerprint` vẫn giữ giá trị nội bộ (`Xiaomi/mondrian/miproduct:15/...`).
- **Hậu quả:** Ứng dụng đối chiếu chéo các phân vùng, phát hiện sự không đồng nhất giữa thương hiệu (`Redmi` vs `Xiaomi`) và tên thiết bị (`mondrian` vs `miproduct`), kích hoạt mã lỗi ROM tùy biến (ví dụ: `CA-E012`).

### 2.2. Dị thường Model & Tên phân vùng
- Phân vùng `ro.product.system.model` thường bị gán nhãn `mainline` (do dùng module AOSP generic system).
- Phân vùng `ro.product.product.model` và `ro.product.product.device` bị đặt là `miproduct`.
- Phân vùng `ro.product.vendor_dlkm.model` lưu mã model nội địa Trung Quốc (`23013RK75C`) trong khi thiết bị thương mại quốc tế là `23013PC75G`.

### 2.3. Rò rỉ chữ ký bản mod & thành phần bổ trợ
- Thuộc tính `ro.product.mod_device` mang hậu tố bản mod (`mondrian_xiaomieu_global`).
- Chữ ký build host (`ro.build.host=xiaomi.eu`), `ro.xiaomi.eu.*`, `ro.lineage.*`, `ro.modversion`.
- Tệp tin phụ trợ đặc thù: `/product/priv-app/XiaomiEUExt`, `/product/priv-app/MiuiExtraPhoto`, `/system_ext/app/XiaomiEUInject`, `/system/addon.d`.

---

## 3. Chuẩn Hóa Thuộc Tính Đa Phân Vùng Toàn Diện (Multi-Partition Normalization)

Kể từ phiên bản **v1.4.3**, quy trình chuẩn hóa thuộc tính trong [`service.sh`](../module/service.sh) được tái thiết kế triệt để nhằm bảo đảm đồng nhất 100%:

### 3.1. Đồng bộ hóa tuyệt đối Fingerprint trên tất cả phân vùng
Thay vì chỉ lọc các chuỗi `generic` hay `test-keys`, script kiểm tra trực tiếp tính tương đồng của từng phân vùng so với `TARGET_FP`:
```sh
if [ -n "$TARGET_FP" ]; then
    for part in system system_ext product vendor odm bootimage vendor_dlkm odm_dlkm; do
        CUR_PART_FP=$(getprop "ro.${part}.build.fingerprint")
        if [ -z "$CUR_PART_FP" ] || [ "$CUR_PART_FP" != "$TARGET_FP" ]; then
            $RESETPROP -n -v "ro.${part}.build.fingerprint" "$TARGET_FP" 2>/dev/null || true
        fi
    done
fi
```

### 3.2. Chuẩn hóa Model, Device, Name, Brand & Manufacturer
Mọi phân vùng (`product`, `vendor_dlkm`, `odm_dlkm`, `system_ext`, `odm`, `system`, `bootimage`, `vendor`) cùng các thuộc tính cấp cao (`ro.product.*`) được chuẩn hóa đồng bộ về thông số thương mại:
- **Model:** Chuẩn hóa về mã thiết bị thực tế (ví dụ: `23013PC75G`), khử bỏ hoàn toàn `mainline`, `miproduct`, `qssi`.
- **Device & Name:** Chuẩn hóa về tên mã thiết bị (`mondrian`), khử bỏ `miproduct`, `generic`, `missi`.
- **Brand:** Chuẩn hóa đồng bộ về thương hiệu máy (`POCO` hoặc `Redmi`).
- **Manufacturer:** Chuẩn hóa về `Xiaomi`.

### 3.3. Bảo toàn trạng thái Bootloader & Verified Boot
Loại bỏ trạng thái rò rỉ của bootloader mở khóa trong bộ nhớ RAM:
```sh
P_FLASH="ro.boot.flash"
P_VBMETA="ro.boot.vbmeta"
$RESETPROP -n -v "${P_FLASH}.locked" 1
$RESETPROP -n -v ro.boot.verifiedbootstate green
$RESETPROP -n -v ro.boot.secureboot 1
$RESETPROP -n -v "${P_VBMETA}.device_state" locked
$RESETPROP -n -v ro.secure 1
$RESETPROP -n -v sys.oem_unlock_allowed 0
$RESETPROP -n -v ro.boot.warranty_bit 0
```

### 3.4. Giả lập Kernel Uname thông minh
Tự động cắt bỏ các hậu tố nhân mod (`-wild`, `-dirty`, `-custom`, `-lineage`...) và đồng bộ ngày biên dịch nhân theo thời gian UTC của bản ROM (`ro.build.date.utc`):
```sh
"$SUSFS_BIN" set_uname "$BASE_KERNEL" "#1 SMP PREEMPT $KERNEL_DATE" 2>/dev/null || true
```

---

## 4. Góc Nhìn Tệp Cấu Hình Tương Thích (Compatibility Build.prop View)

Nhiều thư viện kiểm tra bảo mật native (C/C++) truy xuất trực tiếp `/system/build.prop` thông qua lời gọi hệ thống `open()`.

- **Cơ chế:** Khi cài đặt, module sinh tệp `$MODPATH/compat_build.prop` đã được làm sạch mọi cờ mod ROM.
- **SuSFS Open Redirect:** `service.sh` thiết lập quy tắc chuyển hướng cấp kernel:
  ```sh
  "$SUSFS_BIN" add_open_redirect /system/build.prop "$TARGET_COMPAT_PROP" 3
  ```
- **Phân định UID Scheme 3:** Kernel chỉ chuyển hướng cho các tiến trình ứng dụng người dùng (`UID >= 10000` và có trạng thái `umounted`). Các tiến trình cốt lõi của Android (`init`, `vold`, `rild`) tiếp tục đọc tệp nguyên bản, bảo đảm an toàn kết nối mạng vô tuyến và sóng di động.

---

## 5. Cách Ly Thành Phần Phụ Trợ Của ROM (ROM Component Isolation)

- **Quét động theo môi trường:** Tự động định vị các gói ứng dụng phụ trợ:
  - *HyperOS:* `XiaomiEUExt`, `XiaomiEUInject`, `MiuiExtraPhoto`, `HyperTN`, `TNToolbox`, `EliteROM`...
  - *AOSP:* Các ứng dụng OTA updater, cấu trúc `/system/addon.d` (bảo toàn nguyên vẹn `LineageParts` để không ảnh hưởng cài đặt hệ thống).
- **Cách ly SuSFS sus_path:** Đăng ký toàn bộ danh sách phát hiện vào kernel qua `add_sus_path`. Khi ứng dụng người dùng duyệt thư mục hoặc kiểm tra tệp, kernel trả về mã lỗi `ENOENT` (File not found).

---

## 6. Ma Trận Điều Phối Chứng Thực & Bảo Vệ Keystore Gốc (Attestation & Keystore Matrix)

Dự án giải quyết triệt để sự xung đột giữa công cụ giả lập chứng thực phần cứng (Tricky Store / AlwaysStrong) và các ứng dụng ngân hàng:

### 6.1. Tệp `target.txt` — Danh sách ứng dụng giả lập phần cứng
- Gồm các ứng dụng cần chuyển tiếp chứng thư bảo mật để vượt qua kiểm tra Play Integrity (MEETS_DEVICE_INTEGRITY / MEETS_STRONG_INTEGRITY) hoặc ứng dụng định danh yêu cầu bootloader locked (VNeID).

### 6.2. Tệp `app_keybox.map` gắn cờ `off` — Tấm khiên bảo vệ Keystore gốc
- **Vấn đề thực tế:** AlwaysStrong sở hữu tiến trình nền `aswatcher` tự động quét toàn bộ ứng dụng người dùng cài đặt (`pm list packages -3`) và tự động thêm lại vào `target.txt`.
- **Giải pháp:** Khi một ứng dụng được đưa vào `app_keybox.map` với cờ `off` (`tên_gói\toff`), AlwaysStrong sẽ **bị cưỡng chế bỏ qua và không bao giờ tự động thêm ứng dụng đó vào `target.txt`**.
- Nhờ cơ chế này, các ứng dụng ngân hàng nhạy cảm (như Sacombank Pay) được bảo vệ vĩnh viễn trên Keystore phần cứng thực tế của thiết bị, không bị lỗi giả lập can thiệp.

### 6.3. Làm sạch cấu hình `spoof.conf`
Đồng bộ các tham số giả lập an toàn nhất:
```ini
spoofProvider=0
spoofSignature=0
```

---

## 7. Tiến Trình Giám Sát Nền & Tự Động Đồng Bộ (Guardian Daemon Engine)

Script [`guardian.sh`](../module/guardian.sh) chạy ngầm với mức tiêu thụ tài nguyên cực thấp:
- **Cơ chế theo dõi:** Giám sát dấu thời gian (modification timestamp) của `/data/system/packages.xml`.
- **Tự động phản ứng:** Khi người dùng cài đặt ứng dụng mới hoặc gỡ bỏ ứng dụng, Guardian tự động kích hoạt [`attest_sync.sh`](../module/attest_sync.sh) để tái đồng bộ ma trận chứng thực.
- **Cấu hình động:** Chu kỳ quét có thể tùy chỉnh trong `config.json` (`interval_seconds`, mặc định 120s).
- **Kill-switch tức thì:** Khi tồn tại tệp `/data/adb/hyperos_compat/disable_guardian`, tiến trình tự động giải phóng và kết thúc an toàn.

---

## 8. Trung Tâm Điều Khiển WebUI & Cơ Chế Hot-Reload (WebUI Dashboard & Hot-Reload)

Module tích hợp giao diện WebUI chuẩn hiện đại ([`webroot/index.html`](../module/webroot/index.html)):
- **Hot-Reload tức thì không cần Reboot:** Khi người dùng thay đổi danh sách và nhấn **"Lưu & Áp dụng thay đổi"**, WebUI ghi nhận các gói bị tác động, thực thi đồng bộ tệp và kích hoạt `am force-stop` các ứng dụng liên quan. Ứng dụng khi mở lại sẽ lập tức nhận quy tắc mới mà không cần khởi động lại điện thoại.
- **Trình chọn gói từ máy:** Hỗ trợ quét danh sách ứng dụng đã cài đặt trên thiết bị, tìm kiếm theo tên hoặc tên gói, hỗ trợ chọn hàng loạt và xóa hàng loạt.
- **Phân tách 2 danh sách rõ ràng:** Quản trị độc lập giữa danh sách cần giả lập phần cứng và danh sách cần bảo vệ Keystore gốc.

---

## 9. Vòng Đời Khởi Động & Miễn Nhiễm Bootloop (Boot Lifecycle & Bootloop Immunity)

```
Giai đoạn boot       Hoạt động Module               Lý do an toàn tuyệt đối
─────────────────────────────────────────────────────────────────────────────
early-init           Không can thiệp                Tránh race condition phần cứng
post-fs-data         mkdir -p (Non-blocking stub)   TUYỆT ĐỐI KHÔNG GỌI FRAMEWORK (pm)
boot_completed = 1   service.sh kích hoạt           Bảo đảm toàn bộ hệ thống đã sẵn sàng
```

> [!IMPORTANT]
> **Bài học cốt tử về Bootloop:**  
> Ở giai đoạn `post-fs-data`, Android `system_server` và `PackageManagerService` chưa khởi chạy. Bất kỳ lệnh shell nào gọi `pm list packages` trong `post-fs-data.sh` sẽ bị chặn (block) vĩnh viễn để chờ binder service, dẫn tới treo hoàn toàn chu trình khởi động (bootloop).  
> Kể từ phiên bản v1.4.3, `post-fs-data.sh` được rút gọn thành stub siêu nhẹ (`mkdir -p`), chuyển toàn bộ logic xử lý sang `service.sh` sau khi `sys.boot_completed=1`, bảo đảm **100% không bao giờ gây treo máy khi khởi động**.

---

## 10. Tích Hợp Tiện Ích Bổ Trợ (HMA Sync, Cache Cleaner, Action CLI)

1. **Hide My Applist (HMA) Synchronization:**  
   Tự động phát hiện và gửi tín hiệu làm mới cấu hình qua ContentProvider của HMA (`content://org.frknkrc44.hma_oss.ServiceProvider`).
2. **Trình Dọn Dẹp Bộ Nhớ Đệm (Cache Cleaner):**  
   Script [`scripts/cache_cleaner.sh`](../module/scripts/cache_cleaner.sh) hỗ trợ giải phóng bộ nhớ đệm ứng dụng an toàn.
3. **Menu Điều Khiển Terminal (Action CLI):**  
   Script [`action.sh`](../module/action.sh) hỗ trợ thực thi nhanh qua phím Action của Root Manager hoặc lệnh dòng lệnh:
   - Đồng bộ chứng thực tức thì (`--sync`).
   - Bật/tắt nhanh tiến trình Guardian (`--toggle-guardian`).
   - Dọn dẹp cache hệ thống.

---

## 11. Cơ Chế Phục Hồi & Gỡ Bỏ (Uninstall & Rollback)

Khi gỡ cài đặt module qua trình quản lý root, [`uninstall.sh`](../module/uninstall.sh) tự động thực hiện:
- Xóa các quy tắc chuyển hướng trong `/data/adb/susfs4ksu/sus_open_redirect.txt`.
- Xóa các đường dẫn cách ly khỏi `/data/adb/susfs4ksu/sus_path.txt`.
- Dọn dẹp tệp cấu hình tạm `hyperos_compat_build.prop` trong thư mục SuSFS.
- Dọn dẹp thư mục cấu hình `/data/adb/hyperos_compat`.
- Giải phóng tiến trình `guardian.sh` đang chạy.

---

## 12. Ma Trận Tương Thích & Kiểm Thử Thực Tế (Compatibility Matrix)

| Thiết bị & Nền Tảng | Codename | Hệ Điều Hành | Môi Trường Root | Trạng Thái Kiểm Thử |
|---|---|---|---|---|
| **POCO F5 Pro** | `mondrian` | Xiaomi.eu HyperOS 3.0 (Android 15) | KernelSU + Wild Kernel (SuSFS) | **Hoạt động hoàn hảo (VNeID + Sacombank Pay OK)** |
| **Xiaomi Flagships** | Đa dạng | HyperOS 1.0 / 2.0 / 3.0 | KernelSU / APatch / Magisk | Tương thích hoàn toàn |
| **Thiết bị AOSP** | Đa dạng | LineageOS 21 / 22 (Android 14/15) | KernelSU / APatch / Magisk | Tương thích (Bảo vệ LineageParts) |
| **crDroid / EvolutionX** | Đa dạng | Android 13 – 16 | KernelSU / APatch / Magisk | Tương thích hoàn toàn |
