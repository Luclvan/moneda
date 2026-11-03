# Moneda 🪙
> **Quản lý tài chính cá nhân thông minh theo quy tắc 3 hũ (50/30/20)**  
> Phong cách ngân hàng hiện đại (MB Bank Style) — Tối ưu hóa cho **iOS Native** & **Web**.

[![Flutter CI](https://github.com/levanluc/moneda/actions/workflows/ci.yml/badge.svg)](https://github.com/levanluc/moneda/actions)
[![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Web-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

---

## 📌 1. Bài toán thực tế & Giải pháp của Moneda

### 🔴 Vấn đề thực tế
Đa phần người đi làm và bạn trẻ hiện nay giữ toàn bộ thu nhập hàng tháng trong **một tài khoản ngân hàng duy nhất**:
- **Ngộ nhận số dư khả dụng:** Khi thấy tài khoản còn nhiều tiền, người dùng có xu hướng thoải mái chi tiêu cho các nhu cầu ăn uống, mua sắm lặt vặt không cần thiết.
- **Tiêu lạm vào tiền tiết kiệm & tiền thiết yếu:** Đến cuối tháng, các khoản tiền thuê nhà, hóa đơn điện nước hay tiền tích lũy đều bị "ăn lẹm", dẫn đến tình trạng rỗng túi và không có quỹ dự phòng khẩn cấp.
- **Ghi chép thủ công tốn thời gian:** Các app quản lý tài chính truyền thống bắt phân loại quá nhiều danh mục chi li, làm người dùng nản lòng sau vài ngày.

### 🟢 Giải pháp đột phá từ Moneda
Moneda áp dụng triệt để **Quy tắc 3 hũ ngân sách 50/30/20** của các chuyên gia tài chính thế giới:
1. **Hũ Cần thiết (NEED - 50%):** Tiền thuê nhà, ăn uống cơ bản, điện nước, xăng xe, y tế.
2. **Hũ Mong muốn (WANT - 30%):** Mua sắm, xem phim, cà phê, du lịch, giải trí cá nhân.
3. **Hũ Tích lũy (SAVE - 20%):** Quỹ dự phòng khẩn cấp, tiết kiệm mua sắm lớn, đầu tư dài hạn.

Ngay khi nhận một khoản tiền, Moneda **tự động phân bổ** vào 3 hũ riêng biệt. Khi chi tiêu, tiền chỉ được trích từ hũ tương ứng. **Hũ nào hết tiền thì lập tức bị khóa chi tiêu cho hũ đó**, bảo vệ quỹ tích lũy một cách tự nhiên và bền vững.

---

## 🚀 2. Các tính năng cốt lõi

```mermaid
flowchart TD
    Income[Thu nhập vào] --> Allocation{Quy tắc 3 hũ 50/30/20}
    Allocation -->|50%| Need[Hũ Cần thiết - NEED]
    Allocation -->|30%| Want[Hũ Mong muốn - WANT]
    Allocation -->|20%| Save[Hũ Tích lũy - SAVE]
    
    Need --> ExpenseNeed[Thanh toán hóa đơn / Sinh hoạt]
    Want --> ExpenseWant[Thanh toán mua sắm / Giải trí]
    Save --> Goals[Nạp vào Mục tiêu tiết kiệm]
    
    Need -.->|Dư cuối chu kỳ| Rollover[Kết chuyển chủ động]
    Want -.->|Dư cuối chu kỳ| Rollover
    Rollover --> Save
```

### 1. Thẻ số dư Carousel & Chế độ ẩn/hiện số dư tĩnh lặng
- Khối thẻ số dư trượt ngang 4 trang mượt mà: **Tổng số dư**, **Hũ Need (Xanh biển)**, **Hũ Want (Tím)**, **Hũ Save (Xanh ngọc)**.
- Nút con mắt giúp ẩn số dư tức thì khi ở nơi công cộng, tự động lưu trạng thái bảo mật vào `SharedPreferences`.

### 2. Nhận tiền & Phân bổ tự động chuẩn từng đồng
- Nhập số tiền thu nhập bất kỳ, hệ thống tính toán phân bổ vào 3 hũ theo thời gian thực.
- Thuật toán `MonedaValidator.calculateIncomeAllocation` đảm bảo **bảo toàn 100%**, xử lý phần dư làm tròn chính xác tuyệt đối, không lệch dù chỉ 1 đồng VND.
- Hỗ trợ tùy chọn phân bổ tự động theo tỷ lệ hoặc nạp thẳng 100% vào một hũ chỉ định.

### 3. Thanh toán thông minh & Chặn tuyệt đối chi tiêu âm quỹ
- Giao diện thanh toán 4 trường tinh gọn: *Hũ chi tiêu*, *Số tiền*, *Danh mục*, *Nội dung chi tiết*.
- **Floating Suggestions Dropdown:** Chạm vào ô nhập là nổi danh sách gợi ý danh mục và nội dung sắp xếp theo **tần suất chi tiêu cao nhất**, tự động lọc khi gõ phím mà không đẩy tụt các thành phần giao diện phía dưới.
- **Chặn âm quỹ (Anti-Negative Balance):** Tự động so sánh số tiền nhập với số dư thực tế của hũ đã chọn. Nếu số tiền vượt số dư, hệ thống báo đỏ cảnh báo và khóa nút Tiếp tục.

### 4. Kết chuyển tiền dư sang Hũ Tích lũy (Rollover)
- Khi có thông báo nhắc nhở chu kỳ mới, bấm vào icon Chuông thông báo trên Header để mở màn hình **Kết chuyển tiền dư**.
- Cho phép người dùng chuyển toàn bộ số tiền còn thừa trong Hũ Need và Hũ Want sang Hũ Save để tăng tối đa tiền tiết kiệm.

### 5. Báo cáo & Sao kê ngân sách 3 tầng (Accordion)
- Theo dõi biến động thu nhập, chi tiêu và tăng trưởng tích lũy theo từng tháng.
- Sao kê phân tầng dạng Accordion trực quan, cho phép lọc theo hũ, thời gian và từ khóa giao dịch.

### 6. Quản lý Mục tiêu tiết kiệm (Saving Goals)
- Tạo mục tiêu tích lũy có kỳ hạn (mua laptop, quỹ du lịch, quỹ khẩn cấp...).
- **Nạp tiền:** Trích an toàn từ Hũ Save (không cho phép nạp vượt quá số dư Hũ Save).
- **Rút tiền:** Rút tiền đã tích lũy từ mục tiêu về lại các hũ khi đạt kế hoạch.

### 7. Tiện ích Slider tự cân bằng 100% & Chuyển tiền nội bộ
- **Slider tỷ lệ 3 hũ:** Thuật toán tự cân đối 3 trục, khi kéo bất kỳ thanh nào thì 2 thanh còn lại tự điều chỉnh để tổng luôn duy trì chính xác 100% ở mọi biên độ (kể cả chạm 0% hoặc 100%).
- **Chuyển tiền nội bộ:** Hỗ trợ linh hoạt chuyển tiền giữa các hũ khi phát sinh nhu cầu đột xuất.

### 8. Bảo mật Sinh trắc học Face ID & Vân tay Native
- Biểu tượng **Face ID (Apple)** và **Vân tay (Samsung)** vẽ chuẩn từng nét bằng vector `CustomPainter`.
- Tích hợp `local_auth` xác thực phần cứng và `flutter_secure_storage` lưu thông tin đăng nhập an toàn trong Keychain / Keystore.
- Tự động nhận diện Face ID để đăng nhập 1 chạm vào app.

---

## 🛠️ 3. Kiến trúc kỹ thuật & Tech Stack

| Thành phần | Công nghệ sử dụng | Mục đích |
|---|---|---|
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart 3.x) | Ứng dụng đa nền tảng tối ưu cho iOS và Web |
| **Giao diện** | Material 3 + Custom MB Bank Style | Màu chủ đạo `#1E40AF`, `#F8FAFC`, `#FFFFFF`, bo góc mềm 16-24px |
| **Backend & CSDL** | [Supabase](https://supabase.com) (PostgreSQL 15) | Lưu trữ đám mây, Row Level Security (RLS), Stored Procedures (RPC) |
| **Xác thực** | Supabase Auth + Local Auth | Đăng nhập tài khoản & xác thực Face ID / Vân tay |
| **Bảo mật cục bộ** | `flutter_secure_storage` | Lưu trữ token và mật khẩu mã hóa trong Keychain của iOS |
| **Bộ nhớ đệm** | In-Memory Zero-Spinner Caching | Mở app hiển thị số dư tức thì 0.0s, không màn hình chờ xoay vòng |
| **Xử lý bàn phím** | `GestureDetector` Root Unfocus | Chạm ra ngoài vùng nhập để hạ bàn phím số iOS mượt mà |
| **Kiểm thử & CI** | Flutter Test + GitHub Actions | 144 unit & widget tests tự động chạy kiểm thử 100% pass |

---

## 📱 4. Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Yêu cầu môi trường
- Flutter SDK `>= 3.13.0`
- Xcode 15+ (đối với bản iOS)
- CocoaPods `>= 1.12.0`
- Trình duyệt Chrome / Safari

### 2. Cấu hình dự án
1. Clone mã nguồn về máy:
   ```bash
   git clone https://github.com/levanluc/moneda.git
   cd moneda
   ```
2. Cài đặt các gói phụ thuộc:
   ```bash
   flutter pub get
   ```
3. Cấu hình kết nối Supabase trong file `lib/core/config/supabase_config.dart`:
   ```dart
   class SupabaseConfig {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

### 3. Chạy ứng dụng

#### 👉 Chạy trên Web:
```bash
flutter run -d chrome
```

#### 👉 Chạy trên iPhone thật hoặc Simulator iOS:
```bash
cd ios
pod install
cd ..
flutter run -d ios
```

### 4. Kiểm tra mã nguồn & Chạy kiểm thử tự động
- Kiểm tra phân tích tĩnh (linter):
  ```bash
  flutter analyze
  ```
- Chạy toàn bộ bộ kiểm thử tự động (144 tests):
  ```bash
  flutter test -r expanded
  ```

---

## 👥 Đóng góp & Tác giả
- Tác giả: **Lê Văn Lực**
- Giấy phép: MIT License — bạn có thể tự do sử dụng và tùy biến cho mục đích cá nhân.
