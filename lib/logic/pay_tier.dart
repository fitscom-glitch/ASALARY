import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/logic/pay_calculator.dart';

/// Loại giờ mà phút làm việc tiếp theo sẽ được tính.
enum PayTier { regular, ot, double }

/// Loại giờ hiện tại của hôm nay = loại giờ mà phút làm việc tiếp theo sẽ được tính.
/// Dùng chính [PayCalculator] nên khớp với cách tính lương (kể cả ca đang làm):
///  - ngày lễ: x2;
///  - ngày thường: giờ thường cho đến khi đủ 8 giờ trong ngày (hoặc đủ 40 giờ/tuần), sau đó OT;
///  - thứ 7, CN: giờ thường nếu đang bù cho đủ 40 giờ, đến khi đủ 40 giờ (hoặc quá 8 giờ) thì OT.
///
/// Dùng chung cho vòng tròn ngày hôm nay ở biểu đồ tuần và nhãn loại giờ ở thẻ ca đang làm.
PayTier currentPayTier(
  List<WorkRecord> records,
  Set<String> holidays,
  ActiveShift? active, {
  DateTime? now,
}) {
  final end = floorMinute(now ?? DateTime.now());
  final a = active;

  // Đang trong ca: mỗi ca được tính theo NGÀY BẮT ĐẦU (kể cả khi đã qua nửa đêm), nên loại giờ hiện tại là
  // phần giờ tăng thêm của chính ca này khi kéo dài thêm 1 phút (so với tính đến phút hiện tại).
  if (a != null && end.add(const Duration(minutes: 1)).isAfter(a.start)) {
    final m = startOfWeek(a.start, DateTime.monday);
    final monday = DateTime(m.year, m.month, m.day);
    final next = DateTime(monday.year, monday.month, monday.day + 7);
    final base = <WorkRecord>[
      for (final r in records)
        if (!r.start.isBefore(monday) && r.start.isBefore(next)) r,
    ];
    const liveId = -2;
    WorkRecord live(DateTime until) => PayCalculator.calculate(
          [...base, WorkRecord(id: liveId, start: a.start, end: until, dayType: 'Thường', hourlyRate: 1)],
          holidays,
        ).firstWhere((r) => r.id == liveId);

    final after = live(end.add(const Duration(minutes: 1)));
    final before = end.isAfter(a.start) ? live(end) : null;
    const eps = 1e-9;
    if (after.doubleHours - (before?.doubleHours ?? 0) > eps) return PayTier.double;
    if (after.otHours - (before?.otHours ?? 0) > eps) return PayTier.ot;
    return PayTier.regular;
  }

  // Không có ca đang làm: loại giờ của một phút làm việc bắt đầu ngay bây giờ.
  final m = startOfWeek(end, DateTime.monday);
  final monday = DateTime(m.year, m.month, m.day);
  final next = DateTime(monday.year, monday.month, monday.day + 7);
  final raw = <WorkRecord>[
    for (final r in records)
      if (!r.start.isBefore(monday) && r.start.isBefore(next)) r,
  ];
  const probeId = -1;
  raw.add(WorkRecord(
    id: probeId,
    start: end,
    end: end.add(const Duration(minutes: 1)),
    dayType: 'Thường',
    hourlyRate: 1,
  ));
  final probe = PayCalculator.calculate(raw, holidays).firstWhere((r) => r.id == probeId);
  if (probe.doubleHours > 0) return PayTier.double;
  if (probe.otHours > 0) return PayTier.ot;
  return PayTier.regular;
}
