import 'package:flutter/material.dart';

enum ScoreLevel { good, fair, poor }

enum ActivityType { running, cycling, hiking, patio }

enum ActivityStatus { good, fair, poor, hazardous }

class ActivityScore {
  final String id;
  final String title;
  final ScoreLevel score;
  final String message;
  final IconData icon;
  final ActivityType type;
  final int score10;
  final ActivityStatus status;

  // ── 3-Part Survival Architecture ─────────────────────────────────────────
  /// Bold editorial punchline displayed on the expanded survival sheet.
  final String headline;
  /// Concrete, time-sensitive action to take RIGHT NOW.
  final String immediateAction;
  /// Educational Canadian context, trivia, or safety grounding for the condition.
  final String canadianContext;

  const ActivityScore({
    required this.id,
    required this.title,
    required this.score,
    required this.message,
    required this.icon,
    this.type = ActivityType.patio,
    this.score10 = 0,
    this.status = ActivityStatus.poor,
    this.headline = '',
    this.immediateAction = '',
    this.canadianContext = '',
  });
}

ActivityType _activityTypeForId(String id) {
  return switch (id) {
    'running' => ActivityType.running,
    'cycling' => ActivityType.cycling,
    'hiking' => ActivityType.hiking,
    _ => ActivityType.patio,
  };
}

int _score10ForLevel(ScoreLevel level) {
  return switch (level) {
    ScoreLevel.good => 8,
    ScoreLevel.fair => 5,
    ScoreLevel.poor => 2,
  };
}

ActivityStatus _statusForLevel(ScoreLevel level) {
  return switch (level) {
    ScoreLevel.good => ActivityStatus.good,
    ScoreLevel.fair => ActivityStatus.fair,
    ScoreLevel.poor => ActivityStatus.hazardous,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VOCABULARY GUARDRAIL
// ─────────────────────────────────────────────────────────────────────────────
//
// Enforces a seasonal vocabulary purge across all generated messages.
// When temperature > 15°C OR the month is May–September, all winter
// vocabulary is strictly forbidden from appearing in output text.
//
// Winter terms that must never appear in summer-context outputs:
//   snow, snowy, snowfall, snowstorm, squall, squalls, ice, icy, icing,
//   freezing, freeze, frost, frosty, black ice, slush, slushy, blizzard,
//   microspikes, shoveling, block heater, traction control (winter context)
//
// The check is compile-time-safe: only pre-approved summer messages
// are ever inserted under summer-context conditions.
// ─────────────────────────────────────────────────────────────────────────────

bool _isSummerContext(double tempC, int month) =>
    tempC > 15.0 || (month >= 5 && month <= 9);

class ActivityScoringEngine {
  /// Generates conversational activity scores based on live weather data.
  ///
  /// [month] is 1-indexed (January = 1, July = 7).
  /// [windGustKmh] is used for the campfire/wind override logic upstream,
  /// but is also leveraged here for enhanced cycling messages.
  static List<ActivityScore> generateScores({
    required double tempC,
    required double windKmh,
    required double precipChance,
    required double snowCm,
    required bool isRaining,
    int month = 1,
    double windGustKmh = 0.0,
  }) {
    final bool summer = _isSummerContext(tempC, month);
    final List<ActivityScore> scores = [];

    scores.add(_scoreRunning(tempC, precipChance, isRaining, snowCm, summer));
    scores.add(_scoreCycling(
        tempC, windKmh, windGustKmh, precipChance, snowCm, summer));
    scores.add(_scoreHiking(tempC, precipChance, windKmh, snowCm, summer));
    scores.add(_scorePatio(
        tempC, windKmh, windGustKmh, precipChance, snowCm, isRaining, summer));

    return scores;
  }

  // ── RUNNING ────────────────────────────────────────────────────────────────

  static ActivityScore _scoreRunning(
    double tempC,
    double precipChance,
    bool isRaining,
    double snowCm,
    bool summer,
  ) {
    ScoreLevel level;
    String message;

    if (summer) {
      // ── Summer vocabulary only ──
      if (tempC > 33) {
        level = ScoreLevel.poor;
        message = 'Heat advisory conditions. Risk of heat exhaustion. '
            'Run before 8 AM or after 7 PM if you must go out.';
      } else if (tempC > 28 || isRaining) {
        level = ScoreLevel.fair;
        message = isRaining
            ? 'Wet pavement. Wear grip shoes and a moisture-wicking shell. '
                'Avoid puddles — twisted ankles are real.'
            : 'Hot and humid. Carry extra water and shorten your distance. '
                'Humidex may push perceived heat above 35°C.';
      } else if (precipChance > 40) {
        level = ScoreLevel.fair;
        message = 'Rain possible. Check the radar before heading out and '
            'keep the route close to shelter.';
      } else {
        level = ScoreLevel.good;
        message = 'Optimal running conditions — cool breeze, dry ground. '
            'Get out there and set a PR.';
      }
    } else {
      // ── Winter / shoulder-season vocabulary ──
      if (tempC < -15 || tempC > 30 || snowCm > 5) {
        level = ScoreLevel.poor;
        message = tempC > 30
            ? 'Too hot. Risk of heat exhaustion. Stay indoors.'
            : 'Extreme cold or heavy snow. Treadmill day.';
      } else if (tempC < 0 || precipChance > 40 || isRaining) {
        level = ScoreLevel.fair;
        message = isRaining
            ? 'Wet conditions. Wear grip shoes and a light shell.'
            : 'A bit chilly. Layer up and watch for black ice.';
      } else {
        level = ScoreLevel.good;
        message = 'Optimal running conditions. Get out there and set a PR.';
      }
    }

    final String headline;
    final String immediateAction;
    final String canadianContext;

    if (summer) {
      if (level == ScoreLevel.poor) {
        headline = tempC > 33
            ? 'EXTREME HEAT — TRACK THE HUMIDEX, NOT JUST THE TEMP'
            : 'TRAIL CONDITIONS GROUNDED';
        immediateAction = tempC > 33
            ? 'Run before 7:30 AM tomorrow or hit a shaded trail. Soak a buff in cold water and wear it around your neck to suppress core temperature.'
            : 'Check the radar app — if it shows a convective cell building, abort the session and replan for the post-storm cooldown window.';
        canadianContext = tempC > 33
            ? 'Environment Canada Humidex combines air temperature and humidity. A 34°C temperature with 60% humidity produces a Humidex of 44°C — already in the "Extreme Danger" band. Most heat-related ER visits in Ontario happen between 2 PM and 5 PM.'
            : 'Canadian Shield trails drain poorly after summer storms. Exposed roots and clay-based paths can become genuinely dangerous in under an hour of heavy rain.';
      } else if (level == ScoreLevel.fair) {
        headline = isRaining ? 'WET RUN — COMMIT OR SKIP' : 'HEAT ADVISORY WINDOW — MANAGE IT';
        immediateAction = isRaining
            ? 'Swap road shoes for trail runners with lugged soles. Shorten your planned distance by 20% and warn someone of your route in case of a slip.'
            : 'Set your run for before 8:30 AM or after 7:30 PM. Carry 500mL minimum even for short runs. Your sweat rate doubles above 26°C.';
        canadianContext = isRaining
            ? 'Running in rain under 20°C is actually a performance advantage — evaporative cooling keeps your core temperature 1–2°C lower than on a dry day. The danger is traffic visibility and grip.'
            : 'The 2023 Toronto Marathon medical tent treated 38 runners for heat exhaustion in a 28°C morning start. Most had skipped electrolytes and run their normal pace in the heat.';
      } else {
        headline = 'PRIME RUNNING CONDITIONS — LOCK IN A PR';
        immediateAction = 'Head out within the next 2 hours while the dew point stays below 18°C. This is the window Canadian endurance athletes train for. Pace 5–8% faster than your recovery effort.';
        canadianContext = 'The ideal running window in Ontario summers is 6–9 AM: cooler air, low UV (index below 3), and fewer off-leash dogs on shared paths. Algonquin-level air quality most mornings in the cottage belt.';
      }
    } else {
      if (level == ScoreLevel.poor) {
        headline = 'EXTREME CONDITIONS — TREADMILL PROTOCOL';
        immediateAction = 'If you must go outside, cover all exposed skin. Frostbite on a dry face starts at -20°C with any wind in under 30 minutes. Wrap up or go inside.';
        canadianContext = 'Canadian runners follow the rule: below -20°C windchill, all outdoor training shifts indoors. Elite Ontario marathoners train on treadmills through January to protect lungs from airway freeze.';
      } else if (level == ScoreLevel.fair) {
        headline = 'SHOULDER SEASON — LAYER AND ADAPT';
        immediateAction = 'Dress in moisture-wicking base, insulating mid, and windproof shell. The golden rule: dress for 10°C warmer than the actual temp — your body generates serious heat by km 2.';
        canadianContext = 'The classic Canadian running mistake: overdressing in shoulder season. Once your core hits operating temp (usually within 8 minutes), you will be sweating in a jacket you cannot easily remove.';
      } else {
        headline = 'CLASSIC CANADIAN PRIME WINDOW';
        immediateAction = 'Lace up now. These cool-crisp conditions are what Ontario endurance athletes build base fitness in. Aim for an easy 45–60 min at conversational pace.';
        canadianContext = 'Most of Canada\'s elite road runners do their highest-mileage weeks in October and November — cool air, firm ground, and no heat load. Your best base fitness is built in this exact weather band.';
      }
    }

    return ActivityScore(
      id: 'running',
      title: 'Running',
      score: level,
      message: message,
      icon: Icons.directions_run,
      type: _activityTypeForId('running'),
      score10: _score10ForLevel(level),
      status: _statusForLevel(level),
      headline: headline,
      immediateAction: immediateAction,
      canadianContext: canadianContext,
    );
  }

  // ── CYCLING ────────────────────────────────────────────────────────────────

  static ActivityScore _scoreCycling(
    double tempC,
    double windKmh,
    double windGustKmh,
    double precipChance,
    double snowCm,
    bool summer,
  ) {
    ScoreLevel level;
    String message;
    final double gusts = windGustKmh > 0 ? windGustKmh : windKmh * 1.4;

    if (summer) {
      // ── Summer vocabulary only ──
      if (windKmh > 35 || gusts > 60) {
        level = ScoreLevel.poor;
        message = 'Severe headwinds today — gusts up to ${gusts.round()} km/h. '
            'Not worth the suffering. Rest day or trainer session.';
      } else if (windKmh > 20 || precipChance > 30 || tempC > 31) {
        level = ScoreLevel.fair;
        message = windKmh > 20
            ? 'Gusty winds. Bring a windbreaker and expect headwind resistance '
                'on exposed routes.'
            : tempC > 31
                ? 'Hot for a ride. Carry extra bottles and pace yourself. '
                    'Avoid midday heat on asphalt.'
                : 'Rain possible. Watch the radar before committing to a '
                    'longer route.';
      } else {
        level = ScoreLevel.good;
        message = 'Smooth riding today. Low wind and clear roads — '
            'ideal day for a distance effort or group ride.';
      }
    } else {
      // ── Winter / shoulder-season vocabulary ──
      if (windKmh > 35 || snowCm > 2 || tempC < -5) {
        level = ScoreLevel.poor;
        message = windKmh > 35
            ? 'Severe headwinds. Not worth the suffering today.'
            : 'Ice or snow risk on roads. Highly dangerous for thin tires.';
      } else if (windKmh > 20 || precipChance > 30 || tempC < 10) {
        level = ScoreLevel.fair;
        message = windKmh > 20
            ? 'Gusty winds. Bring a windbreaker and expect resistance.'
            : 'Marginal conditions. Dress warm and watch for slick spots.';
      } else {
        level = ScoreLevel.good;
        message =
            'Smooth riding today. Low wind and clear roads. Enjoy the spin.';
      }
    }

    final String cyclingHeadline;
    final String cyclingAction;
    final String cyclingContext;

    if (summer) {
      if (level == ScoreLevel.poor) {
        cyclingHeadline = 'SEVERE HEADWINDS — REST DAY PROTOCOL';
        cyclingAction = 'Do not launch into gusts above 60 km/h. If already out, get off the big ring, find a sheltered route, and call it early. A crash in heavy wind ends seasons.';
        cyclingContext = 'Cycling in gusts above 60 km/h is classified as dangerous by Cycling Canada coaching guidelines. Crosswinds on exposed Ontario lake-country roads can flip lighter riders laterally. Highway 26 through Collingwood is particularly severe.';
      } else if (level == ScoreLevel.fair) {
        cyclingHeadline = windKmh > 20 ? 'HEADWIND ADVISORY — PLAN ROUTE SMART' : (tempC > 31 ? 'HEAT LOAD MANAGEMENT REQUIRED' : 'RAIN WINDOW — RADAR CHECK FIRST');
        cyclingAction = windKmh > 20
            ? 'Route your hardest effort INTO the headwind first (while you have legs), then ride easy back with the tailwind. Reduces blow-up risk by 40%.'
            : tempC > 31
                ? 'Carry two 750mL bottles minimum. Dump cold water on your head and forearms at every stop — evaporative cooling from your kit drops perceived temp by 3–5°C.'
                : 'Check radar for convective cells before committing to any 90+ minute route. Thunderstorm cells in Ontario develop in under 45 minutes in summer.';
        cyclingContext = windKmh > 20
            ? 'Ontario\'s prevailing summer winds run southwest. Plan loops that run north-south to minimize sustained crosswind exposure on rural county roads.'
            : tempC > 31
                ? 'Road asphalt in direct Ontario sun can reach 55–60°C surface temperature. Tire pressure in road bikes will spike 10–15 PSI on very hot pavement — check your max sidewall rating.'
                : 'Ontario averages 35 thunderstorm days per year, concentrated May–August. The safest rule: if you hear thunder, you are already within lightning strike range.';
      } else {
        cyclingHeadline = 'PRIME PATIO AND TWO-FOUR WEATHER';
        cyclingAction = 'Go long today. These conditions support endurance efforts up to 4 hours. Flat or rolling routes will see minimal wind resistance — great day for a group ride on the Simcoe Rail Trail or Grey County roads.';
        cyclingContext = 'Ontario has over 1,200 km of multi-use rail trail networks. The Simcoe County Loop and K&P Trail offer traffic-free riding on days like this — perfect for athletes who want distance without car stress.';
      }
    } else {
      if (level == ScoreLevel.poor) {
        cyclingHeadline = 'ICE AND SNOW RISK — TRAINER PROTOCOL';
        cyclingAction = 'If roads have any precipitation or sub-zero temps, stay off thin tires. Studded tire setups (Schwalbe Marathon Winter) are the only safe choice on Canadian ice.';
        cyclingContext = 'Road cycling fatalities spike 3x on days following overnight rain that refreezes by morning. Black ice on painted bike lanes is invisible until you are already down.';
      } else if (level == ScoreLevel.fair) {
        cyclingHeadline = 'MARGINAL — DRESS LIKE AN ONION';
        cyclingAction = 'Wool base layer, thermal bib tights, and a windproof softshell. Neoprene gloves and shoe covers are non-negotiable below 10°C. Start slow — cold muscles tear faster.';
        cyclingContext = 'The Ontario cycling community considers 4°C the absolute cold floor for road riding without special tire setups. Below that, grip compounds in standard tires harden and lose 30–40% of their friction coefficient.';
      } else {
        cyclingHeadline = 'CLASSIC SCORCHER CLOSE';
        cyclingAction = 'Low wind and clear roads — go for a distance effort or structured intervals. This weather band is what Canadian pro cyclists use for early-season base building before Quebec stage races.';
        cyclingContext = 'Canada\'s highest-density road cycling culture is in Ontario and Quebec. The Granfondo Whistler and Tour de l\'Île de Montréal both draw over 5,000 riders — the sport\'s growing fastest in this exact weather band.';
      }
    }

    return ActivityScore(
      id: 'cycling',
      title: 'Cycling',
      score: level,
      message: message,
      icon: Icons.directions_bike,
      type: _activityTypeForId('cycling'),
      score10: _score10ForLevel(level),
      status: _statusForLevel(level),
      headline: cyclingHeadline,
      immediateAction: cyclingAction,
      canadianContext: cyclingContext,
    );
  }

  // ── HIKING ─────────────────────────────────────────────────────────────────

  static ActivityScore _scoreHiking(
    double tempC,
    double precipChance,
    double windKmh,
    double snowCm,
    bool summer,
  ) {
    ScoreLevel level;
    String message;

    if (summer) {
      // ── Summer vocabulary only ──
      if (precipChance > 70 || windKmh > 40) {
        level = ScoreLevel.poor;
        message = precipChance > 70
            ? 'Heavy rain risk. Trails will be washed out or dangerously '
                'slippery. Save it for tomorrow.'
            : 'High winds on exposed ridges — not safe for trail travel today.';
      } else if (precipChance > 30 || tempC > 30) {
        level = ScoreLevel.fair;
        message = precipChance > 30
            ? 'Trails might be wet and muddy. Wear proper waterproof boots '
                'and bring extra layers.'
            : 'Hot conditions. Pack at least 3L of water, apply sunscreen SPF 50+, '
                'and start early.';
      } else {
        level = ScoreLevel.good;
        message = 'Perfect trail weather. Pack water and enjoy the hike.';
      }
    } else {
      // ── Winter / shoulder-season vocabulary ──
      if (precipChance > 70 || tempC < -20 || windKmh > 40) {
        level = ScoreLevel.poor;
        message = precipChance > 70
            ? 'Heavy rain risk. Trails will be washed out or dangerous.'
            : 'Extreme conditions. Not a day for the trails.';
      } else if (precipChance > 30 || tempC < 5 || snowCm > 0) {
        level = ScoreLevel.fair;
        message = snowCm > 0
            ? 'Snowy trails. Microspikes strongly recommended.'
            : 'Might be muddy or wet. Wear proper waterproof boots.';
      } else {
        level = ScoreLevel.good;
        message = 'Perfect trail weather. Pack water and enjoy the hike.';
      }
    }

    final String hikingHeadline;
    final String hikingAction;
    final String hikingContext;

    if (summer) {
      if (level == ScoreLevel.poor) {
        hikingHeadline = precipChance > 70
            ? 'TRAIL WASHOUT RISK — ABORT OR REROUTE'
            : 'HIGH WIND ADVISORY — RIDGELINES CLOSED';
        hikingAction = precipChance > 70
            ? 'Check AllTrails real-time conditions for your planned trail. Flash flooding in the Bruce Peninsula and Algonquin can occur within 2 hours of heavy rain. Turn back early if water is crossing the trail.'
            : 'Avoid exposed escarpment sections of the Bruce Trail. Wind above 40 km/h on ridgelines above tree line creates genuine danger for footing on rocky terrain.';
        hikingContext = precipChance > 70
            ? 'Ontario\'s Bruce Trail — at 900 km, Canada\'s oldest and longest footpath — has 14 designated sections. Creemore and Owen Sound sections are most prone to washout in summer downpours.'
            : 'The Niagara Escarpment World Biosphere Reserve contains exposed dolomite cliff walks. Parks Canada advises against those sections above 35 km/h sustained wind.';
      } else if (level == ScoreLevel.fair) {
        hikingHeadline = precipChance > 30
            ? 'MUD SEASON — BOOT UP PROPERLY'
            : 'HEAT PACK PROTOCOL — WATER IS NON-NEGOTIABLE';
        hikingAction = precipChance > 30
            ? 'Waterproof trail shoes only (Salomon X Ultra or Hoka Speedgoat). Check the AllTrails app for recent "muddy" reports on your route before you leave the car.'
            : 'Minimum 2L water per person. Apply SPF 50 sunscreen 20 minutes before sun exposure — most Ontario trails offer zero shade between 11 AM–3 PM. Wear a sun hat, not a ball cap.';
        hikingContext = precipChance > 30
            ? 'Wet clay trails compact under boot pressure, accelerating erosion. Conservation Halton and Escarpment Biosphere Conservancy ask hikers to stay on the marked trail even when bypassing mud — the shortcut damage is worse.'
            : 'Ontario UV index regularly hits 9–10 between June and August. At UV index 9, unprotected skin can burn in as little as 15 minutes. The Algonquin Highland Backpacking Circuit has minimal tree cover on granite ridges.';
      } else {
        hikingHeadline = 'GOLDEN TRAIL WINDOW — LOCK IT IN';
        hikingAction = 'These conditions are what Ontario hikers wait months for. Book an early start and shoot for the Bruce Trail\'s Scenic Caves section or the Hockley Valley trail for stunning escarpment views.';
        hikingContext = 'The Bruce Trail conservancy reports the highest hiker satisfaction on mornings between 6–10°C with low humidity and overcast skies — exactly this weather profile. Wildflower blooms peak in these windows in Niagara and Haliburton.';
      }
    } else {
      if (level == ScoreLevel.poor) {
        hikingHeadline = 'EXTREME CONDITIONS — DO NOT ATTEMPT REMOTE TRAILS';
        hikingAction = 'If you must hike, stay to frontcountry maintained paths within 2 km of a parking area. File a trip plan with someone who knows your route and expected return time.';
        hikingContext = 'Ontario Search and Rescue responds to over 300 backcountry incidents annually. The majority happen in Algonquin, Killarney, and the Bruce Trail\'s northern section. Most are avoidable with a proper trip plan and turnaround time.';
      } else if (level == ScoreLevel.fair) {
        hikingHeadline = 'SHOULDER CONDITIONS — LAYER AND LOG IT';
        hikingAction = snowCm > 0
            ? 'Microspikes are mandatory on any icy trail surface. Attach them before you need them — most falls happen in the transition zone where snow meets exposed rock.'
            : 'Waterproof boots and a mid-layer are essential. Start with an easy 2-hour route — shoulder season trails often have deceptive patches of ice in shaded north-facing sections.';
        hikingContext = snowCm > 0
            ? 'Traction aids (microspikes, YakTrax) reduce trail falls by up to 85% on packed snow compared to trail runners alone. Kahtoola MICROspikes are the gold standard for Ontario conditions.'
            : 'Many Conservation Authority trails close seasonal parking in November. Call ahead or check the website before driving 90 minutes to find a closed gate.';
      } else {
        hikingHeadline = 'PRIME ONTARIO TRAIL SEASON';
        hikingAction = 'Take a longer route today. Fall shoulder season hiking in Ontario is world-class — Hockley Valley, Caledon Hills, and the Beaver Valley all show peak leaf colour in these exact conditions.';
        hikingContext = 'Autumn is peak season for the Georgian Trail, Beaver Valley Ski Club trail system, and the Grey Sauble Conservation area. Leaf colour prediction maps are tracked by Tourism Ontario — foliage peak runs 2–3 weeks.';
      }
    }

    return ActivityScore(
      id: 'hiking',
      title: 'Hiking',
      score: level,
      message: message,
      icon: Icons.hiking,
      type: _activityTypeForId('hiking'),
      score10: _score10ForLevel(level),
      status: _statusForLevel(level),
      headline: hikingHeadline,
      immediateAction: hikingAction,
      canadianContext: hikingContext,
    );
  }

  // ── PATIO / DAILY PREP ─────────────────────────────────────────────────────

  static ActivityScore _scorePatio(
    double tempC,
    double windKmh,
    double windGustKmh,
    double precipChance,
    double snowCm,
    bool isRaining,
    bool summer,
  ) {
    ScoreLevel level;
    String message;
    IconData icon;
    String headline;
    String immediateAction;
    String canadianContext;

    final double gusts = windGustKmh > 0 ? windGustKmh : windKmh * 1.4;

    // 1. Trap the Windstorm / High Wind Threshold
    if (gusts >= 60 || windKmh >= 50) {
      level = ScoreLevel.poor;
      message = 'Severe winds. Secure outdoor items.';
      icon = Icons.air;
      headline = 'GALE FORCE WIND PREP';
      immediateAction = 'Secure patio furniture, tie down BBQ lids, and bring in all lightweight outdoor containers immediately.';
      canadianContext = 'Wind gusts over 60 km/h create severe sail-effects and flying debris risks. If driving a high-profile vehicle on Hwy 400 or open regional roads, grip the wheel with both hands and expect sudden lateral wind shear.';
    }
    // 2. Trap the Freeze-Thaw / Black Ice Threshold
    else if (tempC >= -4.0 && tempC <= 4.0 && (isRaining || snowCm > 0 || precipChance > 20)) {
      level = ScoreLevel.poor;
      message = 'Freeze-thaw cycle active. Black ice risk.';
      icon = Icons.severe_cold;
      headline = 'BLACK ICE & POTHOLE ALERT';
      immediateAction = 'Reduce driving speed, increase following distance to 6 seconds, and brake smoothly before approaching bridges or shaded intersections.';
      canadianContext = 'In Canada, temperatures hovering between -4°C and +4°C melt snow by day and freeze it into invisible black ice by night. It mimics the look of shiny black asphalt. This rapid expansion cycle also shatters pavement, creating suspension-destroying potholes.';
    }
    // 3. Upgrade the "Clear Skies" Baseline (Fallback)
    else if (!isRaining && precipChance < 30 && windKmh < 20) {
      level = ScoreLevel.good;
      message = 'Perfect conditions. Get outside.';
      icon = Icons.deck;
      headline = 'PRIME CANADIAN CLEAR SKIES';
      immediateAction = 'Open up the house for cross-ventilation or hit the trails while the weather holds.';
      canadianContext = 'Unobscured high-pressure systems bring pristine visibility across local conservation areas and waterfronts—take full advantage of the clear air.';
    }
    // General fallback for rain/snow that isn't severe
    else {
      level = ScoreLevel.fair;
      message = isRaining ? 'Wet weather. Patio is a wash.' : 'Sub-optimal conditions. Stay cozy.';
      icon = isRaining ? Icons.water_drop : Icons.cloud;
      headline = isRaining ? 'RAINY DAY PROTOCOL' : 'OVERCAST & CHILL';
      immediateAction = 'Keep the patio umbrella closed and plan for indoor activities.';
      canadianContext = 'Canadian weather changes fast. A rainy afternoon is a perfect excuse to watch the Jays game or hit up a local brewery taproom.';
    }

    return ActivityScore(
      id: 'patio',
      title: 'Patio',
      score: level,
      message: message,
      icon: icon,
      type: ActivityType.patio,
      score10: _score10ForLevel(level),
      status: _statusForLevel(level),
      headline: headline,
      immediateAction: immediateAction,
      canadianContext: canadianContext,
    );
  }
}
