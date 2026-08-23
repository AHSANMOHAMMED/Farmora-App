import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order.dart';
import '../../../core/models/user_role.dart';
import '../../../core/repositories/order_repository.dart';
import '../../auth/providers/auth_provider.dart';

final userOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(orderRepositoryProvider);

  if (user == null) return [];

  if (user.role == Role.farmer) {
    return repository.getFarmerOrders(user.id);
  } else if (user.role == Role.buyer) {
    return repository.getBuyerOrders(user.id);
  } else {
    // For transporter, return all assigned/available orders
    return [];
  }
});
