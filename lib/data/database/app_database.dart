import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:sqflite/sqflite.dart';

import 'package:theo_doi_luong/core/constants/app_constants.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();

  Future<Database>? _open;

  Future<Database> get db async {
    try {
      return await (_open ??= _openDb());
    } catch (_) {
      _open = null;
      rethrow;
    }
  }

  Future<Database> _openDb() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'work_records_v3.db');
    await _backupOnce(path);
    final db = await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _importLegacy(db, dir);
    return db;
  }

  /// Nhập một lần dữ liệu từ các file DB tên cũ (nếu có). Không bao giờ làm
  /// app lỗi khi mở: thất bại thì bỏ qua và thử lại ở lần mở sau.
  Future<void> _importLegacy(Database db, String dir) async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble('hourlyRate') ?? kDefaultRate;

    for (final name in const ['work_records.db', 'work_records_v2.db']) {
      final flag = 'legacyImported:$name';
      if (prefs.getBool(flag) == true) continue;
      try {
        final legacyPath = p.join(dir, name);
        if (!await databaseExists(legacyPath)) continue;

        final old = await openDatabase(legacyPath, readOnly: true);
        try {
          final rows = await old.query('records');
          final batch = db.batch();
          for (final m in rows) {
            final start = DateTime.tryParse('${m['dateStr']} ${m['checkInStr']}:00');
            final end0 = DateTime.tryParse('${m['dateStr']} ${m['checkOutStr']}:00');
            if (start == null || end0 == null) continue;
            var end = end0;
            if (!end.isAfter(start)) {
              end = DateTime(end.year, end.month, end.day + 1, end.hour, end.minute);
            }
            final type = m['dayType'] as String?;
            final oldRate = (m['hourlyRate'] as num?)?.toDouble();
            batch.insert(
              'records',
              WorkRecord(
                start: start,
                end: end,
                dayType: dayTypes.contains(type) ? type! : 'Thường',
                hourlyRate: (oldRate != null && oldRate > 0) ? oldRate : rate,
              ).toMap(),
            );
          }
          await batch.commit(noResult: true);
        } finally {
          await old.close();
        }
        await prefs.setBool(flag, true);
      } catch (_) {
        // bỏ qua, thử lại lần mở sau
      }
    }
  }

  /// Chép file DB hiện có sang bản .bak một lần duy nhất, trước khi nâng cấp
  /// cấu trúc. Nếu có sự cố, dữ liệu gốc vẫn còn nguyên.
  Future<void> _backupOnce(String path) async {
    try {
      final src = File(path);
      final bak = File('$path.pre_v5.bak');
      if (await src.exists() && !await bak.exists()) await src.copy(bak.path);
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateStr TEXT NOT NULL,
        checkInStr TEXT NOT NULL,
        checkOutStr TEXT NOT NULL,
        startMs INTEGER NOT NULL DEFAULT 0,
        endMs INTEGER NOT NULL DEFAULT 0,
        totalHours REAL NOT NULL DEFAULT 0,
        regularHours REAL NOT NULL DEFAULT 0,
        otHours REAL NOT NULL DEFAULT 0,
        doubleTimeHours REAL NOT NULL DEFAULT 0,
        dayType TEXT NOT NULL DEFAULT 'Thường',
        hourlyRate REAL NOT NULL DEFAULT 0,
        earned REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_records_start ON records(startMs)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final cols = (await db.rawQuery('PRAGMA table_info(records)'))
        .map((c) => c['name'] as String)
        .toSet();
    Future<void> add(String name, String type) async {
      if (!cols.contains(name)) {
        await db.execute('ALTER TABLE records ADD COLUMN $name $type NOT NULL DEFAULT 0');
      }
    }

    await add('doubleTimeHours', 'REAL');
    await add('hourlyRate', 'REAL');
    await add('startMs', 'INTEGER');
    await add('endMs', 'INTEGER');

    // Chuyển bản ghi cũ (chuỗi ngày + HH:mm) sang mốc thời gian đầy đủ.
    final rows = await db.query(
      'records',
      columns: ['id', 'dateStr', 'checkInStr', 'checkOutStr'],
      where: 'startMs = 0',
    );
    final batch = db.batch();
    for (final r in rows) {
      final start = DateTime.tryParse('${r['dateStr']} ${r['checkInStr']}:00');
      final end0 = DateTime.tryParse('${r['dateStr']} ${r['checkOutStr']}:00');
      if (start == null || end0 == null) continue;
      var end = end0;
      if (!end.isAfter(start)) {
        end = DateTime(end.year, end.month, end.day + 1, end.hour, end.minute);
      }
      batch.update(
        'records',
        {'startMs': start.millisecondsSinceEpoch, 'endMs': end.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
    }
    await batch.commit(noResult: true);
    await db.execute('CREATE INDEX IF NOT EXISTS idx_records_start ON records(startMs)');
  }

  Future<List<WorkRecord>> getAll() async {
    final rows = await (await db).query('records', orderBy: 'startMs DESC, id DESC');
    return rows.map(WorkRecord.fromMap).whereType<WorkRecord>().toList();
  }

  /// Số dòng còn trong DB nhưng không đọc được (giờ/ngày hỏng). Không bị xóa.
  Future<int> countUnreadable() async {
    final rows = await (await db).rawQuery(
      'SELECT COUNT(*) FROM records WHERE startMs <= 0 OR endMs <= startMs',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> insert(WorkRecord r) async => (await db).insert('records', r.toMap());

  Future<void> update(WorkRecord r) async {
    if (r.id == null) return;
    await (await db).update('records', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> delete(int id) async =>
      (await db).delete('records', where: 'id = ?', whereArgs: [id]);

  Future<void> updateAll(List<WorkRecord> records) async {
    if (records.isEmpty) return;
    final batch = (await db).batch();
    for (final r in records) {
      if (r.id == null) continue;
      batch.update('records', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertAll(List<WorkRecord> records) async {
    if (records.isEmpty) return;
    final batch = (await db).batch();
    for (final r in records) {
      batch.insert('records', r.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Xóa hết rồi ghi lại trong MỘT giao dịch: lỗi giữa chừng thì dữ liệu cũ vẫn còn.
  Future<void> replaceWith(List<WorkRecord> records) async {
    await (await db).transaction((txn) async {
      await txn.delete('records');
      final batch = txn.batch();
      for (final r in records) {
        batch.insert('records', r.toMap());
      }
      await batch.commit(noResult: true);
    });
  }
}
