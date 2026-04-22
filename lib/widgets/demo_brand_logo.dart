import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DemoBrandLogo extends StatelessWidget {
  const DemoBrandLogo({
    super.key,
    required this.brand,
    required this.demoModeEnabled,
    this.size = 22,
    this.fallbackIcon = LucideIcons.car,
    this.color,
  });

  final String brand;
  final bool demoModeEnabled;
  final double size;
  final IconData fallbackIcon;
  final Color? color;

  static const Map<String, String> _brandAssets = {
    'volkswagen': 'volkswagen-svgrepo-com.svg',
    'tesla': 'tesla-svgrepo-com.svg',
    'porsche': 'porsche-svgrepo-com.svg',
  };

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.onSurface;

    if (!demoModeEnabled) {
      return Icon(fallbackIcon, size: size, color: resolvedColor);
    }

    final asset = _brandAssets[brand.trim().toLowerCase()];
    if (asset == null) {
      return Icon(fallbackIcon, size: size, color: resolvedColor);
    }

    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: '$brand logo',
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
    );
  }
}
