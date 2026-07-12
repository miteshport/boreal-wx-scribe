/// glass_card.dart
///
/// Stage 6 Glass Morphism Card — Reusable Foundation Widget
/// ─────────────────────────────────────────────────────────────────────────
/// This widget is the visual foundation of the entire Stage 6 redesign.
/// Every card on the Today tab wraps its content in a GlassCard instead of
/// an opaque Container. The BackdropFilter blur allows the living
/// NeoBrutalistWeatherCanvas particle system to bleed through all cards,
/// creating a unified atmospheric aesthetic.
///
/// ⚠️ Performance Rule: Do NOT nest GlassCard inside another GlassCard.
/// Each BackdropFilter adds a GPU rasterization pass. Nesting blurs will
/// cause frame-rate degradation on mid-range Android devices. One layer only.
///
/// Usage:
///   GlassCard(
///     child: MyContent(),
///   )
///
/// To use the cyan-tinted variant (Survival Guide card):
///   GlassCard(
///     tint: AppColors.glassCyan,
///     child: MyContent(),
///   )

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';

class GlassCard extends StatelessWidget {
  /// The content to render inside the glass surface.
  final Widget child;

  /// Optional override for the glass tint color.
  /// Defaults to [AppColors.glassWhite] (10% white).
  /// Use [AppColors.glassCyan] for the Survival Guide card.
  final Color? tint;

  /// Corner radius. Defaults to 16.
  final double borderRadius;

  /// Blur sigma for the BackdropFilter. Defaults to 10.
  /// Keep between 8–14 for optimal performance/aesthetics balance.
  final double blur;

  /// Whether to draw a glass border outline. Defaults to true.
  final bool showBorder;

  /// Margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Padding inside the card.
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.tint,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.showBorder = true,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTint = tint ?? AppColors.glassWhite;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            // Primary glass surface fill
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Top-left: slightly lighter (glass highlight effect)
                Color.alphaBlend(AppColors.glassHighlight, effectiveTint),
                effectiveTint,
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: AppColors.glassBorder,
                    width: 1.0,
                  )
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
