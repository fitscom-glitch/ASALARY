import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/paid_leave.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/pill.dart';

/// Một ngày nghỉ có lương (Sick leave) trong lịch sử, màu xanh nhạt như cột ở biểu đồ tuần.
class LeaveTile extends StatelessWidget {
  const LeaveTile({
    super.key,
    required this.day,
    required this.leave,
    required this.onTap,
    required this.onDelete,
  });
  final DateTime day;
  final PaidLeave leave;
  final VoidCallback onTap, onDelete;

  static const _fg = Color(0xFF0369A1);
  static const _bg = Color(0xFFBAE6FD);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: _bg.withValues(alpha: 0.35),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 56,
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayShort[day.weekday - 1],
                          style: const TextStyle(fontSize: 11, color: _fg, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${day.day}',
                          style: const TextStyle(fontSize: 20, color: _fg, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nghỉ có lương', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            const Pill('Sick leave', color: _fg),
                            Pill('${money(leave.rate)}/giờ', color: Colors.blueGrey),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(leave.pay), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(fmtHours(leave.hours), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.muted),
                    onSelected: (v) => v == 'edit' ? onTap() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
