import 'package:weather_sync_ca/domain/usecases/activity_scoring_engine.dart';

enum WeatherProfileId {
  galeWindstorm,
  shoulderFreezeThaw,
  wildfireSmokeHigh,
  deepWinterBlizzard,
  extremeHeatHumidex,
  heavyRainDownpour,
  primeSummerClear,
  clearNightStarry,
}

class WeatherProfile {
  final WeatherProfileId id;
  final String headline;
  final String immediateAction;
  final String canadianContext;
  
  final ScoreLevel dailyRunningScoreLevel;
  final String dailyRunningScoreMessage;
  
  final ScoreLevel dailyPatioScoreLevel;
  final String dailyPatioScoreMessage;
  
  final int escapePatioIndex;
  final String escapePatioMessage;
  
  final String escapeHighwayStatus;
  final String escapeCampfireStatus;

  const WeatherProfile({
    required this.id,
    required this.headline,
    required this.immediateAction,
    required this.canadianContext,
    required this.dailyRunningScoreLevel,
    required this.dailyRunningScoreMessage,
    required this.dailyPatioScoreLevel,
    required this.dailyPatioScoreMessage,
    required this.escapePatioIndex,
    required this.escapePatioMessage,
    required this.escapeHighwayStatus,
    required this.escapeCampfireStatus,
  });

  bool get isExtremeHazard => id != WeatherProfileId.primeSummerClear;
}

class WeatherStateMatrix {
  static const WeatherProfile galeWindstorm = WeatherProfile(
    id: WeatherProfileId.galeWindstorm,
    headline: 'GALE FORCE WIND PREP',
    immediateAction: 'Secure patio furniture, tie down BBQ lids, and bring in all lightweight outdoor containers immediately.',
    canadianContext: 'Gale warnings (62–87 km/h) create severe sail-effects and flying debris risks. If driving a high-profile vehicle on Hwy 400 or open regional roads, grip the wheel with both hands to counter lateral wind shear.',
    dailyRunningScoreLevel: ScoreLevel.poor,
    dailyRunningScoreMessage: 'High wind resistance and falling branch hazards. Treadmill recommended.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Gale force winds. Secure outdoor setups.',
    escapePatioIndex: 1,
    escapePatioMessage: 'Stay inside. High wind shear active.',
    escapeHighwayStatus: 'LATERAL WIND SHEAR — Reduce speed on open regional routes and Hwy 400.',
    escapeCampfireStatus: '🚨 HAZARDOUS / NO FIRES — Extreme spark-spread risk. Open fires strictly dangerous.',
  );

  static const WeatherProfile shoulderFreezeThaw = WeatherProfile(
    id: WeatherProfileId.shoulderFreezeThaw,
    headline: 'BLACK ICE & POTHOLE ALERT',
    immediateAction: 'Reduce driving speed, increase following distance to 6 seconds, and brake smoothly before approaching bridges or shaded intersections.',
    canadianContext: 'In Canada, temperatures hovering between -4°C and +4°C melt snow by day and freeze it into invisible black ice by night. It mimics the look of shiny black asphalt. Warn pedestrians about melting snow refreezing into invisible "black ice" overnight; recommend penguin-walking and doubling vehicle following distances.',
    dailyRunningScoreLevel: ScoreLevel.fair,
    dailyRunningScoreMessage: 'Slush and black ice patches. Wear trail spikes or high-grip footwear.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Freeze-thaw cycle active. Outdoor surfaces icy.',
    escapePatioIndex: 2,
    escapePatioMessage: 'Cold slush and damp air. Indoor dining weather.',
    escapeHighwayStatus: 'BLACK ICE TRACKING — Severe freezing risks on overpasses and shaded highway bends.',
    escapeCampfireStatus: 'SUB-OPTIMAL — Damp ground, melting snow, and poor wood ignition.',
  );

  static const WeatherProfile wildfireSmokeHigh = WeatherProfile(
    id: WeatherProfileId.wildfireSmokeHigh,
    headline: '⚠️ WILDFIRE SMOKE PLUME',
    immediateAction: 'Close all windows immediately, set HVAC to recirculation mode, and run indoor HEPA air purifiers.',
    canadianContext: 'An Air Quality Health Index (AQHI) of 7 to 10 indicates high health risks from fine particulate matter (PM2.5). These microscopic smoke particles bypass lung defenses and enter the bloodstream. Outdoor physical exertion must be minimized.',
    dailyRunningScoreLevel: ScoreLevel.poor,
    dailyRunningScoreMessage: 'Air quality hazardous due to wildfire smoke. Move cardio indoors.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Smoke drift detected. Keep air sealed indoors.',
    escapePatioIndex: 1,
    escapePatioMessage: 'Hazardous air quality. Outdoor dining strongly discouraged.',
    escapeHighwayStatus: 'REDUCED VISIBILITY — Wildfire smoke haze tracking across regional transport corridors.',
    escapeCampfireStatus: '🚨 AIR QUALITY BAN — Do not add wood smoke to already hazardous atmospheric levels.',
  );

  static const WeatherProfile deepWinterBlizzard = WeatherProfile(
    id: WeatherProfileId.deepWinterBlizzard,
    headline: 'DEEP WINTER SURVIVAL',
    immediateAction: 'Plug in vehicle block heaters 3 hours before ignition, apply pet-friendly ice melt to walkways, and dress in windproof thermal layers.',
    canadianContext: 'Severe sub-zero temperatures rapidly reduce car battery cranking power and freeze exposed skin within minutes. Engine oil thickens at sub-zero; plug in your block heater to prevent battery/starter failure. Always keep a winter survival kit in your trunk.',
    dailyRunningScoreLevel: ScoreLevel.poor,
    dailyRunningScoreMessage: 'Extreme cold and snow accumulation. Indoor training advised.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Deep winter freeze. Outdoor season suspended.',
    escapePatioIndex: 1,
    escapePatioMessage: 'Sub-zero conditions. Cabin woodstove weather.',
    escapeHighwayStatus: 'SQUALL WARNING — Heavy snow and sudden whiteout conditions along traditional lake-effect snow belts.',
    escapeCampfireStatus: 'WINTERIZED — Open-air fire season closed unless operating a dedicated winter shelter pit.',
  );

  static const WeatherProfile extremeHeatHumidex = WeatherProfile(
    id: WeatherProfileId.extremeHeatHumidex,
    headline: 'EXTREME HUMIDEX VAULT',
    immediateAction: 'Close south-facing blinds and seal windows by 10:00 AM to block peak solar heat gain and reduce daytime A/C electricity costs. Flush house with 16°C outdoor air until 9:30 AM.',
    canadianContext: 'Great Lake humidity makes 28°C feel like 38°C. Seek public cooling centers or libraries if uncooling systems fail.',
    dailyRunningScoreLevel: ScoreLevel.poor,
    dailyRunningScoreMessage: 'High humidex. Heatstroke risk. Run before sunrise or indoors.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Extreme heat vault. Seek air conditioning.',
    escapePatioIndex: 2,
    escapePatioMessage: 'Keep your stick on the ice, grab a double-double, but stay in the AC today. Extreme heat.',
    escapeHighwayStatus: 'CLEAR DRIVE — Asphalt surface temperatures extreme. Check tire pressure.',
    escapeCampfireStatus: 'BAN WARNING — Extreme heat dries out brush rapidly. Check local municipal fire bans before lighting.',
  );

  static const WeatherProfile heavyRainDownpour = WeatherProfile(
    id: WeatherProfileId.heavyRainDownpour,
    headline: 'HEAVY RAIN WARNING',
    immediateAction: 'It\'s a real frog-strangler out there, eh? Keep the boots handy and avoid the low-lying underpasses during the commute.',
    canadianContext: 'Heavy rainfall can lead to localized flash flooding. Ensure your sump pump is active and clear out eavestroughs.',
    dailyRunningScoreLevel: ScoreLevel.poor,
    dailyRunningScoreMessage: 'Heavy downpour. Treadmill recommended.',
    dailyPatioScoreLevel: ScoreLevel.poor,
    dailyPatioScoreMessage: 'Washout. Move the BBQ under the awning or stay indoors.',
    escapePatioIndex: 1,
    escapePatioMessage: 'Total washout. Stay dry inside.',
    escapeHighwayStatus: 'HYDROPLANE RISK — Standing water on major routes. Reduce speed.',
    escapeCampfireStatus: 'WASHOUT — Wet fuels and heavy rain prevent fire ignition.',
  );

  static const WeatherProfile primeSummerClear = WeatherProfile(
    id: WeatherProfileId.primeSummerClear,
    headline: 'PRIME CANADIAN CLEAR SKIES',
    immediateAction: 'Open windows for early morning cross-ventilation or hit the trails while humidity remains manageable.',
    canadianContext: 'Unobscured high-pressure systems bring pristine visibility and optimal outdoor conditions across local conservation areas and waterfronts—take full advantage of the clear air.',
    dailyRunningScoreLevel: ScoreLevel.good,
    dailyRunningScoreMessage: 'Optimal running conditions — cool breeze, dry ground. Set a PR.',
    dailyPatioScoreLevel: ScoreLevel.good,
    dailyPatioScoreMessage: 'Perfect conditions. Get outside.',
    escapePatioIndex: 10,
    escapePatioMessage: 'Wind is dead calm and clear. Perfect backyard BBQ or patio conditions tonight. Two-four time, bud.',
    escapeHighwayStatus: 'CLEAR DRIVE — No heavy rain or severe wind gusts expected on major routes. Good conditions for travel.',
    escapeCampfireStatus: 'CLEAR OUTDOOR CONDITIONS — Low bug activity and no fire ban risk. Ideal conditions for evening campfires or trail walks.',
  );

  static const WeatherProfile clearNightStarry = WeatherProfile(
    id: WeatherProfileId.clearNightStarry,
    headline: 'STARRY NIGHT / CLEAR SKY',
    immediateAction: 'Stargazing conditions are optimal. Bundle up and watch for the shooting star.',
    canadianContext: 'Crisp, unpolluted Canadian night skies offer some of the best stargazing in the northern hemisphere. Perfect visibility tonight.',
    dailyRunningScoreLevel: ScoreLevel.good,
    dailyRunningScoreMessage: 'Clear, crisp night air. Excellent for a night run with reflective gear.',
    dailyPatioScoreLevel: ScoreLevel.fair,
    dailyPatioScoreMessage: 'Clear night, but cooling down. Firepit recommended.',
    escapePatioIndex: 8,
    escapePatioMessage: 'Perfect campfire weather under the stars.',
    escapeHighwayStatus: 'CLEAR DRIVE — Excellent visibility. Watch for wildlife.',
    escapeCampfireStatus: 'IDEAL CONDITIONS — Clear night sky, low wind. Enjoy the fire.',
  );

  /// Resolves the current weather profile based on live data and active simulation modes.
  static WeatherProfile resolveCurrentProfile(
    String simulationId, {
    required double windGustKmh,
    required double windKmh,
    required double aqhi,
    required double tempC,
    required double apparentTempC,
    required bool precip,
    required double snowCm,
  }) {
    // 1. Simulation Overrides
    if (simulationId == 'WINDSTORM') return galeWindstorm;
    if (simulationId == 'SMOKE') return wildfireSmokeHigh;
    if (simulationId == 'SLUSH' || simulationId == 'FREEZE-THAW') return shoulderFreezeThaw;
    if (simulationId == 'SNOW' || simulationId == 'WINTER') return deepWinterBlizzard;
    if (simulationId == 'HEAT' || simulationId == 'EXTREME-HEAT') return extremeHeatHumidex;
    if (simulationId == 'NIGHT' || simulationId == 'CLEAR-NIGHT') return clearNightStarry;
    if (simulationId == 'RAIN' || simulationId == 'HEAVY-RAIN') {
      if (tempC >= -4.0 && tempC <= 4.0) return shoulderFreezeThaw;
      return heavyRainDownpour;
    }

    // 2. Live Threshold Checks in Priority Order
    if (windGustKmh >= 62.0 || windKmh >= 50.0) {
      return galeWindstorm;
    } else if (aqhi >= 7.0) {
      return wildfireSmokeHigh;
    } else if (apparentTempC >= 35.0) {
      return extremeHeatHumidex;
    } else if (tempC >= -4.0 && tempC <= 4.0 && (precip || snowCm > 0)) {
      return shoulderFreezeThaw;
    } else if (tempC <= -15.0 || snowCm >= 5.0) { // Changed tempC to -15.0 per the prompt context
      return deepWinterBlizzard;
    } else if (precip && tempC > 4.0) {
      return heavyRainDownpour;
    } else {
      return primeSummerClear;
    }
  }
}
