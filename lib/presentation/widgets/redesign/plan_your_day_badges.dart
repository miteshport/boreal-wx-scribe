import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';

class PlanYourDayBadges extends StatelessWidget {
  final List<ActivityScore> scores;

  const PlanYourDayBadges({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate grid columns based on available width
          // Minimum width for a badge is roughly 150
          int crossAxisCount = (constraints.maxWidth / 150).floor().clamp(2, 4);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 2.5, // Fixed aspect ratio per AGENTS.md
            ),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              return _BentoBadge(score: scores[index]);
            },
          );
        },
      ),
    );
  }
}

class _BentoBadge extends StatelessWidget {
  final ActivityScore score;

  const _BentoBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final String statusText = _statusLabel(score.status);
    final Color statusColor = _statusColor(score.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Card Background
        border: Border.all(color: const Color(0xFF0A0A0A), width: 2), // 2px solid black border
        borderRadius: BorderRadius.zero, // Sharp 90° corners
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF0A0A0A), // Hard drop shadow
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(score.icon, color: AppColors.pureWhite, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  score.title.toUpperCase(),
                  style: AppTypography.monoCaption.copyWith(
                    color: AppColors.concreteGrey,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            statusText,
            style: AppTypography.monoCaption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _statusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.good:
        return 'PRIME';
      case ActivityStatus.fair:
        return 'MARGINAL';
      case ActivityStatus.poor:
      case ActivityStatus.hazardous:
        return 'HAZARDOUS';
    }
  }

  Color _statusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.good:
        return const Color(0xFF00FF87); // Electric Green
      case ActivityStatus.fair:
        return const Color(0xFFFF9F0A); // Amber
      case ActivityStatus.poor:
      case ActivityStatus.hazardous:
        return const Color(0xFFFF3B30); // Alert Red
    }
  }
}
