import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Two overlapping circles: two individual lives finding a shared space.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 0.8,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: size * 0.64,
                height: size * 0.64,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.64,
                height: size * 0.64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double fontSize;
  final double markSize;

  const BrandLogo({super.key, this.fontSize = 20, this.markSize = 30});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            AppBrand.name,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.text,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }
}
