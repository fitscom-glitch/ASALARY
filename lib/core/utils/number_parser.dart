/// Nhận cả "23.5", "23,5", "1,234.50", "1.234,50".
double? parseNumber(String input) {
  var s = input.trim().replaceAll(RegExp(r'[\s$]'), '');
  if (s.isEmpty) return null;
  final hasComma = s.contains(',');
  final hasDot = s.contains('.');
  if (hasComma && hasDot) {
    final commaIsDecimal = s.lastIndexOf(',') > s.lastIndexOf('.');
    s = commaIsDecimal ? s.replaceAll('.', '').replaceAll(',', '.') : s.replaceAll(',', '');
  } else if (hasComma) {
    s = s.replaceAll(',', '.');
  }
  final v = double.tryParse(s);
  return (v == null || !v.isFinite || v < 0) ? null : v;
}
