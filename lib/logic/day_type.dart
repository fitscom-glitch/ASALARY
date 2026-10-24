import 'package:theo_doi_luong/core/utils/formatters.dart';

/// Loại ngày tự suy ra: ngày lễ (đánh dấu trong cài đặt) > thứ 7/CN (OT) > ngày thường.
String dayTypeOf(DateTime d, Set<String> holidays) {
  if (holidays.contains(dateFmt.format(d))) return 'Lễ';
  return d.weekday >= DateTime.saturday ? 'OT' : 'Thường';
}
