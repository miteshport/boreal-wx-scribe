import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';

class PlanYourDayWidget extends StatefulWidget {
  final List<ActivityScore> scores;

  const PlanYourDayWidget({super.key, required this.scores});

  @override
  State<PlanYourDayWidget> createState() => _PlanYourDayWidgetState();
}

class _PlanYourDayWidgetState extends State<PlanYourDayWidget> {
  List<String> _hiddenActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hiddenActivities = prefs.getStringList('hidden_activities') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _toggleActivity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_hiddenActivities.contains(id)) {
        _hiddenActivities.remove(id);
      } else {
        _hiddenActivities.add(id);
      }
    });
    await prefs.setStringList('hidden_activities', _hiddenActivities);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY SETTINGS',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.pureWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toggle which activities appear in your dashboard.',
                    style: AppTypography.monoCaption.copyWith(
                      color: AppColors.concreteGrey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...widget.scores.map((activity) {
                    final isHidden = _hiddenActivities.contains(activity.id);
                    return CheckboxListTile(
                      activeColor: const Color(0xFF00F0FF),
                      checkColor: const Color(0xFF0A0A0A),
                      side: const BorderSide(color: AppColors.concreteGrey),
                      title: Text(
                        activity.title,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pureWhite,
                        ),
                      ),
                      value: !isHidden,
                      onChanged: (val) async {
                        await _toggleActivity(activity.id);
                        setModalState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── SOLAR-YELLOW SURVIVAL SHEET ──────────────────────────────────────────
  void _openSurvivalSheet(BuildContext context, ActivityScore score) {
    final Color sheetBg = const Color(0xFFD4FF00);
    final Color textBlack = const Color(0xFF0A0A0A);
    final Color dividerColor = const Color(0xFF1A1A00);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Drag handle ────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        color: textBlack.withValues(alpha: 0.25),
                        margin: const EdgeInsets.only(bottom: 28),
                      ),
                    ),
                    // ── Section label ──────────────────────────────────────
                    Text(
                      '${score.title.toUpperCase()} — CANADIAN SURVIVAL SHEET',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textBlack.withValues(alpha: 0.5),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Headline ───────────────────────────────────────────
                    Text(
                      score.headline.isNotEmpty
                          ? score.headline
                          : score.title.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: textBlack,
                        letterSpacing: -1.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 2, color: dividerColor),
                    const SizedBox(height: 24),
                    // ── Block 1: IMMEDIATE ACTION ──────────────────────────
                    Text(
                      '01 — IMMEDIATE ACTION',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textBlack,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      score.immediateAction.isNotEmpty
                          ? score.immediateAction
                          : score.message,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textBlack,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: dividerColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 24),
                    // ── Block 2: CANADIAN CONTEXT ──────────────────────────
                    Text(
                      '02 — CANADIAN CONTEXT',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textBlack,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      score.canadianContext.isNotEmpty
                          ? score.canadianContext
                          : 'No additional context available for current conditions.',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textBlack.withValues(alpha: 0.75),
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: dividerColor.withValues(alpha: 0.4)),
                    const SizedBox(height: 24),
                    // ── Block 3: GENERAL MESSAGE (quick digest) ────────────
                    Text(
                      '03 — QUICK DIGEST',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textBlack,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      score.message,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textBlack.withValues(alpha: 0.65),
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForScore(ScoreLevel level) {
    return switch (level) {
      ScoreLevel.good => const Color(0xFF00FF87),
      ScoreLevel.fair => const Color(0xFFE6FF00),
      ScoreLevel.poor => const Color(0xFFFF3B30),
    };
  }

  String _getScoreLabel(ScoreLevel level) {
    return switch (level) {
      ScoreLevel.good => 'GOOD',
      ScoreLevel.fair => 'FAIR',
      ScoreLevel.poor => 'POOR',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final visibleScores =
        widget.scores.where((s) => !_hiddenActivities.contains(s.id)).toList();

    if (visibleScores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NO ACTIVITIES SELECTED',
              style: AppTypography.monoCaption.copyWith(color: AppColors.concreteGrey),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.concreteGrey),
              onPressed: _openSettings,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAN YOUR DAY',
                style: AppTypography.monoCaption.copyWith(
                  color: AppColors.concreteGrey,
                  letterSpacing: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: AppColors.concreteGrey, size: 20),
                onPressed: _openSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: visibleScores.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final score = visibleScores[index];
              final scoreColor = _getColorForScore(score.score);

              return GestureDetector(
                onTap: () => _openSurvivalSheet(context, score),
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(score.icon, color: scoreColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            score.title.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pureWhite,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getScoreLabel(score.score),
                              style: AppTypography.monoCaption.copyWith(
                                color: scoreColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        score.message,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 15,
                          color: AppColors.concreteGrey,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // "TAP TO EXPAND" hint
                      Text(
                        '↑ TAP FOR SURVIVAL SHEET',
                        style: AppTypography.monoCaption.copyWith(
                          color: scoreColor.withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


