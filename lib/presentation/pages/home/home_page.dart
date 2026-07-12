/// home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_sync_ca/core/theme/color_palette.dart';
import 'package:weather_sync_ca/presentation/blocs/seasonal/seasonal_bloc.dart';
import 'package:weather_sync_ca/presentation/blocs/seasonal/seasonal_state.dart';
import 'package:weather_sync_ca/presentation/pages/summer/summer_dashboard_page.dart';
import 'package:weather_sync_ca/presentation/pages/winter/winter_dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeasonalBloc, SeasonalState>(
      builder: (context, state) {
        return switch (state) {
          SeasonalInitial() => const Scaffold(
              backgroundColor: AppColors.voidBlack,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          SeasonalWinterActive() => const WinterDashboardPage(),
          SeasonalSummerActive() => const SummerDashboardPage(),
        };
      },
    );
  }
}
