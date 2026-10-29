/// Một ngày nghỉ có lương (Sick leave): số giờ nghỉ và mức lương theo giờ tại thời điểm tạo
/// (đổi lương mặc định về sau không làm đổi tiền của ngày nghỉ cũ).
class PaidLeave {
  const PaidLeave({required this.hours, required this.rate});
  final double hours;
  final double rate;

  double get pay => hours * rate;

  Map<String, dynamic> toJson() => {'hours': hours, 'rate': rate};

  /// Trả về null nếu dữ liệu không hợp lệ.
  static PaidLeave? fromJson(Object? j) {
    if (j is! Map) return null;
    final h = j['hours'], r = j['rate'];
    if (h is! num || r is! num || !h.isFinite || !r.isFinite || h <= 0 || h > 24 || r < 0) return null;
    return PaidLeave(hours: h.toDouble(), rate: r.toDouble());
  }

  /// Đọc cả bản đồ 'yyyy-MM-dd' -> PaidLeave, bỏ qua mục không hợp lệ.
  static Map<String, PaidLeave> mapFromJson(Object? j) {
    final out = <String, PaidLeave>{};
    if (j is Map) {
      for (final e in j.entries) {
        final k = e.key;
        if (k is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(k)) continue;
        final v = fromJson(e.value);
        if (v != null) out[k] = v;
      }
    }
    return out;
  }

  static Map<String, dynamic> mapToJson(Map<String, PaidLeave> m) => {
        for (final k in (m.keys.toList()..sort())) k: m[k]!.toJson(),
      };
}

/// Tổng tiền nghỉ có lương trong khoảng ngày [from, to).
double paidLeavePayIn(Map<String, PaidLeave> leave, DateTime from, DateTime to) {
  var sum = 0.0;
  for (final e in leave.entries) {
    final d = DateTime.tryParse(e.key);
    if (d == null || d.isBefore(from) || !d.isBefore(to)) continue;
    sum += e.value.pay;
  }
  return sum;
}
