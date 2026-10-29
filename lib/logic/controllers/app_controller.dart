import 'package:flutter/foundation.dart' show ChangeNotifier, setEquals;

import 'package:theo_doi_luong/core/utils/date_utils.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart' show dateFmt;
import 'package:theo_doi_luong/data/database/app_database.dart';
import 'package:theo_doi_luong/data/models/backup_data.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/data/models/record_draft.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/data/preferences/active_shift.dart';
import 'package:theo_doi_luong/data/preferences/app_settings.dart';
import 'package:theo_doi_luong/logic/day_type.dart';
import 'package:theo_doi_luong/logic/import_planner.dart';
import 'package:theo_doi_luong/logic/pay_calculator.dart';

class AppController extends ChangeNotifier {
  AppController(this._db);
  final AppDatabase _db;

  List<WorkRecord> records = const []; // mới nhất trước
  AppSettings settings = const AppSettings();
  ActiveShift? active;
  bool loading = true;
  String? loadError;
  int skipped = 0; // bản ghi cũ không đọc được (vẫn còn trong file DB)

  Future<void> load() async {
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      settings = await AppSettings.load();
      active = await ActiveShift.load(settings.hourlyRate);
      skipped = await _db.countUnreadable();
      await _recalculate(await _db.getAll());
    } catch (e) {
      loadError = '$e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _recalculate(await _db.getAll());
    } catch (e) {
      loadError = '$e';
      notifyListeners();
    }
  }

  /// Tính lại toàn bộ và chỉ ghi những bản ghi có thay đổi.
  Future<void> _recalculate(List<WorkRecord> raw) async {
    final calculated = PayCalculator.calculate(raw, settings.holidays);
    final before = {for (final r in raw) r.id: r};
    final changed = [
      for (final r in calculated)
        if (before[r.id]?.samePay(r) != true) r
    ];
    await _db.updateAll(changed);
    records = calculated.reversed.toList();
    notifyListeners();
  }

  String? validate(RecordDraft d) {
    if (!d.end.isAfter(d.start)) return 'Giờ ra phải sau giờ vào.';
    if (d.end.difference(d.start) > const Duration(hours: 24)) {
      return 'Một ca tối đa 24 giờ.';
    }
    final clash = records.any(
      (r) => r.id != d.id && r.start.isBefore(d.end) && r.end.isAfter(d.start),
    );
    return clash ? 'Ca này trùng giờ với một ca đã có.' : null;
  }

  Future<String?> saveDraft(RecordDraft d) async {
    final err = validate(d);
    if (err != null) return err;
    try {
      final base = WorkRecord(
        id: d.id,
        start: d.start,
        end: d.end,
        dayType: 'Thường', // loại ngày thật do PayCalculator suy ra
        hourlyRate: d.rate,
      );
      final int id;
      if (d.id == null) {
        id = await _db.insert(base);
      } else {
        await _db.update(base);
        id = d.id!;
      }
      await _recalculate([...records.where((r) => r.id != id), base.withId(id)]);
      return null;
    } catch (e) {
      return 'Không thể lưu: $e';
    }
  }

  Future<String?> delete(WorkRecord r) async {
    try {
      await _db.delete(r.id!);
      await _recalculate(records.where((x) => x.id != r.id).toList());
      return null;
    } catch (e) {
      return 'Không thể xóa: $e';
    }
  }

  Future<void> updateSettings(AppSettings s) async {
    final holidaysChanged = !setEquals(settings.holidays, s.holidays);
    settings = s;
    await s.save();
    if (holidaysChanged) {
      await _recalculate(List.of(records)); // đổi ngày lễ → tính lại
    } else {
      notifyListeners();
    }
  }

  /// Thêm hoặc sửa ngày nghỉ có lương (ghi đè nếu ngày đó đã có).
  Future<void> setPaidLeave(DateTime day, double hours, double rate) => updateSettings(
        settings.copyWith(paidLeave: {
          ...settings.paidLeave,
          dateFmt.format(day): PaidLeave(hours: hours, rate: rate),
        }),
      );

  Future<void> removePaidLeave(String key) =>
      updateSettings(settings.copyWith(paidLeave: {...settings.paidLeave}..remove(key)));

  String dayTypeFor(DateTime d) => dayTypeOf(d, settings.holidays);

  Future<void> checkIn(double rate) async {
    final start = floorMinute(DateTime.now());
    final shift = ActiveShift(start: start, dayType: dayTypeFor(start), rate: rate);
    await shift.save();
    active = shift;
    notifyListeners();
  }

  /// Sửa giờ vào của ca đang làm (khi bấm "Vào ca" trễ vì quên). Giữ nguyên mức lương, tính lại loại ngày.
  Future<String?> updateActiveStart(DateTime newStart) async {
    final shift = active;
    if (shift == null) return null;
    final start = floorMinute(newStart);
    final now = DateTime.now();
    if (start.isAfter(now)) return 'Giờ vào không được ở tương lai.';
    if (now.difference(start) > const Duration(hours: 24)) return 'Một ca tối đa 24 giờ.';
    if (records.any((r) => r.start.isBefore(now) && r.end.isAfter(start))) {
      return 'Giờ vào trùng với một ca đã có.';
    }
    final updated = ActiveShift(start: start, dayType: dayTypeFor(start), rate: shift.rate);
    await updated.save();
    active = updated;
    notifyListeners();
    return null;
  }

  Future<String?> checkOut() async {
    final shift = active;
    if (shift == null) return null;
    final end = floorMinute(DateTime.now());
    if (!end.isAfter(shift.start)) {
      return 'Ca làm cần ít nhất 1 phút. Bấm "Hủy ca" nếu bạn bấm nhầm.';
    }
    try {
      final base = WorkRecord(
        start: shift.start,
        end: end,
        dayType: shift.dayType,
        hourlyRate: shift.rate,
      );
      final id = await _db.insert(base);
      await ActiveShift.clear();
      active = null;
      await _recalculate([...records, base.withId(id)]);
      return null;
    } catch (e) {
      return 'Không thể lưu ca: $e';
    }
  }

  Future<void> discardActive() async {
    await ActiveShift.clear();
    active = null;
    notifyListeners();
  }

  BackupData buildBackup() => BackupData(
        records: records.reversed.toList(),
        hourlyRate: settings.hourlyRate,
        holidays: Set<String>.of(settings.holidays),
        paidLeave: Map.of(settings.paidLeave),
        lang: settings.lang,
        reminders: settings.reminders,
        companyName: settings.companyName,
        userName: settings.userName,
        userId: settings.userId,
        exportedAt: DateTime.now(),
      );

  Future<({int added, int skipped})> importBackup(BackupData d, {required bool replace}) async {
    final plan = planImport(replace ? const <WorkRecord>[] : records, d.records);
    if (replace) {
      await _db.replaceWith(plan.add);
    } else {
      await _db.insertAll(plan.add);
    }
    settings = replace
        ? settings.copyWith(
            hourlyRate: d.hourlyRate,
            holidays: Set<String>.of(d.holidays),
            paidLeave: Map.of(d.paidLeave),
            lang: d.lang,
            reminders: d.reminders,
            companyName: d.companyName,
            userName: d.userName,
            userId: d.userId,
          )
        : settings.copyWith(
            holidays: {...settings.holidays, ...d.holidays},
            paidLeave: {...settings.paidLeave, ...d.paidLeave},
          );
    await settings.save();
    await _recalculate(await _db.getAll());
    return (added: plan.add.length, skipped: plan.skipped);
  }
}
