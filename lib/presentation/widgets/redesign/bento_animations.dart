/// bento_animations.dart
///
/// Shared Micro-Animation Library — Bento Grid Redesign
/// ─────────────────────────────────────────────────────────────────────────
/// All animation components are isolated StatefulWidgets that own their own
/// AnimationControllers. They NEVER call a parent setState(), preventing any
/// widget tree rebuild cascade during continuous animations.
///
/// Components:
///   - BentoEntrance:         Staggered fade-and-slide-up entrance for cards.
///   - PulseGlowBorder:       Ambient pulsing Solar-Yellow border glow wrapper.
///   - AnimatedStatusColor:   Smooth AnimatedContainer cross-fade for badge bg.
library bento_animations;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. BENTO ENTRANCE — Staggered fade + slide-up
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a staggered fade-and-slide-up entrance animation.
///
/// [delay] offsets when this card starts animating within the stagger sequence.
/// [duration] controls the total animation time for this individual card.
///
/// Uses [RepaintBoundary] so the animating subtree is rasterised independently
/// and does not trigger repaints in sibling cards.
class BentoEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideBegin;

  const BentoEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.slideBegin = const Offset(0, 0.06),
  });

  @override
  State<BentoEntrance> createState() => _BentoEntranceState();
}

class _BentoEntranceState extends State<BentoEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    // Delayed start for stagger effect
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: widget.slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. PULSE GLOW BORDER — Ambient ambient Solar-Yellow hero signal
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a container whose border opacity pulses continuously,
/// creating an ambient "breathing" glow effect that visually signals the
/// Canadian Survival Guide is the interactive hero element.
///
/// Isolated AnimationController: zero parent setState() calls.
/// RepaintBoundary: rasterises this subtree independently.
class PulseGlowBorder extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxGlowAlpha;   // 0.0–1.0
  final double minGlowAlpha;   // 0.0–1.0
  final Duration pulseDuration;

  const PulseGlowBorder({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFD4FF00), // Solar-Yellow
    this.maxGlowAlpha = 0.85,
    this.minGlowAlpha = 0.20,
    this.pulseDuration = const Duration(milliseconds: 1800),
  });

  @override
  State<PulseGlowBorder> createState() => _PulseGlowBorderState();
}

class _PulseGlowBorderState extends State<PulseGlowBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _alpha;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    )..repeat(reverse: true);

    _alpha = Tween<double>(
      begin: widget.minGlowAlpha,
      end: widget.maxGlowAlpha,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _alpha,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              // Inner card shadow — always-on crisp Neo-Brutalist drop
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A0A0A),
                  offset: const Offset(4, 4),
                ),
                // Ambient pulsing Solar-Yellow glow
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: _alpha.value * 0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. ANIMATED STATUS COLOR — Smooth badge background cross-fade
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in an [AnimatedContainer] that smoothly cross-fades its
/// background [color] whenever the weather state changes (e.g., when the Dev
/// Simulator toggles a new simulation mode). Ensures non-tappable Bento
/// badges still feel alive and reactive.
class AnimatedStatusColor extends StatelessWidget {
  final Color color;
  final Widget child;
  final Duration duration;

  const AnimatedStatusColor({
    super.key,
    required this.color,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedContainer handles the implicit animation natively —
    // no AnimationController needed here.
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      color: color,
      child: child,
    );
  }
}
class TeletypeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const TeletypeText(this.text, {super.key, this.style});

  @override
  State<TeletypeText> createState() => _TeletypeTextState();
}

class _TeletypeTextState extends State<TeletypeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _charCount = StepTween(begin: 0, end: widget.text.length).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _hasAnimated = true;
          });
        }
      }
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(TeletypeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.stop();
      _hasAnimated = false;
      _charCount = StepTween(begin: 0, end: widget.text.length).animate(_controller);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAnimated) {
      return Text(widget.text, style: widget.style);
    }

    return Stack(
      children: [
        // Base Layer (The Anchor): Forces max bounds instantly
        Opacity(
          opacity: 0.0,
          child: Text(widget.text, style: widget.style),
        ),
        // Top Layer (The Animation): Types over the pre-sized bounds
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _charCount,
            builder: (context, child) {
              final safeEnd = _charCount.value.clamp(0, widget.text.length);
              String visibleString = widget.text.substring(0, safeEnd);
              return Text(visibleString, style: widget.style);
            },
          ),
        ),
      ],
    );
  }
}

