class RecordDraft {
  const RecordDraft({
    this.id,
    required this.start,
    required this.end,
    required this.rate,
  });
  final int? id;
  final DateTime start;
  final DateTime end;
  final double rate;
}
