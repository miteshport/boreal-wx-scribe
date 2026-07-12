import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPRING PRESS WRAPPER (Tactile Bumps)
// ─────────────────────────────────────────────────────────────────────────────

class SpringPressWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SpringPressWrapper({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<SpringPressWrapper> createState() => _SpringPressWrapperState();
}

class _SpringPressWrapperState extends State<SpringPressWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(0.95,
        duration: const Duration(milliseconds: 50), curve: Curves.easeOut);
  }

  void _onTapUp(TapUpDetails details) {
    _bounceBack();
    if (widget.onTap != null) widget.onTap!();
  }

  void _onTapCancel() {
    _bounceBack();
  }

  void _bounceBack() {
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 400.0,
      damping: 15.0,
    );
    final simulation = SpringSimulation(spring, _controller.value, 1.0, 0);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            alignment: Alignment.center,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D BENTO FLIP CARD
// ─────────────────────────────────────────────────────────────────────────────

class BentoFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const BentoFlipCard({
    super.key,
    required this.front,
    required this.back,
  });

  @override
  State<BentoFlipCard> createState() => _BentoFlipCardState();
}

class _BentoFlipCardState extends State<BentoFlipCard>
    with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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
    return SpringPressWrapper(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isUnder = _animation.value > pi / 2;
          final angle = _animation.value;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}
