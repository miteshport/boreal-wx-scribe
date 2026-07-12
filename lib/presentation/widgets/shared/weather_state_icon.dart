/// weather_state_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';

class WeatherStateIcon extends StatelessWidget {
  final String condition; // e.g., 'snow', 'sun', 'cloud', 'wind'
  final double size;
  final Color color;

  const WeatherStateIcon({
    super.key,
    required this.condition,
    this.size = 24.0,
    this.color = AppColors.pureWhite,
  });

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (condition.toLowerCase()) {
      case 'snow':
        assetPath = 'assets/icons/ic_snow.svg';
        break;
      case 'sun':
      case 'clear':
        assetPath = 'assets/icons/ic_sun.svg';
        break;
      case 'cloud':
      case 'clouds':
        assetPath = 'assets/icons/ic_cloud.svg';
        break;
      case 'wind':
        assetPath = 'assets/icons/ic_wind.svg';
        break;
      default:
        assetPath = 'assets/icons/ic_sun.svg'; // fallback
    }

    // Since we may not have the SVGs physically generated, we return an Icon fallback
    // if the SVG fails to load, or we can just use Material icons for the demo.
    return Icon(
      _getMaterialFallback(condition),
      size: size,
      color: color,
    );
  }

  IconData _getMaterialFallback(String cond) {
    switch (cond.toLowerCase()) {
      case 'snow': return Icons.ac_unit;
      case 'sun': return Icons.wb_sunny;
      case 'cloud': return Icons.cloud;
      case 'wind': return Icons.air;
      default: return Icons.wb_sunny;
    }
  }
}
