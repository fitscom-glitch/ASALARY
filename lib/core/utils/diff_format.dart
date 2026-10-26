import 'package:theo_doi_luong/core/utils/formatters.dart';

/// Chênh lệch tiền a so với b, có dấu: "+$12.50", "-$3.00", "$0.00".
String diffMoney(double a, double b) {
  final d = a - b;
  if (d.abs() < 0.005) return money(0);
  return '${d > 0 ? '+' : '-'}${money(d.abs())}';
}

/// Phần trăm a thay đổi so với b: "+12.3%". Rỗng nếu cả hai đều 0, "—" nếu b = 0 mà a > 0.
String diffPercent(double a, double b) {
  if (b.abs() < 0.005) return a.abs() < 0.005 ? '' : '—';
  return '${a >= b ? '+' : '-'}${((a - b).abs() / b * 100).toStringAsFixed(1)}%';
}

/// Chênh lệch số nguyên có dấu: "+3", "-2", "0".
String diffInt(int a, int b) {
  final d = a - b;
  return d > 0 ? '+$d' : '$d';
}
