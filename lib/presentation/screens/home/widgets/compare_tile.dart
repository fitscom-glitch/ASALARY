import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/core/constants/app_colors.dart';
import 'package:theo_doi_luong/presentation/widgets/app_text.dart';

class CompareTile extends StatelessWidget {
  const CompareTile({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.compare_arrows_rounded, color: Colors.indigo),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('So sánh thu nhập', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                        'So sánh tuần, tháng hoặc năm với một kỳ khác',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );
}
