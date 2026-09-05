import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DahrLogo extends StatelessWidget {
  const DahrLogo({super.key, this.height = 32});

  final double height;

  /// Intrinsic size of [assets/brand/dahr_logo.png].
  static const Size _assetSize = Size(512, 584);

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2;
    final cacheHeight = (height * dpr * 2).round().clamp(64, 1024);
    final cacheWidth =
        (cacheHeight * _assetSize.width / _assetSize.height).round();
    return Image.asset(
      'assets/brand/dahr_logo.png',
      height: height,
      width: height * _assetSize.width / _assetSize.height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }
}

class DahrHeader extends StatelessWidget {
  const DahrHeader({
    super.key,
    required this.cityLabel,
    this.onCityTap,
    this.onNotifications,
  });

  final String cityLabel;
  final VoidCallback? onCityTap;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            onTap: onCityTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.glacier,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cityLabel,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: Center(child: DahrLogo(height: 44))),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
            color: AppColors.ink,
          ),
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
