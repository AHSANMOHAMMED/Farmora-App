import 'package:flutter/material.dart';

class AppColors {
  // ── Primary ──────────────────────────────────────────
  static const Color primary = Color(0xff1f7a4d);
  static const Color primaryLight = Color(0xffdcefe2);
  static const Color primaryContainer = Color(0xffe4f3e8);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xff1f7a4d);

  // ── Surface ──────────────────────────────────────────
  static const Color surface = Color(0xfff7faf7);
  static const Color onSurface = Color(0xff1a1c1e);
  static const Color onSurfaceVariant = Color(0xff44474e);
  static const Color surfaceContainer = Color(0xffe7e8ec);
  static const Color surfaceContainerLow = Color(0xfff1f1f4);
  static const Color surfaceContainerHigh = Color(0xffdcdce0);
  static const Color surfaceContainerLowest = Color(0xffffffff);

  // ── Secondary ────────────────────────────────────────
  static const Color secondary = Color(0xff545f70);
  static const Color secondaryContainer = Color(0xffd8e3f8);
  static const Color onSecondaryContainer = Color(0xff111c2b);

  // ── Tertiary ─────────────────────────────────────────
  static const Color tertiary = Color(0xff6e5676);
  static const Color onTertiary = Colors.white;

  // ── Error ────────────────────────────────────────────
  static const Color error = Color(0xffba1a1a);
  static const Color errorContainer = Color(0xffffdad6);
  static const Color onErrorContainer = Color(0xff410002);

  // ── Outline ──────────────────────────────────────────
  static const Color outline = Color(0xff74777f);
  static const Color outlineVariant = Color(0xffc4c6d0);

  // ── Background ───────────────────────────────────────
  static const Color background = Color(0xfff7faf7);
  static const Color cardBackground = Colors.white;
  static const Color inverseSurface = Color(0xff2f3033);
  static const Color inverseOnSurface = Color(0xfff1f0f4);
  static const Color primaryFixed = Color(0xffa6f2bd);

  // ── Text ─────────────────────────────────────────────
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black45;

  // ── Status: Active ───────────────────────────────────
  static const Color statusActiveBg = Color(0xffdcefe2);
  static const Color statusActiveText = Color(0xff1f7a4d);

  // ── Status: Pending ──────────────────────────────────
  static const Color statusPendingBg = Color(0xfffff0c2);
  static const Color statusPendingText = Color(0xffe67e22);

  // ── Status: Approved ─────────────────────────────────
  static const Color statusApprovedBg = Color(0xffdcefe2);
  static const Color statusApprovedText = Color(0xff1f7a4d);

  // ── Status: Rejected ─────────────────────────────────
  static const Color statusRejectedBg = Color(0xffffdad6);
  static const Color statusRejectedText = Color(0xffba1a1a);

  // ── Status: Empty ────────────────────────────────────
  static const Color statusEmptyBg = Color(0xfff1f1f4);
  static const Color statusEmptyText = Color(0xff74777f);

  // ── Legacy (backward compat) ─────────────────────────
  static const Color statusInTransit = Color(0xff3478c5);
  static const Color statusDelivered = Color(0xff1f7a4d);
  static const Color statusPending = Color(0xffe67e22);
}
