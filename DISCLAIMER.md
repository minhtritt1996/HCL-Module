# Tuyên Bố Miễn Trừ Trách Nhiệm (Disclaimer)

*English version follows below the Vietnamese text.*

---

## Bản Tiếng Việt

**HyperOS Compatibility Layer** là một dự án phần mềm mã nguồn mở độc lập, do cộng đồng phát triển nhằm mục đích nâng cao tính tương thích hệ thống trên nền tảng Xiaomi HyperOS và các bản ROM tùy biến dựa trên HyperOS.

Dự án này **HOÀN TOÀN KHÔNG liên kết, không được tài trợ, không được ủy quyền, không được chứng thực hoặc có bất kỳ mối quan hệ chính thức nào** với Xiaomi Inc., Google LLC, bất kỳ cơ quan chính phủ, ngân hàng, tổ chức tài chính hoặc bên thứ ba nào được đề cập trong tài liệu và mã nguồn của kho lưu trữ này.

### 1. Mục Đích & Phạm Vi Dự Án
Phần mềm này được phát triển phục vụ các mục đích:
- **Nghiên cứu khoa học và kỹ thuật phần mềm** (Research);
- **Tăng cường tính tương thích liên tác** (Interoperability);
- **Chẩn đoán và chuẩn hóa cấu hình hệ thống** (Diagnostics);
- **Tương thích môi trường ROM tùy biến** (Custom ROM Compatibility);
- **Tùy biến và kiểm soát thiết bị cá nhân** thuộc quyền sở hữu hợp pháp của người dùng.

Dự án tập trung vào việc chuẩn hóa cục bộ các thuộc tính hệ thống Android (`build.prop`, `system properties`) bị cấu hình sai lệch hoặc không nhất quán trong các bản ROM tùy biến, đưa thiết bị về trạng thái tương thích chuẩn của hệ điều hành.

### 2. Giới Hạn Về Tính Tương Thích Ứng Dụng Bên Thứ Ba
- Dự án **không cam kết hoặc bảo đảm** rằng bất kỳ ứng dụng hoặc dịch vụ cụ thể nào sẽ hoạt động ổn định trên môi trường Android đã tùy biến hoặc có quyền root.
- **Tính tương thích với các ứng dụng bên thứ ba không được bảo đảm và có thể thay đổi** khi các ứng dụng đó hoặc chính sách bảo mật/hệ thống máy chủ của họ được cập nhật.

### 3. Trách Nhiệm Của Người Dùng
Người dùng hoàn toàn tự chịu trách nhiệm về:
- Việc cài đặt, cấu hình và vận hành phần mềm này trên thiết bị của mình;
- Bản ROM, Kernel, giải pháp root và các can thiệp phần mềm liên quan;
- Việc tuân thủ toàn bộ các quy định pháp luật hiện hành tại quốc gia sở tại;
- Việc tuân thủ Điều khoản dịch vụ (Terms of Service), thỏa thuận người dùng cuối (EULA) và các tiêu chuẩn bảo mật của các ứng dụng/dịch vụ bên thứ ba;
- Tự sao lưu toàn bộ dữ liệu (backup) trước khi thực hiện bất kỳ can thiệp nào vào thiết bị.

Nghiêm cấm người dùng sử dụng phần mềm này để truy cập trái phép vào các hệ thống thông tin, cơ sở dữ liệu, tài khoản cá nhân, hoặc gây gián đoạn hoạt động của các dịch vụ công và dịch vụ tài chính.

### 4. Dữ Liệu Cá Nhân & Bảo Mật
- Dự án được thiết kế vận hành cục bộ trên thiết bị của người dùng.
- Bản thân module **không triển khai bất kỳ cơ chế thu thập dữ liệu (telemetry) hay kết nối máy chủ ngầm nào**.
- Tác giả và những người đóng góp không thu thập, không lưu trữ và không xử lý thông tin định danh, tài khoản ngân hàng, mật khẩu, mã OTP hay dữ liệu sinh trắc học của người dùng.

### 5. An Toàn Thiết Bị & Miễn Trừ Trách Nhiệm Pháp Lý
- Việc can thiệp hệ thống Android ở cấp độ root/kernel luôn tiềm ẩn rủi ro (lỗi khởi động, mất dữ liệu, ảnh hưởng bảo hành phần cứng). Người dùng tự chịu mọi rủi ro khi cài đặt.
- Phần mềm này được cung cấp theo nguyên trạng **"AS IS"**, không đi kèm bất kỳ sự bảo đảm nào, dù rõ ràng hay ngụ ý.
- Trong mọi trường hợp, trong giới hạn tối đa mà pháp luật cho phép, tác giả và những người đóng góp vào dự án sẽ **không chịu trách nhiệm** đối với bất kỳ thiệt hại nào phát sinh từ việc sử dụng hoặc không thể sử dụng phần mềm này.

---

## English Version

### Disclaimer

**HyperOS Compatibility Layer** is an independent open-source Android compatibility project developed by the community.

This project is **not affiliated with, endorsed by, sponsored by, or officially associated with** Xiaomi Inc., Google LLC, any government agency, bank, financial institution, or any other third-party service mentioned in this repository.

### 1. Purpose and Scope
This project is provided strictly for:
- **Research, academic, and educational exploration**;
- **Interoperability improvement**;
- **System configuration diagnostics**;
- **Custom ROM environment compatibility**;
- **Personal device customization** on devices owned by the user.

The project focuses on locally normalizing Android system properties (`build.prop`, environment flags) that are misconfigured or inconsistent in third-party custom ROM environments based on Xiaomi HyperOS.

### 2. Third-Party Application Compatibility
- The project does not guarantee that any specific application or service will function on modified, unlocked, or rooted Android devices.
- **Compatibility with third-party applications is not guaranteed and may change when those applications or their security policies are updated.**

### 3. User Responsibility
Users are solely responsible for:
- The installation, configuration, and operation of this software on their device;
- The choice of custom ROM, kernel, root solution, and associated system modifications;
- Ensuring strict compliance with applicable local laws and regulations;
- Complying with third-party Terms of Service, EULAs, and application security policies;
- Maintaining adequate backups before performing any device modifications.

This software must NOT be used for unauthorized access to systems, networks, accounts, or services, or for any malicious purpose.

### 4. Data Privacy
- This software is designed to operate locally on the user's device.
- **The module itself does not implement telemetry, analytics, or remote data collection.**
- The authors and contributors do not collect, store, transmit, or process user credentials, national ID records, biometric data, banking information, or passwords.

### 5. Device Safety and Limitation of Liability
- Modifying Android system properties or installing kernel-level modules may cause boot failure, data loss, application instability, or void device warranty.
- This software is distributed under the MIT License on an **"AS IS"** basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
- To the maximum extent permitted by law, the authors and contributors shall have no liability for any direct, indirect, incidental, or consequential damages arising from the use of this software.

---

**Copyright © 2026 minhtritt1996 and contributors.**  
*This document is general project documentation and does not constitute formal legal advice.*
