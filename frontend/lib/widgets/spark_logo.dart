import 'package:flutter/material.dart';
import 'brand_logo.dart';

class SparkLogo extends StatelessWidget {
  final Color pinkAccent;
  final Color purpleAccent;

  const SparkLogo({
    super.key,
    required this.pinkAccent,
    required this.purpleAccent,
  });

  @override
  Widget build(BuildContext context) {
    return const BrandLogo(fontSize: 32, markSize: 38);
  }
}
