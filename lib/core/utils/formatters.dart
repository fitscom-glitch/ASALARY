import 'package:intl/intl.dart' show DateFormat, NumberFormat;

String fmtStart(DateTime d) => '${pad2(d.hour)}:${pad2(d.minute)} ${pad2(d.day)}/${pad2(d.month)}';

final _moneyFmt = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);

final rateFmt = NumberFormat('0.##', 'en_US');

final dateFmt = DateFormat('yyyy-MM-dd');

final dmyFmt = DateFormat('dd/MM/yyyy');

final timeFmt = DateFormat('HH:mm');

String money(double v) => _moneyFmt.format(v);

String fmtHours(double hours) {
  final m = (hours * 60).round();
  return '${m ~/ 60}h${(m % 60).toString().padLeft(2, '0')}';
}

String pad2(int n) => n.toString().padLeft(2, '0');

String weekLabel(DateTime monday) {
  final sun = DateTime(monday.year, monday.month, monday.day + 6);
  return '${pad2(monday.day)}/${pad2(monday.month)} – ${pad2(sun.day)}/${pad2(sun.month)}/${sun.year}';
}
