/// winter_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/core/theme/typography.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/admob_banner_widget.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/weather_state_icon.dart';
import 'package:weather_sync_ca/presentation/widgets/shared/actionable_chore_card.dart';
import 'package:weather_sync_ca/domain/usecases/canadian_advice_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WinterDashboardPage extends StatefulWidget {
  const WinterDashboardPage({super.key});

  @override
  State<WinterDashboardPage> createState() => _WinterDashboardPageState();
}

class _WinterDashboardPageState extends State<WinterDashboardPage> {
  late CanadianAdviceEngine _adviceEngine;
  List<AdviceResult> _adviceList = [];

  @override
  void initState() {
    super.initState();
    _initAdviceEngine();
  }

  Future<void> _initAdviceEngine() async {
    final prefs = await SharedPreferences.getInstance();
    _adviceEngine = CanadianAdviceEngine(prefs: prefs);

    // Simulate current weather parameters that trigger the Winter rules
    // (e.g. Temp < -12 and heavy snow)
    final advice = await _adviceEngine.generateAdvice(
      const CanadianAdviceParams(
        temperatureC: -15.0,
        snowfallCm: 8.0,
        isSnowing: true,
        currentHour: 8,
      ),
    );

    setState(() {
      _adviceList = advice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WINTER SYNC',
          style: AppTypography.titleLarge.copyWith(letterSpacing: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentConditions(),
              const SizedBox(height: 16),
              const _ShovelWindowCard(),
              const SizedBox(height: 16),
              const _WindrowAlertCard(),
              const SizedBox(height: 16),

              // Map the advice list to our new ActionableChoreCard
              if (_adviceList.isNotEmpty) ...[
                Text('CANADIAN SURVIVAL GUIDE',
                    style: AppTypography.labelMedium),
                const SizedBox(height: 8),
                ..._adviceList
                    .map((advice) => ActionableChoreCard(advice: advice)),
              ],

              const SizedBox(height: 16),
              const AdMobBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStroke),
        color: AppColors.surfaceElevated,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TORONTO', style: AppTypography.labelMedium),
              Text('-15°', style: AppTypography.displayMedium),
            ],
          ),
          const WeatherStateIcon(condition: 'snow', size: 48),
        ],
      ),
    );
  }
}

class _ShovelWindowCard extends StatelessWidget {
  const _ShovelWindowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStroke),
        color: AppColors.surfaceElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ac_unit, color: AppColors.iceSpark, size: 20),
              const SizedBox(width: 8),
              Text('SHOVEL WINDOW',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.iceSpark)),
            ],
          ),
          const SizedBox(height: 16),
          Text('02:45', style: AppTypography.monoDisplay),
          Text('UNTIL OPTIMAL CLEARING WINDOW',
              style: AppTypography.monoCaption),
        ],
      ),
    );
  }
}

class _WindrowAlertCard extends StatelessWidget {
  const _WindrowAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.iceSpark, width: 2),
        color: AppColors.surfaceDim,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WINDROW ALERT', style: AppTypography.labelLarge),
          const SizedBox(height: 8),
          Text(
            'City plow expected to block driveway entrance between 4:00 PM and 6:00 PM.',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
