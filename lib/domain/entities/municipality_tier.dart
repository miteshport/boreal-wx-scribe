/// municipality_tier.dart
///
/// Canadian Municipality Classification for the Windrow Alert Engine
/// ─────────────────────────────────────────────────────────────────────────
/// Encodes the three-tier municipal complexity model used by the
/// [CalculateWindrowAlert] use case to compute city-plow time offsets.
///
/// Tier Assignment Guidelines for UI (Settings → City Type):
///   METRO  → Population > 500,000 with dedicated city plow fleet.
///            Examples: Toronto, Montréal, Calgary, Ottawa, Edmonton,
///            Vancouver, Winnipeg, Québec City.
///   SUBURB → Population 50,000–500,000, shared/contract plow services.
///            Examples: Hamilton, London ON, Laval, Burnaby, Brampton,
///            Saskatoon, Regina, Kelowna.
///   RURAL  → Population < 50,000 or rural municipality. Minimal
///            dedicated plow infrastructure; regional county roads.
///            Examples: All rural municipalities, small towns, townships.

library municipality_tier;

/// Represents the operational complexity tier of a Canadian municipality,
/// used to calculate realistic plow-deployment time offsets after a storm.
enum MunicipalityTier {
  /// Tier 1: Large Canadian metropolitan area.
  /// Dedicated municipal plow fleet with high road-priority coverage.
  /// Typical residential windrow drop delay: 2 hours post-storm.
  metro,

  /// Tier 2: Mid-size Canadian city or suburban municipality.
  /// Mixed municipal + contracted plow services. Moderate coverage density.
  /// Typical residential windrow drop delay: 4 hours post-storm.
  suburb,

  /// Tier 3: Rural municipality or small town.
  /// Minimal dedicated infrastructure. Regional county roads prioritised.
  /// Typical residential windrow drop delay: 6 hours post-storm.
  rural;

  // ─────────────────────────────────────────────────────────────────────────
  // DISPLAY HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Human-readable tier label for display in the Settings page.
  String get displayName => switch (this) {
        MunicipalityTier.metro => 'Major City',
        MunicipalityTier.suburb => 'Mid-Size City / Suburb',
        MunicipalityTier.rural => 'Rural / Small Town',
      };

  /// Concise plow description shown in the WindrowAlertCard subtitle.
  String get plowDescription => switch (this) {
        MunicipalityTier.metro => 'Large municipal plow fleet',
        MunicipalityTier.suburb => 'Shared municipal + contracted plows',
        MunicipalityTier.rural => 'Regional county road service',
      };

  /// Short tier code used in logging and analytics events.
  String get analyticsCode => switch (this) {
        MunicipalityTier.metro => 'T1_METRO',
        MunicipalityTier.suburb => 'T2_SUBURB',
        MunicipalityTier.rural => 'T3_RURAL',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // FACTORY CONSTRUCTORS
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves a [MunicipalityTier] from a stored settings string key.
  /// Defaults to [MunicipalityTier.suburb] if the key is unrecognised,
  /// as it represents the most statistically common Canadian user profile.
  static MunicipalityTier fromStorageKey(String key) => switch (key) {
        'metro' => MunicipalityTier.metro,
        'suburb' => MunicipalityTier.suburb,
        'rural' => MunicipalityTier.rural,
        _ => MunicipalityTier.suburb, // Safe default
      };

  /// Serialisation key for [SharedPreferences] persistence.
  String get storageKey => name; // Uses enum name: 'metro', 'suburb', 'rural'
}
