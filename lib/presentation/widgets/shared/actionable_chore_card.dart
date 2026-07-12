/// actionable_chore_card.dart
///
/// Editorial Full-Bleed Chore Block with OpenContainer Morph Transition
/// ─────────────────────────────────────────────────────────────────────────
/// Renders as a full-width, edge-to-edge color block.
/// On tap, OpenContainer morphs the block to flood the full screen,
/// transitioning into ChoreDetailPage with staggered content animations.
library actionable_chore_card;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/canadian_advice_engine.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/chore_detail_page.dart';

/// Returns the editorial block color pair [blockColor, textColor] for a given
/// [AdviceResult]. Summer warnings use Electric Yellow. Winter/action cards
/// use Electric Cyan. Normal cards use near-black surface.
({Color blockColor, Color textColor}) _resolveColors(AdviceResult advice) {
  return switch (advice.urgencyLevel) {
    UrgencyLevel.actionRequired => switch (advice.category) {
        AdviceCategory.deIcing || AdviceCategory.snowShoveling => (
            blockColor: const Color(0xFF00F0FF), // Electric Cyan
            textColor: const Color(0xFF0A0A0A),
          ),
        AdviceCategory.windowManagement => (
            blockColor: const Color(0xFF0A0A0A), // Night — dark with cyan text
            textColor: const Color(0xFF00F0FF),
          ),
        AdviceCategory.summerSafety => (
            blockColor: const Color(0xFFFF3B30), // Electric Red for Heat/UV
            textColor: AppColors.pureWhite,
          ),
        _ => (
            blockColor: const Color(0xFF111111),
            textColor: AppColors.pureWhite,
          ),
      },
    UrgencyLevel.warning => (
        blockColor: const Color(0xFFE6FF00), // Electric Yellow
        textColor: const Color(0xFF0A0A0A),
      ),
    UrgencyLevel.normal => (
        blockColor: const Color(0xFF1A1A1A),
        textColor: AppColors.pureWhite,
      ),
  };
}

class ActionableChoreCard extends StatelessWidget {
  final AdviceResult advice;

  const ActionableChoreCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    final (:blockColor, :textColor) = _resolveColors(advice);

    return OpenContainer<void>(
      // The container morph matches background for seamless expansion
      closedColor: blockColor,
      openColor: blockColor,
      middleColor: blockColor,
      closedElevation: 0,
      openElevation: 0,
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fade,

      // ── CLOSED STATE: Editorial Full-Bleed Block ─────────────────────
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: openContainer,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            color: blockColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + icon row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      advice.category.displayName,
                      style: AppTypography.monoCaption.copyWith(
                        color: textColor.withOpacity(0.55),
                        letterSpacing: 3,
                        fontSize: 11,
                      ),
                    ),
                    Icon(advice.icon, color: textColor.withOpacity(0.55), size: 20),
                  ],
                ),

                const SizedBox(height: 20),

                // Brutalist title — large kinetic type
                Text(
                  advice.title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 0.95,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Instruction preview — first sentence only on card
                Text(
                  advice.instruction.split('!').first +
                      (advice.instruction.contains('!') ? '!' : '.'),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: textColor.withOpacity(0.75),
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 20),

                // Tap prompt
                Row(
                  children: [
                    Text(
                      'EXPAND →',
                      style: AppTypography.monoCaption.copyWith(
                        color: textColor.withOpacity(0.4),
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },

      // ── OPEN STATE: Full-Screen Morph Detail Page ─────────────────────
      openBuilder: (context, _) => ChoreDetailPage(
        advice: advice,
        blockColor: blockColor,
        textColor: textColor,
      ),
    );
  }
}
