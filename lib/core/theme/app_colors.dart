import 'package:flutter/material.dart';

/// RepCommit brand color system.
///
/// Derived from the prototype's CSS custom properties.
/// The palette is intentionally restrained: graphite background,
/// bone/off-white text, signal orange for primary actions,
/// and pale mint for positive data indicators.
abstract final class AppColors {
  // ── Text hierarchy ──────────────────────────────────────────────
  /// Primary text — bone/off-white.
  static const Color ink = Color(0xFFECE9E0);

  /// Secondary text — muted warm grey.
  static const Color inkDim = Color(0xFFA5A49D);

  /// Tertiary text — metadata, kickers, timestamps.
  static const Color inkFaint = Color(0xFF6E706C);

  // ── Surfaces ────────────────────────────────────────────────────
  /// App background — graphite/near-black.
  static const Color bg = Color(0xFF0D0F0F);

  /// Card/panel surface.
  static const Color panel = Color(0xFF121514);

  /// Elevated surface.
  static const Color panel2 = Color(0xFF171A18);

  /// Highest elevation surface.
  static const Color panel3 = Color(0xFF1D211E);

  // ── Dividers ────────────────────────────────────────────────────
  /// Standard divider/border.
  static const Color line = Color(0xFF2A2E2B);

  /// Stronger divider for section boundaries.
  static const Color lineStrong = Color(0xFF3A403B);

  // ── Brand accents ───────────────────────────────────────────────
  /// Signature signal orange/red — primary CTA, brand identity.
  static const Color signal = Color(0xFFF05A3A);

  /// Dark variant of signal — used for subtle backgrounds.
  static const Color signalDark = Color(0xFF6F251B);

  /// Pale mint — positive data, success indicators.
  static const Color mint = Color(0xFF9BC9B5);

  /// Warm warning tone — urgency only.
  static const Color warning = Color(0xFFE4A35A);

  /// Danger red.
  static const Color danger = Color(0xFFC95C5C);

  // ── Light surfaces (used in logger sheet) ───────────────────────
  /// Light background — paper/bone for modal sheets.
  static const Color paper = Color(0xFFF1EEE6);

  /// Dark text on light surfaces.
  static const Color black = Color(0xFF11120F);

  // ── Heatmap levels ──────────────────────────────────────────────
  /// Empty cell — no activity.
  static const Color heatEmpty = Color(0xFF1C201D);

  /// Level 1 — light activity.
  static const Color heatL1 = Color(0xFF304238);

  /// Level 2 — medium activity.
  static const Color heatL2 = Color(0xFF4F695B);

  /// Level 3 — strong activity.
  static const Color heatL3 = Color(0xFF7EA68E);

  /// Level 4 — very strong activity (same as mint).
  static const Color heatL4 = mint;

  /// Future cell background.
  static const Color heatFuture = Color(0xFF151817);

  /// Future cell border.
  static const Color heatFutureBorder = Color(0xFF222622);

  // ── Helpers ─────────────────────────────────────────────────────

  /// Returns the heatmap color for a given intensity level (0–4).
  static Color heatLevel(int level) {
    return switch (level) {
      1 => heatL1,
      2 => heatL2,
      3 => heatL3,
      4 => heatL4,
      _ => heatEmpty,
    };
  }
}
