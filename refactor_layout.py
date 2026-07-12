import re

with open('lib/presentation/pages/redesign/today_tab_view.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We need to replace the content inside builder: (context, constraints) { ... }
# The best way is to locate 'final isLargeScreen = constraints.maxWidth >= 600.0;'
# and replace everything up to the matching '});' of LayoutBuilder.

new_builder_logic = '''
                final isLargeScreen = constraints.maxWidth >= 600.0;

                final heroOverview = BentoEntrance(
                  delay: const Duration(milliseconds: 0),
                  child: _HeroWeatherOverview(
                    liveData: liveData,
                    activeProfile: activeProfile,
                    settings: settings,
                    intel: intel,
                    isLoading: isLoading,
                  ),
                );

                final environmentalDeck = BentoEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: _EnvironmentalDeck(
                    intel: intel,
                    isLoading: isLoading,
                  ),
                );

                final dockedCard = BentoEntrance(
                  delay: const Duration(milliseconds: 200),
                  child: _DockedCard(
                    intel: intel,
                    isLoading: isLoading,
                  ),
                );

                final badges = filteredScores.isNotEmpty
                    ? BentoEntrance(
                        delay: const Duration(milliseconds: 250),
                        child: PlanYourDayBadges(scores: filteredScores),
                      )
                    : const SizedBox.shrink();

                final sunCard = BentoEntrance(
                  delay: const Duration(milliseconds: 300),
                  child: SunFlipCard(liveData: liveData),
                );

                Widget weeklyCard = const SizedBox.shrink();
                Widget weekendAnchorBlock = const SizedBox.shrink();
                if (liveData?.dailyForecasts.isNotEmpty ?? false) {
                  final dailyForecasts = liveData!.dailyForecasts;
                  final taggedWeek = WeeklyForecastingEngine.tagWeek(dailyForecasts);
                  final weekendDays = taggedWeek.where((t) => t.isWeekend).toList();
                  final weekendSummary = WeeklyForecastingEngine.generateWeekendSummary(weekendDays);

                  if (weekendDays.isNotEmpty) {
                    weekendAnchorBlock = BentoEntrance(
                      delay: const Duration(milliseconds: 350),
                      child: WeekendAnchorBlock(
                        weekendDays: weekendDays,
                        summary: weekendSummary,
                      ),
                    );
                  }

                  weeklyCard = BentoEntrance(
                    delay: const Duration(milliseconds: 400),
                    child: WeeklyCanadianPlannerCard(
                      taggedWeek: taggedWeek,
                      weekendSummary: weekendSummary,
                    ),
                  );
                }
                
                final aqhiCard = liveData != null && airQuality != null
                    ? BentoEntrance(
                        delay: const Duration(milliseconds: 400),
                        child: AqhiSmokeDriftCard(
                          aq: airQuality!,
                          weather: liveData!,
                        ),
                      )
                    : const SizedBox.shrink();

                final ecccButton = BentoEntrance(
                  delay: const Duration(milliseconds: 500),
                  child: _EnvironmentCanadaButton(liveData: liveData),
                );

                Widget scrollContent;

                if (isLargeScreen) {
                  // GLASS COCKPIT — WIDESCREEN LAYOUT (>= 600px)
                  scrollContent = SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TIER 1: THE COMMAND CENTER
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT COLUMN (40%): Hero Weather ONLY
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [heroOverview],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // RIGHT COLUMN (60%): Crown Jewel + Manifest + Slang
                              Expanded(
                                flex: 6,
                                child: BentoEntrance(
                                  delay: const Duration(milliseconds: 150),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F0FF).withValues(alpha: 0.25),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'CANADIAN SURVIVAL GUIDE',
                                              style: TextStyle(
                                                fontFamily: 'JetBrains Mono',
                                                color: Color(0xFF00F0FF),
                                                letterSpacing: 2,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => showDialog(
                                                context: context,
                                                builder: (_) => TacticalBriefingModal(vaultData: intel),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                                                ),
                                                child: const Text(
                                                  'FULL BRIEFING ?',
                                                  style: TextStyle(
                                                    fontFamily: 'JetBrains Mono',
                                                    color: Color(0xFF00F0FF),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF141414),
                                            border: Border.all(color: const Color(0xFFFF4500), width: 1),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'ROAD-TRIP TRANSLATOR & SLANG HUD',
                                                style: TextStyle(
                                                  fontFamily: 'JetBrains Mono',
                                                  color: Color(0xFFFF4500),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TeletypeText(
                                                intel?.roadTripSlang ?? 'Awaiting AI uplink...',
                                                style: const TextStyle(
                                                  fontFamily: 'SpaceGrotesk',
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF141414),
                                            border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PRE-FLIGHT ESCAPE MANIFEST',
                                                style: TextStyle(
                                                  fontFamily: 'JetBrains Mono',
                                                  color: Color(0xFF00F0FF),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TeletypeText(
                                                intel?.escapeManifest ?? 'Awaiting AI uplink...',
                                                style: const TextStyle(
                                                  fontFamily: 'SpaceGrotesk',
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TIER 2: FLIGHT HORIZON
                        weeklyCard,
                        // TIER 3: ACTIVITY RIBBON
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: badges,
                        ),
                        // TIER 4: INTELLIGENCE MATRIX (MASONRY)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: StaggeredGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: [
                              StaggeredGridTile.fit(crossAxisCellCount: 1, child: aqhiCard),
                              StaggeredGridTile.fit(crossAxisCellCount: 1, child: sunCard),
                              StaggeredGridTile.fit(crossAxisCellCount: 1, child: weekendAnchorBlock),
                              StaggeredGridTile.fit(crossAxisCellCount: 1, child: environmentalDeck),
                              StaggeredGridTile.fit(crossAxisCellCount: 2, child: dockedCard),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // SLAB PHONE VIEW (< 600px)
                  scrollContent = SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TIER 1: IMMEDIATE TELEMETRY & ACTION
                        heroOverview,
                        BentoEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: _CanadianSurvivalGuideCard(intel: intel),
                        ),
                        // TIER 2: THE HORIZON
                        weeklyCard,
                        // TIER 3: METRICS & ACTION (2x2 Grid)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: badges),
                                    const SizedBox(width: 8),
                                    Expanded(child: aqhiCard),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: sunCard),
                                    const SizedBox(width: 8),
                                    Expanded(child: weekendAnchorBlock),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // TIER 4: THE DEEP CONTEXT DECK
                        environmentalDeck,
                        dockedCard,
                      ],
                    ),
                  );
                }

                return Stack(
                  children: [
                    scrollContent,
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ecccButton,
                    ),
                  ],
                );
              },
'''

import re
pattern = re.compile(r"final isLargeScreen = constraints\.maxWidth >= 600\.0;.*?return\s+(?:SingleChildScrollView|Stack)\(.*?\);\s*},\s*\);", re.DOTALL)

# Let's do a more precise replacement using the lines we know.
start_idx = content.find("final isLargeScreen = constraints.maxWidth >= 600.0;")
end_idx = content.find("          },", start_idx) # the end of LayoutBuilder builder
end_idx2 = content.find("        );", end_idx) # end of LayoutBuilder

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + new_builder_logic + content[end_idx:]
    with open('lib/presentation/pages/redesign/today_tab_view.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Successfully replaced layout builder logic.")
else:
    print("Could not find start/end indices.")

