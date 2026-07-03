import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_sizes.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    required this.size,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  });

  final double size;
  final Color? backgroundColor;
  final double? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final logoPadding = padding ?? size * 0.12;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(logoPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.radius),
      ),
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
