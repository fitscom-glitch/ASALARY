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
  });

  /// Tổng tiền, tổng giờ và giờ theo từng loại (thường, OT x1.5, x2).
  final double earned, total, regular, ot, dbl;

  /// Tiền theo từng loại giờ.
  final double regularPay, otPay, dblPay;
  final int shifts;
}
