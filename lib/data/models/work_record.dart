import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';

bool _near(double a, double b) => (a - b).abs() < 1e-6;

class WorkRecord {
  const WorkRecord({
    this.id,
    required this.start,
    required this.end,
    required this.dayType,
    required this.hourlyRate,
    this.totalHours = 0,
    this.regularHours = 0,
    this.otHours = 0,
    this.doubleHours = 0,
    this.earned = 0,
  });

  final int? id;
  final DateTime start;
  final DateTime end;
  final String dayType;
  final double hourlyRate;
  final double totalHours;
  final double regularHours;
  final double otHours; // x1.5
  final double doubleHours; // x2
  final double earned;

  int get minutes => end.difference(start).inMinutes;
  bool get overnight => dateOnly(end) != dateOnly(start);

  /// Tiền theo từng loại giờ (chưa làm tròn).
  double get regularPay => regularHours * hourlyRate;
  double get otPay => otHours * kOtMultiplier * hourlyRate;
  double get doublePay => doubleHours * kDoubleMultiplier * hourlyRate;

  WorkRecord withId(int newId) => WorkRecord(
        id: newId,
        start: start,
        end: end,
        dayType: dayType,
        hourlyRate: hourlyRate,
        totalHours: totalHours,
        regularHours: regularHours,
        otHours: otHours,
        doubleHours: doubleHours,
        earned: earned,
      );

  WorkRecord withPay({
    required double total,
    required double regular,
    required double ot,
    required double dbl,
    required double earned,
    required String dayType,
  }) =>
      WorkRecord(
        id: id,
        start: start,
        end: end,
        dayType: dayType,
        hourlyRate: hourlyRate,
        totalHours: total,
        regularHours: regular,
        otHours: ot,
        doubleHours: dbl,
        earned: earned,
      );

  bool samePay(WorkRecord o) =>
      dayType == o.dayType &&
      _near(totalHours, o.totalHours) &&
      _near(regularHours, o.regularHours) &&
      _near(otHours, o.otHours) &&
      _near(doubleHours, o.doubleHours) &&
      (earned - o.earned).abs() < 0.005;

  // Vẫn ghi dateStr/checkInStr/checkOutStr để tương thích cột cũ (NOT NULL).
  Map<String, Object?> toMap() => {
        'dateStr': dateFmt.format(start),
        'checkInStr': timeFmt.format(start),
        'checkOutStr': timeFmt.format(end),
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
        'totalHours': totalHours,
        'regularHours': regularHours,
        'otHours': otHours,
        'doubleTimeHours': doubleHours,
        'dayType': dayType,
        'hourlyRate': hourlyRate,
        'earned': earned,
      };

  static WorkRecord? fromMap(Map<String, Object?> m) {
    double n(String k) => (m[k] as num?)?.toDouble() ?? 0;
    final startMs = (m['startMs'] as num?)?.toInt() ?? 0;
    final endMs = (m['endMs'] as num?)?.toInt() ?? 0;
    if (startMs <= 0 || endMs <= startMs) return null;
    final type = m['dayType'] as String? ?? 'Thường';
    return WorkRecord(
      id: m['id'] as int?,
      start: DateTime.fromMillisecondsSinceEpoch(startMs),
      end: DateTime.fromMillisecondsSinceEpoch(endMs),
      dayType: dayTypes.contains(type) ? type : 'Thường',
      hourlyRate: n('hourlyRate'),
      totalHours: n('totalHours'),
      regularHours: n('regularHours'),
      otHours: n('otHours'),
      doubleHours: n('doubleTimeHours'),
      earned: n('earned'),
    );
  }
}
