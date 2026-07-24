// lib/utils/celebration.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

/// Perayaan singkat saat sebuah tugas ditandai selesai: getar halus +
/// overlay animasi (lingkaran centang) yang muncul di tengah lalu
/// memudar sendiri. Sengaja tanpa dependency tambahan agar tetap ringan.
void celebrateTaskCompletion(BuildContext context) {
  // Getar halus sebagai umpan balik taktil.
  HapticFeedback.mediumImpact();

  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => const _CelebrationOverlay(),
  );
  overlay.insert(entry);

  // Bersihkan setelah animasi selesai.
  Future.delayed(const Duration(milliseconds: 1300), () {
    entry.remove();
  });
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Muncul (pop) di 0–0.35, tahan, lalu memudar di 0.7–1.0.
            final appear = Curves.elasticOut.transform(
                (_c.value / 0.35).clamp(0.0, 1.0));
            final fade = _c.value < 0.7
                ? 1.0
                : (1 - (_c.value - 0.7) / 0.3).clamp(0.0, 1.0);
            return Opacity(
              opacity: fade,
              child: Transform.scale(
                scale: 0.6 + 0.4 * appear,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.success.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 12),
                    const Text('Selesai!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
