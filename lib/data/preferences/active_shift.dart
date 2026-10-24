import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

import 'package:theo_doi_luong/core/constants/app_constants.dart';

class ActiveShift {
  const ActiveShift({required this.start, required this.dayType, required this.rate});
  final DateTime start;
  final String dayType;
  final double rate;

  static Future<ActiveShift?> load(double fallbackRate) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('activeCheckInMillis');
    if (ms == null) return null;
    final type = prefs.getString('activeDayType') ?? 'Thường';
    return ActiveShift(
      start: DateTime.fromMillisecondsSinceEpoch(ms),
      dayType: dayTypes.contains(type) ? type : 'Thường',
      rate: prefs.getDouble('activeRate') ?? fallbackRate,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeCheckInMillis', start.millisecondsSinceEpoch);
    await prefs.setString('activeDayType', dayType);
    await prefs.setDouble('activeRate', rate);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeCheckInMillis');
    await prefs.remove('activeDayType');
    await prefs.remove('activeRate');
  }
}
