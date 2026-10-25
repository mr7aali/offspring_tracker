import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';

/// Shows an installed app's real icon, falling back to a category symbol
/// when the icon is not available (other phones, sample data, non-Android).
class AppIconImage extends StatelessWidget {
  const AppIconImage({
    super.key,
    required this.packageName,
    required this.fallbackIcon,
    required this.color,
    this.size = 46,
    this.isBlocked = false,
  });

  final String packageName;
  final IconData fallbackIcon;
  final Color color;
  final double size;

  /// Greys the icon and adds a lock badge.
  final bool isBlocked;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _AppIconCache.load(packageName),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final radius = BorderRadius.circular(size * 0.26);

        final Widget icon = bytes == null
            ? Container(
                key: const ValueKey('fallback'),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: radius,
                ),
                child: Icon(
                  isBlocked ? Icons.lock : fallbackIcon,
                  color: color,
                  size: size * 0.52,
                ),
              )
            : ClipRRect(
                key: const ValueKey('icon'),
                borderRadius: radius,
                child: ColorFiltered(
                  colorFilter: isBlocked ? _greyscale : _identity,
                  child: Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              );

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: icon,
              ),
              if (isBlocked && bytes != null)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      Icons.lock,
                      size: size * 0.24,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

const _identity = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
]);

const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.6, 0, //
]);

/// Loads each app's icon once per app session.
class _AppIconCache {
  static final _icons = <String, Future<Uint8List?>>{};

  static Future<Uint8List?> load(String packageName) {
    return _icons.putIfAbsent(
      packageName,
      () => appDependencies.refreshInstalledApps.source.loadIcon(packageName),
    );
  }
}
