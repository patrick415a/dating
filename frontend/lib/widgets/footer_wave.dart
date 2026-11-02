import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared, subtle rose wave for the splash and profile review screens.
class FooterWave extends StatefulWidget {
  const FooterWave({super.key});

  @override
  State<FooterWave> createState() => _FooterWaveState();
}

class _FooterWaveState extends State<FooterWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: 90,
          child: AnimatedBuilder(
            animation: _controller,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            builder: (context, child) => ClipPath(
              clipper: _WaveClipper(_controller.value),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;

  _WaveClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, 25);
    for (double x = 0; x <= size.width; x++) {
      final y = math.sin((x / size.width * 2 * math.pi) +
          (progress * 2 * math.pi)) * 10 + 25;
      path.lineTo(x, y);
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) =>
      oldClipper.progress != progress;
}
