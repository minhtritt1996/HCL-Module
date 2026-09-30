# Hướng Dẫn Đóng Góp (Contributing Guidelines)

Cảm ơn bạn đã quan tâm và muốn đóng góp cho dự án **HyperOS Compatibility Layer**! Chúng tôi hoan nghênh mọi đóng góp từ cộng đồng nhằm mở rộng khả năng tương thích của các bản ROM tùy biến dựa trên Xiaomi HyperOS.

---

## 🎯 Trọng Tâm Đóng Góp (Contribution Focus Areas)

Chúng tôi đặc biệt khuyến khích các đóng góp tập trung vào các lĩnh vực sau:

1. **Hỗ trợ phiên bản HyperOS mới:** Kiểm thử và chuẩn hóa trên HyperOS 1.0, HyperOS 2.0, HyperOS 3.0 (Android 14, 15, 16...).
2. **Mở rộng hỗ trợ các bản ROM HyperOS:**
   - Xiaomi.eu
   - HyperTN / TN ToolBox
   - EliteROM
   - MiPA
   - Pulse
   - HyperOS Ports (Port từ các thiết bị flagship sang thiết bị khác)
3. **Độ tương thích thiết bị phần cứng mới:** Bổ sung báo cáo thử nghiệm trên các dòng máy Xiaomi, Redmi, POCO.
4. **Tương thích Kernel & SuSFS:** Kiểm thử trên các kernel tùy biến hỗ trợ SuSFS (Wild Kernel, ShirkNeko, NoName...).
5. **Chuẩn hóa thuộc tính (Property Normalization):** Bổ sung các quy tắc phát hiện và chuẩn hóa các thuộc tính hệ thống lạ phát sinh từ các bản mod mới.
6. **Kiểm thử hồi quy (Regression Testing):** Đảm bảo các thay đổi mới không làm ảnh hưởng đến modem, sóng di động hay các dịch vụ hệ thống.
7. **Cải tiến tài liệu:** Hoàn thiện hướng dẫn kỹ thuật, sửa lỗi tài liệu và cập nhật bảng tương thích.

---

## 🔒 Quy Định Bảo Mật Dữ Liệu Khi Đóng Góp

Theo chính sách [PRIVACY.md](../PRIVACY.md):
- **Không gửi thông tin cá nhân:** Không chia sẻ tài khoản, mật khẩu, thông tin cá nhân hay bất kỳ dữ liệu nhạy cảm nào.
- **Xóa bỏ các định danh nhạy cảm (Redaction):** Khi gửi log hoặc ảnh chụp màn hình chẩn đoán, bắt buộc phải che giấu hoặc xóa bỏ:
  - IMEI, IMSI, Số điện thoại cá nhân
  - Số Serial phần cứng, Android ID
  - Địa chỉ MAC và địa chỉ IP công cộng
  - Token xác thực hoặc cookies phiên làm việc
  - File logcat đầy đủ chưa qua chọn lọc

---

## 📱 Báo Cáo Tương Thích Thiết Bị

Khi gửi Pull Request bổ sung thiết bị đã kiểm thử thành công, vui lòng cập nhật bảng trong `README.md` theo cấu trúc:

```markdown
| Tên Thiết Bị | Codename | Bản ROM HyperOS | Giải Pháp Root | Kernel SuSFS | Trạng Thái Tương Thích |
```

Trong nội dung PR, chỉ cần cung cấp các thông số kỹ thuật hệ thống sau:
- Codename (`getprop ro.product.device`)
- Phiên bản Android & HyperOS (`getprop ro.build.version.release`, `getprop ro.mi.os.version.name`)
- Phiên bản Kernel (`uname -r`)
- Trạng thái SELinux (`getenforce`)
- Giải pháp root và phiên bản (KernelSU / APatch / Magisk)

---

## 💻 Chuẩn Mực Mã Nguồn (Code Style)

- **POSIX Shell Standards:** Các script (`customize.sh`, `service.sh`, `uninstall.sh`) phải tuân thủ chuẩn POSIX `sh` (Toybox trên Android). Tránh dùng cú pháp riêng của Bash.
- **Bảo toàn kết nối vô tuyến (RIL / Modem):** Mọi can thiệp thuộc tính phải bảo toàn hậu tố phân vùng mạng (`_global`, `_eea_global`, `_in_global`) và chỉ thực thi sau khi hoàn tất khởi động (`sys.boot_completed=1`).
- **An toàn tệp tin:** Không bao giờ ghi đè hoặc sửa đổi trực tiếp vào các phân vùng hệ thống (`/system`, `/product`, `/vendor`).
