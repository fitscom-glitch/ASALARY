import 'package:flutter/material.dart' hide Text;

Color typeColor(String t) => switch (t) {
      'Lễ' => Colors.deepOrange,
      'OT' => Colors.indigo,
      _ => Colors.teal,
    };

IconData typeIcon(String t) => switch (t) {
      'Lễ' => Icons.celebration,
      'OT' => Icons.more_time,
      _ => Icons.work_outline,
    };
