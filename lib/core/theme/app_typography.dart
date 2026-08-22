import 'package:flutter/material.dart';

/// RepCommit typography system.
///
/// Three type families mirroring the prototype:
/// - **display**: Condensed, high-impact — large numbers, titles.
/// - **sans**: System sans-serif — body text, descriptions.
/// - **mono**: Monospace — kickers, metadata, timestamps.
abstract final class AppTypography {
  // ── Font families ───────────────────────────────────────────────
  static const String _displayFamily = 'Arial Narrow';
  static const String _monoFamily = 'RobotoMono';

  // ── Display styles (condensed, for large numbers & headings) ───
  static const TextStyle displayHero = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 70,
    fontWeight: FontWeight.w900,
    height: 0.75,
    letterSpacing: -5.25,
  );

  static const TextStyle displayXL = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    height: 0.85,
    letterSpacing: -3.6,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 34,
    fontWeight: FontWeight.w900,
    height: 0.95,
    letterSpacing: -1.7,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 0.95,
    letterSpacing: -1.4,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 0.95,
    letterSpacing: -1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.7,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -0.4,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 14,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -0.28,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.26,
  );

  static const TextStyle statLarge = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 21,
    fontWeight: FontWeight.w900,
    height: 0.9,
    letterSpacing: -0.84,
  );

  static const TextStyle statMedium = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 0.9,
    letterSpacing: -0.32,
  );

  // ── Sans styles (system, for body text) ─────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodyTiny = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  // ── Mono styles (metadata, kickers, labels) ─────────────────────
  static const TextStyle kicker = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    height: 1.2,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    height: 1.2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle monoTiny = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    height: 1.2,
  );

  // ── Wordmark ────────────────────────────────────────────────────
  static const TextStyle wordmark = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: -1.0,
  );

  // ── Counter (push logger) ───────────────────────────────────────
  static const TextStyle counter = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 62,
    fontWeight: FontWeight.w900,
    height: 0.8,
    letterSpacing: -4.96,
  );

  // ── Nav label ───────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    height: 1.0,
  );
}
