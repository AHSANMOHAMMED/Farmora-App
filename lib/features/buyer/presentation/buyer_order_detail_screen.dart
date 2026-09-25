import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'track_order_screen.dart';
import 'barcode_scan_screen.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../../services/firebase_service.dart';
import '../../payments/presentation/order_payment_card.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import 'buyer_l10n.dart';

class BuyerOrderDetailScreen extends StatelessWidget {
  final FarmoraOrder order;

  const BuyerOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currentOrder = state.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );
    final linkedJob = state.jobs.where((j) => j.orderId == currentOrder.id).firstOrNull;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.buyerOrderDetailTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l.message,
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.onSurface),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConversationsScreen(orderId: order.id),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.buyerOrderNumber(currentOrder.orderNumber.toUpperCase()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.tertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(l, currentOrder.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMiniBadge(
                  currentOrder.paymentStatusLabel,
                  _paymentColor(currentOrder.paymentState),
                ),
                _buildMiniBadge(
                  _escrowLabel(l, currentOrder.escrowStatus),
                  AppColors.onSurfaceVariant,
                ),
                if (currentOrder.isDisputed)
                  _buildMiniBadge(l.buyerDisputedPayoutPaused, AppColors.error),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentOrder.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.buyerRequestedFor(currentOrder.requestedDate.isNotEmpty
                        ? currentOrder.requestedDate
                        : AppFormat.date(currentOrder.createdAt)),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Timeline
            _buildStatusTimeline(l, currentOrder),
            const SizedBox(height: 20),
            if (currentOrder.status.toLowerCase() != 'delivered')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(l.verifyHarvestBarcode),
                  onPressed: () async {
                    final result =
                        await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                          builder: (_) => const BarcodeScanScreen()),
                    );
                    if (context.mounted && result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l.harvestAuthenticityVerified)),
                      );
                    }
                  },
                ),
              ),
            if (currentOrder.status.toLowerCase() == 'delivered')
              _TrustActions(order: currentOrder),
            const SizedBox(height: 16),
            if (!currentOrder.isDeclined) ...[
              OrderPaymentCard(order: currentOrder, viewerIsFarmer: false),
              const SizedBox(height: 16),
            ],

            // Farmer Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.agriculture_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.buyerName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentOrder.buyerCompany,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      height: 1),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 22,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.buyerDeliveryAddress,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentOrder.deliveryAddress,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (currentOrder.status == 'pending')
                        IconButton(
                          tooltip: l.editDeliveryAddress,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _editDeliveryAddress(context, state, currentOrder),
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.buyerOrderSummary,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                      l.buyerProduct,
                      currentOrder.productName.isNotEmpty
                          ? currentOrder.productName
                          : currentOrder.title),
                  _buildDivider(),
                  _buildSummaryRow(l.quantity, currentOrder.quantity),
                  _buildDivider(),
                  _buildSummaryRow(l.buyerUnitPrice, currentOrder.unitPrice),
                  _buildDivider(),
                  _buildSummaryRow(l.buyerGrade, currentOrder.grade),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.commonTotal,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                        buyerOrderTotal(currentOrder),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (linkedJob != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l.buyerLogisticsTransport,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            statusLabel(linkedJob.status, l),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      l.buyerTransportProvider,
                      linkedJob.transporterId != null && linkedJob.transporterId!.isNotEmpty
                          ? l.buyerAssignedTo(linkedJob.transporterId!)
                          : l.buyerPendingAssignment,
                    ),
                    _buildDivider(),
                    _buildSummaryRow(l.buyerRoute, linkedJob.route),
                    _buildDivider(),
                    _buildSummaryRow(l.buyerFee, linkedJob.fee),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (() {
            final s = currentOrder.status.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
            final trackable = {'confirmed','assigned','pickedup','intransit','accepted'}.contains(s);
            return trackable
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(order: currentOrder),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  l.trackOrder,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          : currentOrder.isPending
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: OutlinedButton(
                    onPressed: () {
                      state.cancelOrder(currentOrder.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.orderCancelled)),
                      );
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l.buyerCancelOrderButton,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : null;
          })(),
    );
  }

  Widget _buildStatusTimeline(AppLocalizations l, FarmoraOrder order) {
    final steps = [
      l.buyerStepOrderPlaced,
      l.buyerStepAcceptedByFarmer,
      l.statusInTransit,
      l.statusDelivered,
    ];
    int currentStep;
    switch (order.status.toLowerCase()) {
      case 'accepted':
        currentStep = 1;
        break;
      case 'in transit':
        currentStep = 2;
        break;
      case 'delivered':
        currentStep = 3;
        break;
      default:
        currentStep = 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.buyerOrderStatus,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
            final isActive = index <= currentStep;
            final isCurrent = index == currentStep;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primaryFixed, width: 3)
                            : null,
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: index < currentStep
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.outlineVariant.withValues(alpha: 0.3),
      height: 1,
    );
  }

  Widget _buildStatusBadge(AppLocalizations l, String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'accepted':
        bgColor = AppColors.statusApprovedBg;
        textColor = AppColors.statusApprovedText;
        break;
      case 'delivered':
      case 'completed':
        bgColor = AppColors.statusApprovedBg;
        textColor = AppColors.statusApprovedText;
        break;
      case 'declined':
        bgColor = AppColors.statusRejectedBg;
        textColor = AppColors.statusRejectedText;
        break;
      default:
        bgColor = AppColors.statusPendingBg;
        textColor = AppColors.statusPendingText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        statusLabel(status, l),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: textColor,
        ),
      ),
    );
  }

  Color _paymentColor(PaymentState s) {
    switch (s) {
      case PaymentState.paid:
        return AppColors.statusApprovedText;
      case PaymentState.rejected:
      case PaymentState.disputed:
        return AppColors.error;
      default:
        return AppColors.statusPendingText;
    }
  }

  String _escrowLabel(AppLocalizations l, String s) {
    switch (s.toLowerCase()) {
      case 'funded_pending_delivery':
        return l.buyerEscrowFunded;
      case 'released':
        return l.buyerEscrowReleased;
      case 'held':
        return l.buyerEscrowProtected;
      default:
        return l.buyerEscrowStatus(statusLabel(s, l));
    }
  }

  Widget _buildMiniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _editDeliveryAddress(BuildContext context, FarmoraState state, FarmoraOrder order) {
    final controller = TextEditingController(text: order.deliveryAddress);
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editDeliveryAddress),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l.buyerEnterNewAddress,
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await state.updateOrderAddress(order.id, controller.text.trim());
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.addressUpdatedSuccessfully)),
                  );
                }
              }
            },
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
  }
}

class _TrustActions extends StatefulWidget {
  final FarmoraOrder order;

  const _TrustActions({required this.order});

  @override
  State<_TrustActions> createState() => _TrustActionsState();
}

class _TrustActionsState extends State<_TrustActions> {
  final _comment = TextEditingController();
  int _rating = 5;
  final _service = FirestoreService();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _review() async {
    if (!widget.order.canReview) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.buyerReviewOnlyAfterDelivery)));
      }
      return;
    }
    if (_comment.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.buyerWriteReviewFirst)));
      }
      return;
    }
    try {
      await _service.submitReview(
        orderId: widget.order.id,
        rating: _rating,
        comment: _comment.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.buyerReviewSubmittedModeration)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.reviewSubmitFailed(
                userMessage(e, action: 'submit review')))));
      }
    }
  }

  Future<void> _dispute() async {
    final reason = _comment.text.trim();
    if (reason.isEmpty) return;
    await _service.openDispute(orderId: widget.order.id, reason: reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.buyerComplaintOpened)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.buyerTrustAndSupport,
            style: Theme.of(context).textTheme.titleMedium),
        if (!widget.order.canReview)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(l.buyerReviewsUnlockHint,
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _rating,
          items: [1, 2, 3, 4, 5]
              .map((value) =>
                  DropdownMenuItem(value: value, child: Text(l.buyerStarsCount(value))))
              .toList(),
          onChanged: (value) => setState(() => _rating = value ?? 5),
          decoration: InputDecoration(labelText: l.buyerProductRating),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          maxLength: 2000,
          maxLines: 3,
          decoration:
              InputDecoration(labelText: l.buyerReviewOrComplaintDetails),
        ),
        Row(
          children: [
            Expanded(
                child: FilledButton(
                    onPressed: _review, child: Text(l.submitReview))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: _dispute, child: Text(l.openComplaint))),
          ],
        ),
      ],
    );
  }
}
