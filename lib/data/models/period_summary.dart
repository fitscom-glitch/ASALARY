class PeriodSummary {
  const PeriodSummary({
    this.earned = 0,
    this.total = 0,
    this.regular = 0,
    this.ot = 0,
    this.dbl = 0,
    this.regularPay = 0,
    this.otPay = 0,
    this.dblPay = 0,
    this.shifts = 0,
    this.leaveHours = 0,
    this.leavePay = 0,
    this.leaveDays = 0,
  });

  /// Tổng tiền (đã gồm tiền nghỉ có lương), tổng giờ làm và giờ theo từng loại (thường, OT x1.5, x2).
  final double earned, total, regular, ot, dbl;

  /// Tiền theo từng loại giờ.
  final double regularPay, otPay, dblPay;
  final int shifts;

  /// Ngày nghỉ có lương (Sick leave) trong kỳ: số giờ nghỉ, tiền và số ngày.
  /// Giờ nghỉ KHÔNG nằm trong [total]; tiền nghỉ nằm trong [earned].
  final double leaveHours, leavePay;
  final int leaveDays;
}
