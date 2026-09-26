import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_navigator.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';

/// Opens the order detail screen for the signed-in user's role (farmer or
/// buyer). Returns false when this role has no order detail screen.
///
/// Thin wrapper kept so existing callers don't need to touch FarmoraState
/// themselves; the actual role -> screen mapping lives in AppNavigator so
/// every deep-navigation destination is declared in one place.
bool openOrderDetail(BuildContext context, FarmoraOrder order) {
  final role = context.read<FarmoraState>().role;
  return AppNavigator.openOrderDetail(context, order, role);
}
