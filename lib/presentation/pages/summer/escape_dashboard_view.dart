/// escape_dashboard_view.dart
///
/// Weekend Escape — Synthetic Activity Index Dashboard (v2)
/// ─────────────────────────────────────────────────────────────────────────
/// v2 additions:
///   - `isRainingWeekend` param on EscapeParams.
///   - _CabinCrokinoleBlock: 10/10 rainy weekend pivot card.
///   - When rain detected, Cabin block appears as the hero top card.
library escape_dashboard_view;

import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/matrix/weather_state_matrix.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARAMS
// ─────────────────────────────────────────────────────────────────────────────

class EscapeParams {
  const EscapeParams({
    required this.tempC,
    required this.windKmh,
    required this.precipChance,
    required this.humidity,
    required this.recentRainMm,
    this.windGustKmh = 0.0,
    this.isFridayEvening = false,
    this.isSundayEvening = false,
    this.isRainingWeekend = false,
  });

  final double tempC;
  final double windKmh;

  /// Precipitation probability (0–100%)
  final double precipChance;

  /// Relative humidity (0–100%)
  final double humidity;

  /// Rain accumulation in recent 24h (mm)
  final double recentRainMm;

  /// Max wind gusts (km/h)
  final double windGustKmh;

  final bool isFridayEvening;
  final bool isSundayEvening;

  /// When true, escape content pivots to the Cabin & Crokinole indoor mode.
  final bool isRainingWeekend;
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPUTED SCORE MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _PatioScore {
  final int score;
  final String label;
  final String description;
  final Color blockColor;
  final Color textColor;

  const _PatioScore({
    required this.score,
    required this.label,
    required this.description,
    required this.blockColor,
    required this.textColor,
  });

  factory _PatioScore.compute(WeatherProfile profile) {
    final int score = profile.escapePatioIndex;

    if (score >= 9) {
      return _PatioScore(
        score: score,
        label: 'PATIO WEATHER',
        description: profile.escapePatioMessage,
        blockColor: const Color(0xFFE6FF00),
        textColor: const Color(0xFF0A0A0A),
      );
    } else if (score >= 7) {
      return _PatioScore(
        score: score,
        label: 'GREAT EVENING',
        description: profile.escapePatioMessage,
        blockColor: const Color(0xFF00FF87),
        textColor: const Color(0xFF0A0A0A),
      );
    } else if (score >= 5) {
      return _PatioScore(
        score: score,
        label: 'MARGINAL',
        description: profile.escapePatioMessage,
        blockColor: const Color(0xFF1A1A1A),
        textColor: AppColors.pureWhite,
      );
    } else {
      return _PatioScore(
        score: score,
        label: 'STAY IN',
        description: profile.escapePatioMessage,
        blockColor: const Color(0xFF111111),
        textColor: const Color(0xFF555555),
      );
    }
  }
}

enum _HighwayRisk { clear, caution, squall }

class _HighwayStatus {
  final _HighwayRisk risk;
  final String label;
  final String description;
  final Color blockColor;
  final Color textColor;
  final Color tagColor;

  const _HighwayStatus({
    required this.risk,
    required this.label,
    required this.description,
    required this.blockColor,
    required this.textColor,
    required this.tagColor,
  });

  factory _HighwayStatus.compute(WeatherProfile profile) {
    final parts = profile.escapeHighwayStatus.split(' — ');
    final label = parts[0].trim();
    final description = parts.length > 1 ? parts.sublist(1).join(' — ').trim() : label;

    _HighwayRisk risk;
    Color textColor;

    if (profile.id == WeatherProfileId.galeWindstorm || profile.id == WeatherProfileId.deepWinterBlizzard) {
      risk = _HighwayRisk.squall;
      textColor = const Color(0xFFFF3B30);
    } else if (profile.id == WeatherProfileId.shoulderFreezeThaw || profile.id == WeatherProfileId.wildfireSmokeHigh) {
      risk = _HighwayRisk.caution;
      textColor = const Color(0xFFE6FF00);
    } else {
      risk = _HighwayRisk.clear;
      textColor = const Color(0xFF00FF87);
    }

    return _HighwayStatus(
      risk: risk,
      label: label,
      description: description,
      blockColor: const Color(0xFF0A0A0A),
      textColor: textColor,
      tagColor: textColor,
    );
  }
}

enum _BugRisk { highWindHazard, lowRisk, moderate, bugAlert, campfireBan }

class _BugStatus {
  final _BugRisk risk;
  final String label;
  final String description;
  final Color tagColor;

  const _BugStatus({
    required this.risk,
    required this.label,
    required this.description,
    required this.tagColor,
  });

  factory _BugStatus.compute(WeatherProfile profile) {
    final parts = profile.escapeCampfireStatus.split(' — ');
    final label = parts[0].trim();
    final description = parts.length > 1 ? parts.sublist(1).join(' — ').trim() : label;

    _BugRisk risk;
    Color tagColor;

    if (profile.id == WeatherProfileId.galeWindstorm || profile.id == WeatherProfileId.wildfireSmokeHigh) {
      risk = _BugRisk.highWindHazard;
      tagColor = const Color(0xFFFF3B30);
    } else if (profile.id == WeatherProfileId.primeSummerClear) {
      risk = _BugRisk.lowRisk;
      tagColor = const Color(0xFF00FF87);
    } else {
      risk = _BugRisk.moderate;
      tagColor = const Color(0xFFFF9F0A);
    }

    return _BugStatus(
      risk: risk,
      label: label,
      description: description,
      tagColor: tagColor,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESCAPE DASHBOARD VIEW
// ─────────────────────────────────────────────────────────────────────────────

class EscapeDashboardView extends StatelessWidget {
  final EscapeParams params;
  final WeatherProfile profile;

  const EscapeDashboardView({super.key, required this.params, required this.profile});

  @override
  Widget build(BuildContext context) {
    final patio = _PatioScore.compute(profile);
    final highway = _HighwayStatus.compute(profile);
    final bugs = _BugStatus.compute(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EscapeHeader(isRaining: params.isRainingWeekend),
        Container(height: 1, color: Colors.white.withOpacity(0.07)),

        // ── RAIN WEEKEND PIVOT ───────────────────────────────────────────
        // When rain is detected, the Cabin & Crokinole block leads as the
        // hero card — a full editorial pivot from outdoor to indoor culture.
        if (params.isRainingWeekend) ...[
          const _CabinCrokinoleBlock(),
          Container(height: 1, color: Colors.white.withOpacity(0.07)),
        ],

        // Patio block always shown (score naturally drops during rain)
        _PatioBlock(score: patio),
        Container(height: 1, color: Colors.white.withOpacity(0.07)),
        _HighwayBlock(status: highway),
        Container(height: 1, color: Colors.white.withOpacity(0.07)),
        _BugBlock(status: bugs),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESCAPE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _EscapeHeader extends StatelessWidget {
  final bool isRaining;
  const _EscapeHeader({this.isRaining = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRaining ? '🌧️  RAINY WEEKEND PIVOT' : '⛺  WEEKEND ESCAPE',
            style: AppTypography.monoCaption.copyWith(
              color: isRaining
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFFE6FF00),
              letterSpacing: 4,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isRaining ? 'INDOOR\nCULTURE\nINDEX' : 'ACTIVITY\nINDEX',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFFFFF),
              height: 0.92,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRaining
                ? '— OUTDOOR SCORES PIVOTED TO INDOOR ALTERNATIVES'
                : '— SYNTHETIC SCORES FROM LIVE WEATHER DATA',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CABIN & CROKINOLE BLOCK — Rain Weekend Pivot (v2 addition)
// ─────────────────────────────────────────────────────────────────────────────

class _CabinCrokinoleBlock extends StatelessWidget {
  const _CabinCrokinoleBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      // Deep blue-tinted black — feels cozy and interior, not cold
      color: const Color(0xFF0D1117),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🏕  CABIN & CROKINOLE INDEX',
            style: AppTypography.monoCaption.copyWith(
              color: const Color(0xFF00F0FF),
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 20),

          // Massive score — 10/10
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '10',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFFFFF),
                  height: 0.88,
                  letterSpacing: -4,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '/10',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF444444),
                  ),
                ),
              ),
              const Spacer(),
              // Status label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFF00F0FF).withOpacity(0.4),
                      width: 1),
                ),
                child: Text(
                  'FOR CABIN COZY',
                  style: AppTypography.monoCaption.copyWith(
                    color: const Color(0xFF00F0FF),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Editorial description
          const Text(
            'The lake and trails are washed out today. Perfect excuse to fire up the woodstove, brew some tea, and break out the Crokinole board or a 1,000-piece puzzle.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 17,
              color: Color(0xFFCCCCCC),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 24),

          // Indoor activity chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _IndoorChip(label: '🎯 CROKINOLE', color: Color(0xFF00F0FF)),
              _IndoorChip(label: '🧩 1000-PC PUZZLE', color: Color(0xFF00F0FF)),
              _IndoorChip(label: '🔥 WOODSTOVE', color: Color(0xFF00F0FF)),
              _IndoorChip(label: '📚 READING', color: Color(0xFF00F0FF)),
              _IndoorChip(label: '♟  BOARD GAMES', color: Color(0xFF00F0FF)),
            ],
          ),

          const SizedBox(height: 20),

          // Cultural footnote
          Text(
            '— CROKINOLE WAS INVENTED IN ONTARIO IN 1876. THE MOST CANADIAN BOARD GAME.',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey.withOpacity(0.5),
              fontSize: 9,
              letterSpacing: 2,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndoorChip extends StatelessWidget {
  final String label;
  final Color color;

  const _IndoorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.monoCaption.copyWith(
          color: color.withOpacity(0.75),
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PATIO & BBQ INDEX BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _PatioBlock extends StatelessWidget {
  final _PatioScore score;
  const _PatioBlock({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      color: score.blockColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🍺  PATIO & BBQ INDEX',
                style: AppTypography.monoCaption.copyWith(
                  color: score.textColor.withOpacity(0.6),
                  letterSpacing: 3,
                  fontSize: 11,
                ),
              ),
              Text(
                'EVENING',
                style: AppTypography.monoCaption.copyWith(
                  color: score.textColor.withOpacity(0.4),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 110,
                  fontWeight: FontWeight.w900,
                  color: score.textColor,
                  height: 0.88,
                  letterSpacing: -4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '/10',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: score.textColor.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: score.textColor.withOpacity(0.12),
            child: Text(
              score.label,
              style: AppTypography.monoCaption.copyWith(
                color: score.textColor,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            score.description,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 16,
              color: score.textColor.withOpacity(0.8),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. HIGHWAY & GETAWAY RADAR BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _HighwayBlock extends StatelessWidget {
  final _HighwayStatus status;
  const _HighwayBlock({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      color: status.blockColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚗  HIGHWAY & GETAWAY RADAR',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status.label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: status.tagColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'HWY 400 / HWY 11 / REGIONAL ROUTES',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status.description,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              color: AppColors.pureWhite.withOpacity(0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '→ CHECK 511.ONTARIO.CA BEFORE DEPARTURE',
            style: AppTypography.monoCaption.copyWith(
              color: status.tagColor.withOpacity(0.5),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CAMPFIRE & BUG GAUGE BLOCK
// ─────────────────────────────────────────────────────────────────────────────

class _BugBlock extends StatelessWidget {
  final _BugStatus status;
  const _BugBlock({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      color: const Color(0xFF0D0D0D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏕  CAMPFIRE & BUG GAUGE',
            style: AppTypography.monoCaption.copyWith(
              color: AppColors.concreteGrey,
              letterSpacing: 3,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              border:
                  Border.all(color: status.tagColor, width: 1.5),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: status.tagColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            status.description,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 15,
              color: AppColors.pureWhite.withOpacity(0.65),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickTip(label: 'DEET 30%', color: status.tagColor),
              _QuickTip(label: 'CITRONELLA', color: status.tagColor),
              _QuickTip(label: 'FIRE PERMIT', color: status.tagColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTip extends StatelessWidget {
  final String label;
  final Color color;

  const _QuickTip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.monoCaption.copyWith(
          color: color.withOpacity(0.7),
          fontSize: 9,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
