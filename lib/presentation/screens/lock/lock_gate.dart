import 'package:flutter/material.dart' hide Text;

import 'package:theo_doi_luong/logic/controllers/app_lock.dart';
import 'package:theo_doi_luong/presentation/screens/lock/lock_screen.dart';
import 'package:theo_doi_luong/presentation/screens/lock/setup_lock_screen.dart';

/// Phủ màn hình khóa lên trên toàn bộ ứng dụng (kể cả hộp thoại đang mở).
class LockGate extends StatelessWidget {
  const LockGate({super.key, required this.lock, required this.child});
  final AppLock lock;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: lock,
        builder: (context, _) {
          final covered = !lock.ready || lock.needsSetup || lock.locked;
          return Stack(
            fit: StackFit.expand,
            children: [
              Offstage(offstage: covered, child: child),
              if (covered) Positioned.fill(child: Overlay.wrap(child: _LockSwitcher(lock: lock))),
            ],
          );
        },
      );
}

class _LockSwitcher extends StatelessWidget {
  const _LockSwitcher({required this.lock});
  final AppLock lock;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: lock,
        builder: (context, _) {
          if (!lock.ready) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (lock.needsSetup) return SetupLockScreen(lock: lock);
          return LockScreen(lock: lock);
        },
      );
}
