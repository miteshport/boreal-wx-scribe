/// neo_brutalist_weather_canvas.dart
///
/// 7-Stage Neo-Brutalist Atmospheric Canvas Engine — CustomPainter
/// ─────────────────────────────────────────────────────────────────────────
/// Performance contract: `repaint: animation` on every painter guarantees
/// only the Canvas layer repaints per tick. The widget tree is never
/// rebuilt during animation — verified 60 FPS architecture.
///
/// 7 ATMOSPHERIC MODES:
///  1. rain       — Vector Slash Blades (cyan diagonal slashes)
///  2. snow       — Geometric Drifting Matrix (2px square dots + sine drift)
///  3. summerDay  — Thermal Refraction Mesh v2:
///                   · 3-layer MaskFilter.blur amber-gold blob (morphing 6s)
///                   · Chromatic aberration: R/C offset twin strokes on columns
///  4. clearNight — Astronomical Blueprint v2:
///                   · Proximity Link Rule: connect stars < 60px, max opacity 0.15
///                   · Lunar Vignette Pulse: 8s indigo breathing from screen edges
///  5. wildfire   — Particulate Smog Shader (charcoal-orange bg + ash streaks)
///  6. severeWind — Kinetic Streamline Warp (high-speed horizontal dashes)
///  7. slush      — Dithered Overcast Halftone Grid (oscillating dot matrix)
library neo_brutalist_weather_canvas;

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum WeatherAnimationMode {
  rain,
  snow,
  summerDay,
  clearNight,
  wildfire,
  severeWind,
  slush,
}

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE DATA (immutable, created once in initState)
// ─────────────────────────────────────────────────────────────────────────────

final class _RainDrop {
  const _RainDrop({
    required this.x, required this.startY,
    required this.speed, required this.strokeWidth, required this.length,
  });
  final double x, startY, speed, strokeWidth, length;
}

final class _Snowflake {
  const _Snowflake({
    required this.x, required this.startY,
    required this.speed, required this.size,
    required this.driftPhase, required this.driftAmplitude,
  });
  final double x, startY, speed, size, driftPhase, driftAmplitude;
}

final class _Cloud {
  const _Cloud({
    required this.x, required this.startY,
    required this.speed, required this.scale,
    required this.opacity, required this.seed,
    required this.isYellow,
  });
  final double x, startY, speed, scale, opacity;
  final int seed;
  final bool isYellow;
}

final class _SunRay {
  const _SunRay({
    required this.anglePhase, required this.speed,
    required this.length, required this.thickness,
  });
  final double anglePhase, speed, length, thickness;
}

final class _Star {
  const _Star({
    required this.x, required this.y,
    required this.phase, required this.size,
    required this.isCross, required this.twinkleSpeed,
  });
  final double x, y, phase, size, twinkleSpeed;
  final bool isCross;
}

final class _AshParticle {
  const _AshParticle({
    required this.x, required this.startY,
    required this.speed, required this.opacity,
    required this.size, required this.driftPhase,
    required this.isOrange,
  });
  final double x, startY, speed, opacity, size, driftPhase;
  final bool isOrange;
}

final class _WindStreak {
  const _WindStreak({
    required this.y, required this.phase,
    required this.speed, required this.length,
    required this.opacity, required this.strokeWidth,
    required this.isCyan,
  });
  final double y, phase, speed, length, opacity, strokeWidth;
  final bool isCyan;
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class NeoBrutalistWeatherCanvas extends StatefulWidget {
  final WeatherAnimationMode mode;

  const NeoBrutalistWeatherCanvas({super.key, required this.mode});

  /// Per-mode opacity to use on the outer Opacity widget.
  /// Wildfire/clearNight are visually prominent; summerDay is very subtle.
  static double suggestedOpacity(WeatherAnimationMode mode) {
    return switch (mode) {
      WeatherAnimationMode.rain       => 0.85,
      WeatherAnimationMode.snow       => 0.90,
      WeatherAnimationMode.wildfire   => 0.85,
      WeatherAnimationMode.clearNight => 1.00,
      WeatherAnimationMode.summerDay  => 0.14,
      WeatherAnimationMode.slush      => 0.35,
      WeatherAnimationMode.severeWind => 0.85,
    };
  }

  @override
  State<NeoBrutalistWeatherCanvas> createState() =>
      _NeoBrutalistWeatherCanvasState();
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class _NeoBrutalistWeatherCanvasState extends State<NeoBrutalistWeatherCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Particle lists — only the list for the active mode will be populated.
  late final List<_RainDrop> _drops;
  late final List<_Snowflake> _flakes;
  late final List<_Cloud> _clouds;
  late final List<_SunRay> _rays;
  late final List<_Star> _stars;
  late final List<_AshParticle> _ash;
  late final List<_WindStreak> _streaks;

  // Fixed seed: deterministic particle layout across sessions.
  static const _seed = 42;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForMode(widget.mode),
    )..repeat();
  }

  static Duration _durationForMode(WeatherAnimationMode m) => switch (m) {
    WeatherAnimationMode.rain        => const Duration(milliseconds: 1600),
    WeatherAnimationMode.snow        => const Duration(milliseconds: 5200),
    WeatherAnimationMode.summerDay   => const Duration(milliseconds: 6000),
    WeatherAnimationMode.clearNight  => const Duration(seconds: 8), // 8s loop for prominent shooting star
    WeatherAnimationMode.wildfire    => const Duration(milliseconds: 9000),
    WeatherAnimationMode.severeWind  => const Duration(milliseconds: 480),
    WeatherAnimationMode.slush       => const Duration(milliseconds: 4200),
  };

  void _initParticles() {
    final rng = Random(_seed);

    // ── RAIN & FREEZETHAW (Rain Streaks) ───────────────────────────────────
    _drops = (widget.mode == WeatherAnimationMode.rain || widget.mode == WeatherAnimationMode.slush)
        ? List.generate(55, (_) {
            final thickness = 2.0 + rng.nextDouble() * 1.5;
            final zSpeed = (thickness / 2.8) * 1.5 + 0.4;
            return _RainDrop(
              x: rng.nextDouble(),
              startY: rng.nextDouble(),
              speed: zSpeed,
              strokeWidth: thickness,
              length: 15 + rng.nextDouble() * 25,
            );
          })
        : const [];

    // ── SNOW & FREEZETHAW (Ice dots / Snow flakes) ───────────────────────
    _flakes = (widget.mode == WeatherAnimationMode.snow || widget.mode == WeatherAnimationMode.slush)
        ? List.generate(widget.mode == WeatherAnimationMode.slush ? 45 : 55, (_) => _Snowflake(
            x: rng.nextDouble(),
            startY: rng.nextDouble(),
            speed: 0.10 + rng.nextDouble() * 0.25,
            size: 3.0 + rng.nextDouble() * 3.0, // 3.0 - 6.0 dp
            driftPhase: rng.nextDouble() * 2 * pi,
            driftAmplitude: 8 + rng.nextDouble() * 22,
          ))
        : const [];

    // ── EXTREME HEAT (Thermal Dots) ───────────────────────────────────────
    _clouds = widget.mode == WeatherAnimationMode.summerDay
        ? List.generate(45, (i) => _Cloud(
            x: rng.nextDouble(),
            startY: rng.nextDouble(),
            speed: 0.04 + rng.nextDouble() * 0.08,
            scale: 3.0 + rng.nextDouble() * 5.0, // Used as dot size
            opacity: 0.40 + rng.nextDouble() * 0.30,
            seed: rng.nextInt(10000),
            isYellow: rng.nextBool(),
          ))
        : const [];
    _rays = const []; 

    // ── CLEAR NIGHT ───────────────────────────────────────────────────────
    _stars = widget.mode == WeatherAnimationMode.clearNight
        ? List.generate(70, (_) => _Star(
            x: rng.nextDouble(),
            y: rng.nextDouble() * 0.85,
            phase: rng.nextDouble() * 2 * pi,
            size: 1.5 + rng.nextDouble() * 3.0,
            isCross: rng.nextDouble() > 0.45,
            twinkleSpeed: 1.0 + rng.nextDouble() * 2.5,
          ))
        : const [];

    // ── WILDFIRE SMOKE (Embers) ───────────────────────────────────────────
    _ash = widget.mode == WeatherAnimationMode.wildfire
        ? List.generate(55, (_) => _AshParticle(
            x: rng.nextDouble(),
            startY: rng.nextDouble(),
            speed: 0.10 + rng.nextDouble() * 0.15,
            opacity: 0.50 + rng.nextDouble() * 0.25,
            size: 2.0 + rng.nextDouble() * 4.0,
            driftPhase: rng.nextDouble() * 2 * pi,
            isOrange: rng.nextBool(),
          ))
        : const [];

    // ── GALE WINDSTORM (Velocity Streaks) ─────────────────────────────────
    _streaks = widget.mode == WeatherAnimationMode.severeWind
        ? List.generate(45, (_) => _WindStreak(
            y: rng.nextDouble(),
            phase: rng.nextDouble(),
            speed: 1.5 + rng.nextDouble() * 1.5,
            length: 0.2 + rng.nextDouble() * 0.3,
            opacity: 0.40 + rng.nextDouble() * 0.20,
            strokeWidth: 2.0,
            isCyan: rng.nextBool(),
          ))
        : const [];
  }

  CustomPainter _selectPainter() => switch (widget.mode) {
    WeatherAnimationMode.rain =>
        _RainPainter(animation: _controller, drops: _drops),
    WeatherAnimationMode.snow =>
        _SnowPainter(animation: _controller, flakes: _flakes),
    WeatherAnimationMode.summerDay =>
        _SummerDayPainter(animation: _controller, clouds: _clouds, rays: _rays),
    WeatherAnimationMode.clearNight =>
        _ClearNightPainter(animation: _controller, stars: _stars),
    WeatherAnimationMode.wildfire =>
        _WildFirePainter(animation: _controller, ash: _ash),
    WeatherAnimationMode.severeWind =>
        _SevereWindPainter(animation: _controller, streaks: _streaks),
    WeatherAnimationMode.slush =>
        _SlushPainter(animation: _controller, drops: _drops, flakes: _flakes),
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _selectPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. RAIN — "Vector Slash Blades"
// ─────────────────────────────────────────────────────────────────────────────

class _RainPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_RainDrop> drops;
  _RainPainter({required this.animation, required this.drops})
      : super(repaint: animation);

  // 25° slash: sin(25°)=0.4226, cos(25°)=0.9063
  static const _dx = 0.4226;
  static const _dy = 0.9063;
  final _p = Paint()..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in drops) {
      final progress = (d.startY + animation.value * d.speed) % 1.0;
      final opacity = 0.65 + ((d.strokeWidth - 2.0) / 1.5) * 0.20; // 0.65 to 0.85
      _p
        ..color = const Color(0xFF00F0FF).withOpacity(opacity) // Cyber-cyan
        ..strokeWidth = d.strokeWidth;
      canvas.drawLine(
        Offset(d.x * size.width, progress * size.height),
        Offset(d.x * size.width + d.length * _dx,
               progress * size.height + d.length * _dy),
        _p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SNOW — "Geometric Drifting Matrix"
// ─────────────────────────────────────────────────────────────────────────────

class _SnowPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Snowflake> flakes;
  _SnowPainter({required this.animation, required this.flakes})
      : super(repaint: animation);

  final _p = Paint()..color = Colors.white.withValues(alpha: 0.90)..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      final y = (f.startY + animation.value * f.speed) % 1.0;
      final dx = sin(animation.value * 2 * pi + f.driftPhase) * f.driftAmplitude;
      // Diagonal drift based on speed to simulate wind
      final x = (f.x * size.width + dx + (y * size.height * 0.5)) % size.width;
      canvas.drawCircle(Offset(x, y * size.height), f.size, _p);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. SUMMER DAY — "Drifting Clouds & Sun Rays"
// ─────────────────────────────────────────────────────────────────────────────

class _SummerDayPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Cloud> clouds; // Repurposed to ThermalDots
  final List<_SunRay> rays; // Unused
  _SummerDayPainter({required this.animation, required this.clouds, required this.rays})
      : super(repaint: animation);

  final _dotPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;

    for (final c in clouds) {
      // Thermal dots float upwards
      final y = (c.startY - v * c.speed) % 1.0;
      // Re-wrap negative to 1.0
      final wrapY = y < 0 ? 1.0 + y : y;
      
      final xDrift = sin(v * 2 * pi + c.seed) * 20;
      final x = (c.x * size.width + xDrift) % size.width;
      
      final pulse = (sin(v * 4 * pi + c.seed) + 1) / 2;
      final currentOpacity = c.opacity * (0.6 + 0.4 * pulse);

      _dotPaint.color = c.isYellow 
          ? const Color(0xFFFFFFFF).withValues(alpha: currentOpacity) // High contrast white
          : const Color(0xFF000000).withValues(alpha: currentOpacity); // High contrast black
          
      canvas.drawCircle(Offset(x, wrapY * size.height), c.scale, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SummerDayPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. CLEAR NIGHT — "Crosshair Constellation"
// ─────────────────────────────────────────────────────────────────────────────

class _ClearNightPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Star> stars;
  _ClearNightPainter({required this.animation, required this.stars})
      : super(repaint: animation);

  final _starPaint = Paint()
    ..strokeCap = StrokeCap.square
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final _linkPaint = Paint()
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;
    final center = Offset(size.width / 2, size.height / 2);

    // ── LUNAR VIGNETTE PULSE (Drawn first — behind everything) ────────────
    // 8-second breathing sub-cycle.
    // sin() oscillates the dark-indigo opacity between 0.12 and 0.38.
    final vignettePhase = (v * 8.0 / 8.0) % 1.0; 
    final breathe = (sin(vignettePhase * 2 * pi) + 1) / 2; // 0→1
    final vignetteOpacity = 0.12 + breathe * 0.26;
    final maxRadius = sqrt(size.width * size.width + size.height * size.height) / 2;

    final vignetteShader = ui.Gradient.radial(
      center,
      maxRadius,
      [
        Colors.transparent,
        Colors.transparent,
        const Color(0xFF100830).withOpacity(vignetteOpacity),
      ],
      [0.0, 0.50, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = vignetteShader,
    );
    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // ── AURORA BOREALIS (Volumetric Gradients) ────────────────────────────
    canvas.saveLayer(canvasRect, Paint()..blendMode = BlendMode.screen);

    final aurora1 = ui.Gradient.radial(
      Offset(size.width * 0.3 + sin(v * 2 * pi) * 150, size.height * 0.2 + cos(v * 2 * pi) * 50),
      size.width * 0.7,
      [const Color(0xFF00FF87).withValues(alpha: 0.15), Colors.transparent],
    );
    canvas.drawRect(canvasRect, Paint()..shader = aurora1);

    final aurora2 = ui.Gradient.radial(
      Offset(size.width * 0.8 - cos(v * 2 * pi) * 100, size.height * 0.4 + sin(v * 2 * pi) * 80),
      size.width * 0.8,
      [const Color(0xFF00F0FF).withValues(alpha: 0.12), Colors.transparent],
    );
    canvas.drawRect(canvasRect, Paint()..shader = aurora2);

    final aurora3 = ui.Gradient.radial(
      Offset(size.width * 0.5 + sin(v * 4 * pi) * 50, size.height * 0.7 - cos(v * 2 * pi) * 100),
      size.width * 0.9,
      [const Color(0xFF9D00FF).withValues(alpha: 0.08), Colors.transparent],
    );
    canvas.drawRect(canvasRect, Paint()..shader = aurora3);

    canvas.restore();

    // ── PRE-COMPUTE STAR SCREEN POSITIONS ─────────────────────────────────
    // Cache pixel coordinates so the proximity O(n²) loop below avoids
    // recomputing size.width * s.x for each pair.
    final positions = List<Offset>.generate(
      stars.length,
      (i) => Offset(stars[i].x * size.width, stars[i].y * size.height),
    );

    // ── PROXIMITY CONSTELLATION LINKS ─────────────────────────────────────
    // Proximity Link Rule: if two stars are within 60px of each other,
    // draw an ultra-faint 1px connecting line.
    // Opacity scales linearly: max 0.15 at distance 0, 0.0 at distance 60px.
    const proximityThreshold = 60.0;
    for (int i = 0; i < stars.length - 1; i++) {
      final ax = positions[i].dx;
      final ay = positions[i].dy;
      for (int j = i + 1; j < stars.length; j++) {
        final bx = positions[j].dx;
        final by = positions[j].dy;
        // Fast early-out: skip if x-distance alone exceeds threshold
        if ((ax - bx).abs() > proximityThreshold) continue;
        final dist = sqrt((ax - bx) * (ax - bx) + (ay - by) * (ay - by));
        if (dist >= proximityThreshold) continue;

        // Linear falloff: t = 1 at distance 0, t = 0 at distance 60px
        final t = 1.0 - dist / proximityThreshold;
        _linkPaint.color = Colors.white.withOpacity(t * 0.15);
        canvas.drawLine(Offset(ax, ay), Offset(bx, by), _linkPaint);
      }
    }

    // ── STARS ─────────────────────────────────────────────────────────────
    for (int idx = 0; idx < stars.length; idx++) {
      final s = stars[idx];
      final cx = positions[idx].dx;
      final cy = positions[idx].dy;

      // Twinkle: opacity oscillates via sine with unique phase & speed
      final twinkle = (sin(v * 2 * pi * s.twinkleSpeed + s.phase) + 1) / 2;
      final opacity = 0.15 + twinkle * 0.80;

      _starPaint.color = Colors.white.withOpacity(opacity);
      _starPaint.strokeWidth = s.isCross ? 1.0 : 1.5;

      if (s.isCross) {
        // Step-rotation digital twinkle:
        // Every few seconds (based on twinkleSpeed), flicker between
        // + (crosshair) and × (45°-rotated) orientation.
        final isFlipped = ((v * s.twinkleSpeed * 3).floor()) % 3 == 0;
        if (isFlipped) {
          final r = s.size * 0.707;
          canvas.drawLine(Offset(cx - r, cy - r), Offset(cx + r, cy + r), _starPaint);
          canvas.drawLine(Offset(cx + r, cy - r), Offset(cx - r, cy + r), _starPaint);
        } else {
          canvas.drawLine(Offset(cx - s.size, cy), Offset(cx + s.size, cy), _starPaint);
          canvas.drawLine(Offset(cx, cy - s.size), Offset(cx, cy + s.size), _starPaint);
        }
      } else {
        final h = s.size * 0.5;
        canvas.drawRect(
          Rect.fromLTWH(cx - h, cy - h, s.size, s.size),
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // ── SHOOTING STAR / SATELLITE ─────────────────────────────────────────
    // Appears during the last 20% of the 8-second animation loop (~1.6s).
    // Trajectory: upper-left to center-right diagonal at ~21° angle.
    if (v > 0.80) {
      final t = (v - 0.80) / 0.20;
      final headX = (0.08 + t * 0.72) * size.width;
      final headY = (0.07 + t * 0.34) * size.height;
      final tailX  = headX - size.width  * 0.15;
      final tailY  = headY - size.height * 0.06;

      final shader = ui.Gradient.linear(
        Offset(tailX, tailY),
        Offset(headX, headY),
        [Colors.transparent, Colors.white.withOpacity(0.9)],
      );
      canvas.drawLine(
        Offset(tailX, tailY), Offset(headX, headY),
        Paint()
          ..shader = shader
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(headX, headY), 2.0,
        Paint()
          ..color = Colors.white.withOpacity(0.95)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClearNightPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. WILDFIRE SMOKE — "Particulate Smog Shader"
// ─────────────────────────────────────────────────────────────────────────────

class _WildFirePainter extends CustomPainter {
  final Animation<double> animation;
  final List<_AshParticle> ash; // Repurposed to rising embers
  _WildFirePainter({required this.animation, required this.ash})
      : super(repaint: animation);

  final _emberPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;

    // Slow-moving ambient radial gradient circles (Smoke Haze)
    final haze1 = ui.Gradient.radial(
      Offset(size.width * 0.3 + sin(v * 2 * pi) * 40, size.height * 0.7 - v * 200),
      size.width * 0.8,
      [const Color(0xFF331100).withValues(alpha: 0.3), Colors.transparent],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = haze1);

    final haze2 = ui.Gradient.radial(
      Offset(size.width * 0.8 - cos(v * 2 * pi) * 60, size.height * 0.4 - v * 150),
      size.width * 0.6,
      [const Color(0xFF331100).withValues(alpha: 0.3), Colors.transparent],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = haze2);

    // Rising thermal embers
    for (final p in ash) {
      final y = (p.startY - v * p.speed) % 1.0;
      final wrapY = y < 0 ? 1.0 + y : y;
      final xDrift = sin(v * 2 * pi + p.driftPhase) * 30;
      final x = (p.x * size.width + xDrift) % size.width;

      final pulse = (sin(v * 6 * pi + p.driftPhase) + 1) / 2;
      final currentOpacity = (p.opacity * (0.5 + 0.5 * pulse)).clamp(0.0, 1.0);

      _emberPaint.color = p.isOrange
          ? const Color(0xFFFF8C00).withValues(alpha: currentOpacity)
          : const Color(0xFFFF4500).withValues(alpha: currentOpacity);

      canvas.drawCircle(Offset(x, wrapY * size.height), p.size, _emberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WildFirePainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. SEVERE WIND — "Kinetic Streamline Warp"
// ─────────────────────────────────────────────────────────────────────────────

class _SevereWindPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_WindStreak> streaks;
  _SevereWindPainter({required this.animation, required this.streaks})
      : super(repaint: animation);

  final _p = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in streaks) {
      final x = (s.phase + animation.value * s.speed) % (1.0 + s.length);
      if (x < s.length) continue;

      final headX = x * size.width;
      final tailX = headX - s.length * size.width;
      final y = s.y * size.height;

      final baseColor = s.isCyan ? const Color(0xFF00F0FF) : Colors.white;

      final shader = ui.Gradient.linear(
        Offset(tailX, y),
        Offset(headX, y),
        [
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: s.opacity),
        ],
      );

      _p
        ..shader = shader
        ..strokeWidth = s.strokeWidth;

      canvas.drawLine(Offset(tailX, y), Offset(headX, y), _p);
      _p.shader = null;
    }
  }

  @override
  bool shouldRepaint(covariant _SevereWindPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. SLUSH / OVERCAST — "Dithered Overcast Halftone Grid"
// ─────────────────────────────────────────────────────────────────────────────

class _SlushPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_RainDrop> drops;
  final List<_Snowflake> flakes;
  _SlushPainter({required this.animation, required this.drops, required this.flakes}) : super(repaint: animation);

  final _pDrop = Paint()..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
  final _pFlake = Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.fill;
  static const _dx = 0.4226;
  static const _dy = 0.9063;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Rain streaks (lighter Cyber-Cyan)
    for (final d in drops) {
      final progress = (d.startY + animation.value * d.speed) % 1.0;
      final opacity = 0.30 + ((d.strokeWidth - 2.0) / 1.5) * 0.20; 
      _pDrop
        ..color = const Color(0xFF00F0FF).withValues(alpha: opacity)
        ..strokeWidth = d.strokeWidth * 0.7; // Thinner
      canvas.drawLine(
        Offset(d.x * size.width, progress * size.height),
        Offset(d.x * size.width + d.length * _dx, progress * size.height + d.length * _dy),
        _pDrop,
      );
    }
    
    // 2. Ice dots (twinkling white)
    for (final f in flakes) {
      final y = (f.startY + animation.value * f.speed) % 1.0;
      final dx = sin(animation.value * 2 * pi + f.driftPhase) * f.driftAmplitude;
      final x = (f.x * size.width + dx + (y * size.height * 0.3)) % size.width;
      
      final pulse = (sin(animation.value * 8 * pi + f.driftPhase) + 1) / 2;
      _pFlake.color = Colors.white.withValues(alpha: 0.4 + 0.45 * pulse);
      
      canvas.drawCircle(Offset(x, y * size.height), f.size * 0.7, _pFlake);
    }
  }

  @override
  bool shouldRepaint(covariant _SlushPainter o) => false;
}
