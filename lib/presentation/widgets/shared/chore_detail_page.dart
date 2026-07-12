/// chore_detail_page.dart
///
/// Full-Screen Morph Detail — Editorial Expansion Layout (v2)
/// ─────────────────────────────────────────────────────────────────────────
/// v2 fix: Content column wrapped in SingleChildScrollView with
/// BouncingScrollPhysics to eliminate the 65px bottom overflow error
/// on smaller screens (< 700px logical height).
library chore_detail_page;

import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/canadian_advice_engine.dart';

class ChoreDetailPage extends StatefulWidget {
  final AdviceResult advice;
  final Color blockColor;
  final Color textColor;

  const ChoreDetailPage({
    super.key,
    required this.advice,
    required this.blockColor,
    required this.textColor,
  });

  @override
  State<ChoreDetailPage> createState() => _ChoreDetailPageState();
}

class _ChoreDetailPageState extends State<ChoreDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeCategory;
  late Animation<Offset> _slideTitle;
  late Animation<double> _fadeInstruction;
  late Animation<double> _fadeExplanation;
  late Animation<double> _fadeClose;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeCategory = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _slideTitle = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
    ));
    _fadeInstruction = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    );
    _fadeExplanation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
    );
    _fadeClose = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.blockColor,
      body: Stack(
        children: [
          // ── SCROLLABLE CONTENT (overflow fix: SingleChildScrollView) ──
          SafeArea(
            child: SingleChildScrollView(
              // BouncingScrollPhysics gives a native, premium feel
              // and eliminates the RenderFlex 65px overflow on small screens.
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    FadeTransition(
                      opacity: _fadeCategory,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: widget.textColor.withOpacity(0.4),
                              width: 1),
                        ),
                        child: Text(
                          widget.advice.category.displayName,
                          style: AppTypography.monoCaption.copyWith(
                            color: widget.textColor.withOpacity(0.7),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Kinetic title
                    SlideTransition(
                      position: _slideTitle,
                      child: FadeTransition(
                        opacity: _fadeInstruction,
                        child: Text(
                          widget.advice.title,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor,
                            height: 0.95,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    FadeTransition(
                      opacity: _fadeInstruction,
                      child: Container(
                          height: 2,
                          width: 60,
                          color: widget.textColor.withOpacity(0.5)),
                    ),

                    const SizedBox(height: 28),

                    // Full instruction text — no truncation in detail view
                    FadeTransition(
                      opacity: _fadeInstruction,
                      child: Text(
                        widget.advice.instruction,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: widget.textColor,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // "Why this works" header
                    FadeTransition(
                      opacity: _fadeExplanation,
                      child: Text(
                        '— WHY THIS WORKS',
                        style: AppTypography.monoCaption.copyWith(
                          color: widget.textColor.withOpacity(0.5),
                          letterSpacing: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Scientific explanation — can be long, scrollable
                    FadeTransition(
                      opacity: _fadeExplanation,
                      child: Text(
                        widget.advice.explanation,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: widget.textColor.withOpacity(0.75),
                          height: 1.7,
                        ),
                      ),
                    ),

                    // Extra breathing room at the bottom
                    const SizedBox(height: 40),

                    // Swipe hint — now inside the scroll so it's reachable
                    FadeTransition(
                      opacity: _fadeClose,
                      child: Center(
                        child: Text(
                          '↓  SWIPE DOWN TO CLOSE',
                          style: AppTypography.monoCaption.copyWith(
                            color: widget.textColor.withOpacity(0.30),
                            letterSpacing: 3,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── CLOSE BUTTON (always visible, above scroll) ───────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: FadeTransition(
                opacity: _fadeClose,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: widget.textColor.withOpacity(0.4), width: 1),
                      color: widget.blockColor.withOpacity(0.8),
                    ),
                    child: Text(
                      '[ × ]',
                      style: AppTypography.monoCaption.copyWith(
                        color: widget.textColor,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
