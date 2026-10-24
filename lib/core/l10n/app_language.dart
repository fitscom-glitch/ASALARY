// Đa ngôn ngữ (Tiếng Việt / English).
// Chuỗi gốc viết bằng tiếng Việt. Khi chọn English, Text và tr() tra bảng dịch
// trong en_translations.dart (khớp nguyên câu hoặc theo mẫu cho câu có số liệu).

String currentLang = 'vi';

const supportedLangs = {'vi': 'Tiếng Việt', 'en': 'English'};

List<String> get weekdayShort => currentLang == 'en'
    ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

List<String> get weekdayFull => currentLang == 'en'
    ? const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    : const ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];

/// Tên loại ngày để hiển thị (giá trị lưu trữ vẫn là 'Thường' / 'OT' / 'Lễ').
String dayLabel(String type) {
  if (currentLang != 'en') return type;
  return switch (type) {
    'Lễ' => 'Holiday',
    'OT' => 'Weekend',
    _ => 'Weekday',
  };
}

List<String> get monthShort => currentLang == 'en'
    ? const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    : const ['Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6', 'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12'];
