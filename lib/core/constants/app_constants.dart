/// Spacing and layout constants for RepCommit.
///
/// Keeps magic numbers out of widget code. Values are derived from
/// the prototype's CSS padding/margin/gap values.
abstract final class AppConstants {
  // ── Spacing ─────────────────────────────────────────────────────
  static const double pagePadding = 15.0;
  static const double contentGap = 13.0;
  static const double sectionGap = 13.0;

  // ── Heatmap geometry ────────────────────────────────────────────
  static const double heatCellSize = 10.0;
  static const double heatCellGap = 3.0;
  static const int heatRowCount = 7;

  // ── Squad field geometry ────────────────────────────────────────
  static const double squadCellSize = 9.0;
  static const double squadCellGap = 3.0;

  // ── Navigation ──────────────────────────────────────────────────
  static const double navHeight = 60.0;
  static const double navMargin = 10.0;

  // ── Sheet / modal ───────────────────────────────────────────────
  static const double sheetPadding = 15.0;

  // ── Target defaults ─────────────────────────────────────────────
  static const int defaultDailyTarget = 60;
  static const int defaultWeeklyTarget = 420;

  // ── Counter defaults ────────────────────────────────────────────
  static const int counterDefault = 20;
  static const int counterStep = 5;
  static const int counterMin = 5;

  // ── Quick values for logger ─────────────────────────────────────
  static const List<int> quickValues = [10, 20, 30, 50];

  // ── Forecast parameters ─────────────────────────────────────────
  static const int forecastWindowDays = 28;
  static const double forecastRecentWeight = 0.62;
  static const double forecastBaseWeight = 0.38;

  // ── Comeback threshold ──────────────────────────────────────────
  static const int comebackThresholdDays = 3;

  // ── Consistency ─────────────────────────────────────────────────
  static const int consistencyWindowDays = 7;

  // ── Username ────────────────────────────────────────────────────
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 24;
  static const String usernamePattern = r'^[a-z0-9_]+$';

  // ── Demo data ───────────────────────────────────────────────────
  static const bool isDemoMode = true; // Toggle for development
}
