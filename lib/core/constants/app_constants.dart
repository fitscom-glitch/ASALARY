const dayTypes = ['Thường', 'OT', 'Lễ'];

const kDefaultRate = 25.0;

/// Tên hiển thị và phiên bản của ứng dụng.
/// Phiên bản lấy từ dòng `version:` trong pubspec.yaml: workflow truyền vào bằng --dart-define=APP_VERSION.
/// Giá trị mặc định chỉ dùng khi chạy ngoài workflow (DartPad, chạy thử).
const kAppName = 'ASALARY';
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.1.0');

/// Hệ số lương làm thêm giờ (giờ 8–12 trong ngày) và giờ x2 (trên 12 giờ, ngày lễ).
const kOtMultiplier = 1.5;
const kDoubleMultiplier = 2.0;

/// Số nhắc nhở tối đa.
const kMaxReminders = 20;
