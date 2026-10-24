import 'package:theo_doi_luong/data/models/work_record.dart';

/// Chọn các ca sẽ được thêm vào (bỏ qua ca trùng giờ với ca đã có hoặc đã chọn).
({List<WorkRecord> add, int skipped}) planImport(List<WorkRecord> existing, List<WorkRecord> incoming) {
  final occupied = List<WorkRecord>.of(existing);
  final add = <WorkRecord>[];
  var skipped = 0;
  final sorted = [...incoming]..sort((a, b) => a.start.compareTo(b.start));
  for (final r in sorted) {
    final clash = occupied.any((x) => x.start.isBefore(r.end) && x.end.isAfter(r.start));
    if (clash) {
      skipped++;
      continue;
    }
    occupied.add(r);
    add.add(r);
  }
  return (add: add, skipped: skipped);
}
