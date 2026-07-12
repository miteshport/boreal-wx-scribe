# AGENTS.MD — IMMUTABLE PROJECT CONSTITUTION & DESIGN LAWS

> **This document is the supreme authority for all AI developer agents operating in this codebase.**
> Rules are non-negotiable. Any violation is strictly prohibited and must be immediately reverted.

---

## 1. THE IMMUTABLE BACKEND RULE

### Scope of Protection
The following files and directories are **READ-ONLY** during any frontend, layout, or UI refactor task:

| Protected Layer | Files |
|---|---|
| Domain Logic | `lib/domain/matrix/weather_state_matrix.dart` |
| Scoring Engines | `lib/domain/usecases/activity_scoring_engine.dart` |
| Advice Engine | `lib/domain/usecases/canadian_advice_engine.dart` |
| Weekly Engine | `lib/domain/usecases/weekly_forecasting_engine.dart` |
| API Parsers | `lib/services/live_weather_service.dart` |
| Air Quality | `lib/services/air_quality_service.dart` |
| Data Models | All `DailyForecast`, `LiveWeatherData`, `HourlyForecast`, `WeatherProfile`, `ActivityScore` classes |

### The Law
- **Never Modify Domain Logic During UI Refactors.** When executing frontend layout updates, these files must not be edited.
- **Consume, Do Not Alter.** UI components must strictly consume the existing `WeatherProfile` and `LiveWeatherData` streams without touching their underlying data pipelines.
- **Backend changes require explicit user approval** in a dedicated architecture spec before any edits are made.

---

## 2. BENTO BOX GRID & LAYOUT DISCIPLINE

### Fixed Bounding Boxes
- All dashboard cards must operate within a strict **Bento Grid system** using fixed aspect ratios or **capped height constraints**.
- Cards must **NEVER** expand or contract based on varying text lengths.
- Use `SizedBox`, `ConstrainedBox`, or `AspectRatio` wrappers to enforce immutable card dimensions.

### Text Handling
- If a string exceeds the card bounds, it must cleanly truncate with an ellipsis (`...`):
  ```dart
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  ```
- Alternatively, use `FittedBox` or `AutoSizeText` to dynamically scale typography down within bounds.
- **Zero layout shifting allowed** — no card may reflow or resize based on runtime content.

### Visual Identity Standards
Every grid card must enforce:

| Property | Value |
|---|---|
| Border | `2px solid Color(0xFF0A0A0A)` |
| Corner radius | `0` — sharp 90° corners only |
| Drop shadow | Hard drop-shadow (offset, no blur) |
| Background | `Color(0xFF111111)` (card) or `Color(0xFF0A0A0A)` (page) |

---

## 3. ABSOLUTE BRAND IDENTITY — THE SOLAR-YELLOW RULE

### Modal / Bottom Sheet Law
Every expanded bottom sheet (Canadian Survival Guide, Day Detail, Survival Sheets) **must** be hardcoded as follows. No exceptions.

```dart
showModalBottomSheet(
  backgroundColor: const Color(0xFFD4FF00),  // ← ABSOLUTE. NEVER CHANGE.
  ...
)
```

Inside every sheet:
- All body text: `const Color(0xFF0A0A0A)`
- All dividers: `const Color(0xFF1A1A00)`
- Section labels: `Color(0xFF0A0A0A).withValues(alpha: 0.55)`

### Zero Fallbacks
- **No conditional styling** inside modal sheets.
- **No dark-mode overrides** — the Solar-Yellow sheet is identity-defining, not theme-responsive.
- **No black fallbacks** under any `if/else`, ternary, or `ThemeData` resolver inside a sheet builder.

### Brand Accent Colors (Approved Palette)
| Token | Hex | Usage |
|---|---|---|
| Solar Yellow | `0xFFD4FF00` | Sheet backgrounds, Prime Day badge, key accent |
| Electric Green | `0xFF00FF87` | Positive/clear status tags |
| Neon Yellow | `0xFFE6FF00` | Secondary accent (caution/good) |
| Alert Red | `0xFFFF3B30` | Hazard tags, danger states |
| Amber | `0xFFFF9F0A` | Moderate risk tags |
| Pure White | `0xFFFFFFFF` | Primary text on dark backgrounds |
| Concrete Grey | `0xFF7F7F7F` | Secondary text, subtitles |
| Deep Black | `0xFF0A0A0A` | Page background, borders, sheet text |

---

## 4. PARALLEL SANDBOX DEVELOPMENT

### The Non-Destructive Build Rule
- **Never overwrite legacy views** when building new layout architecture.
- New architectural work must be created as **new files** alongside existing implementations. Examples:
  - `today_tab_view.dart` (not overwriting `summer_dashboard_page.dart`)
  - `getaway_tab_view.dart` (not overwriting `escape_dashboard_view.dart`)
  - `sun_flip_card.dart` (not replacing existing activity cards)
- **Legacy pages must not be deleted** until explicit user sign-off is granted in a dedicated approval message.
- This enables safe A/B comparison and instant rollback without data loss.

---

## 5. ANALYSIS & CODE QUALITY GATE

Before any pull request or feature completion is declared:

1. Run `dart analyze lib` — **zero errors** required before sign-off.
2. Warnings in new files must be resolved. Pre-existing warnings in legacy files do not block, but must be logged.
3. All new `Color` values must use `.withValues(alpha: x)` — **never `.withOpacity()`**.
4. All new layout constraints must be tested at the minimum supported screen width (360dp).

---

## 6. ENFORCEMENT

Any AI agent that violates Rules 1–4 must:
1. Immediately revert the non-compliant change.
2. Re-read this document before continuing.
3. Declare the violation in its response before resuming work.

*Last updated: 2026-07-08 by project architect.*
