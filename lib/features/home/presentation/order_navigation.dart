import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/order.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../buyer/presentation/buyer_order_detail_screen.dart';
import '../../farmer/presentation/order_detail_screen.dart';

/// Opens the order detail screen for the signed-in user's role (farmer or
/// buyer). Returns false when this role has no order detail screen.
bool openOrderDetail(BuildContext context, FarmoraOrder order) {
  final role = context.read<FarmoraState>().role;
  final Widget? screen = switch (role) {
    Role.farmer => OrderDetailScreen(order: order),
    Role.buyer => BuyerOrderDetailScreen(order: order),
    _ => null,
  };
  if (screen == null) return false;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  return true;
}
