import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/farm_input.dart';
import '../../../services/farm_records_service.dart';
import '../../../services/input_market_service.dart';
import 'inputs_l10n.dart';

/// Farmer: their input purchases and machinery bookings.
class MyInputOrdersScreen extends StatefulWidget {
  const MyInputOrdersScreen({super.key});

  @override
  State<MyInputOrdersScreen> createState() => _MyInputOrdersScreenState();
}

class _MyInputOrdersScreenState extends State<MyInputOrdersScreen> {
  final _service = InputMarketService();
  late final _stream = _service.farmerOrders();

  final _records = FarmRecordsService();

  /// Books a delivered purchase / finished rental as a farm expense.
  Future<void> _addExpense(InputOrder o) async {
    final l = context.l10n;
    try {
      if (!await _records.hasEntryFor(o.id)) {
        await _records.addEntry(
          isExpense: true,
          category: switch (o.category) {
            InputCategory.seeds => 'seed',
            InputCategory.fertilizer => 'fertilizer',
            InputCategory.pesticide => 'pesticide',
            InputCategory.machinery => 'machinery',
            InputCategory.tools => o.isRental ? 'machinery' : 'other',
          },
          amountMinor: o.totalMinor,
          date: DateTime.now(),
          note: o.inputName,
          sourceId: o.id,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.farmAddedToExpenses)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'add the expense')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _cancel(InputOrder o) async {
    try {
      await _service.transition(o, InputOrderStatus.cancelled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(userMessage(e, action: 'cancel the order')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.inpMyOrders)),
      body: StreamBuilder<List<InputOrder>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) return Center(child: Text(l.inpNoOrders));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => InputOrderCard(
              order: orders[i],
              subtitle: l.inpBy(orders[i].supplierName),
              actions: [
                if (orders[i].status == InputOrderStatus.pending)
                  TextButton(
                    onPressed: () => _cancel(orders[i]),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                    child: Text(l.inpCancelOrder),
                  ),
                if (orders[i].status == InputOrderStatus.delivered ||
                    orders[i].status == InputOrderStatus.returned)
                  TextButton.icon(
                    onPressed: () => _addExpense(orders[i]),
                    icon: const Icon(Icons.account_balance_wallet_outlined,
                        size: 18),
                    label: Text(l.farmAddToExpenses),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Order summary card shared by the farmer and supplier order lists.
class InputOrderCard extends StatelessWidget {
  const InputOrderCard({
    super.key,
    required this.order,
    required this.subtitle,
    this.actions = const [],
  });

  final InputOrder order;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final qty = order.isRental
        ? '${order.quantity} × ${l.inpRentalFor('${order.days ?? 1}', order.startDate == null ? '' : AppFormat.date(order.startDate!))}'
        : '${order.quantity} ${order.unit}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.inputName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              InputStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(qty),
          Text(AppFormat.lkr(order.total),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          if (order.paid || order.payLater)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                order.paid
                    ? l.inpPaid
                    : order.overdue
                        ? l.inpOverdue
                        : l.inpDueBy(order.dueAt == null
                            ? ''
                            : AppFormat.date(order.dueAt!)),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: order.paid
                      ? AppColors.primary
                      : order.overdue
                          ? AppColors.error
                          : const Color(0xFFE65100),
                ),
              ),
            ),
          Text(order.deliveryAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          if (actions.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: actions,
            ),
        ],
      ),
    );
  }
}
