DateTime floorMinute(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d, int weekStart) {
  final day = dateOnly(d);
  return DateTime(day.year, day.month, day.day - (day.weekday - weekStart + 7) % 7);
}
