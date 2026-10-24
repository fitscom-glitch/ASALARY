import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/core/l10n/app_language.dart';
import 'package:theo_doi_luong/core/utils/formatters.dart';
import 'package:theo_doi_luong/data/models/work_record.dart';
import 'package:theo_doi_luong/presentation/theme/day_type_style.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';
import 'package:theo_doi_luong/presentation/widgets/pill.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });
  final WorkRecord record;
  final VoidCallback onTap, onDelete;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final color = typeColor(r.dayType);
    final range = '${timeFmt.format(r.start)} – ${timeFmt.format(r.end)}${r.overnight ? ' (+1)' : ''}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayShort[r.start.weekday - 1],
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${r.start.day}',
                        style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(range, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          if (r.dayType != 'Thường') ...[
                            const SizedBox(width: 6),
                            Pill(dayLabel(r.dayType), color: color),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (r.regularHours > 0) Pill('Thường ${fmtHours(r.regularHours)}', color: AppColors.tealMid),
                          if (r.otHours > 0) Pill('OT ${fmtHours(r.otHours)}', color: Colors.indigo),
                          if (r.doubleHours > 0) Pill('x2 ${fmtHours(r.doubleHours)}', color: Colors.deepOrange),
                          Pill('${money(r.hourlyRate)}/giờ', color: Colors.blueGrey),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(money(r.earned), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(fmtHours(r.totalHours), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
}
