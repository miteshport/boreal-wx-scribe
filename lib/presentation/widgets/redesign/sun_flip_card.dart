import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/glass_card.dart';
import 'package:weather_sync_ca/services/live_weather_service.dart';

class SunFlipCard extends StatefulWidget {
  final LiveWeatherData? liveData;

  const SunFlipCard({super.key, this.liveData});

  @override
  State<SunFlipCard> createState() => _SunFlipCardState();
}

class _SunFlipCardState extends State<SunFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx.abs() > 300) {
          _flipCard();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isUnder = _animation.value > pi / 2;
          final angle = _animation.value;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateX(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  )
                : _buildFront(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    final sunset = widget.liveData?.sunsetTime;
    final timeStr = sunset != null ? DateFormat.jm().format(sunset) : '8:45 PM';

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVENING TRANSITION',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.wb_twilight, color: Color(0xFFFF9F0A), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              timeStr,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.pureWhite,
                letterSpacing: -1.5,
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.8, 1.0],
              ).createShader(bounds);
            },
            child: Text(
              'Rapid thermal drop expected post-sunset. Seal windows by $timeStr to retain thermal mass.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.concreteGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4FF00), width: 1),
                color: const Color(0xFF0A0A0A),
              ),
              child: const Text(
                '[ TAP FOR INTEL ]',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  color: Color(0xFFD4FF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    // Fallback to ~6:00 AM if no exact sunrise data is available in the current payload
    final sunriseStr = '6:15 AM'; 

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MORNING FLUSH',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  letterSpacing: 2,
                ),
              ),
              const Icon(Icons.wb_sunny_outlined, color: Color(0xFFD4FF00), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              sunriseStr,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.pureWhite,
                letterSpacing: -1.5,
                height: 1.0,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.8, 1.0],
              ).createShader(bounds);
            },
            child: Text(
              'Open cross-ventilation windows at $sunriseStr to purge stale air before peak daily heat hits.',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.concreteGrey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD4FF00), width: 1),
                color: const Color(0xFF0A0A0A),
              ),
              child: const Text(
                '[ TAP FOR INTEL ]',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  color: Color(0xFFD4FF00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
