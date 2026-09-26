import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import 'track_order_screen.dart';
import 'barcode_scan_screen.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../reviews/presentation/submit_review_screen.dart';
import '../../../models/transport_job.dart';
import '../../../services/firebase_service.dart';
import 'create_dispute_screen.dart';
import '../../payments/presentation/order_payment_card.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import 'buyer_l10n.dart';

class BuyerOrderDetailScreen extends StatefulWidget {
  final FarmoraOrder order;

  const BuyerOrderDetailScreen({super.key, required this.order});

  @override
  State<BuyerOrderDetailScreen> createState() => _BuyerOrderDetailScreenState();
}

class _BuyerOrderDetailScreenState extends State<BuyerOrderDetailScreen> {
  final FirestoreService _service = FirestoreService();
  Stream<List<TransportJob>>? _jobStream;
  final Map<String, Stream<Map<String, dynamic>?>> _transporterStreams = {};
  bool _cancelling = false;

  FarmoraOrder get order => widget.order;

  @override
  void initState() {
    super.initState();
    final uid = context.read<FarmoraState>().currentUserId;
    if (uid.isNotEmpty) {
      _jobStream = _service.jobByOrderAsBuyerStream(order.id, uid);
    }
  }

  Stream<Map<String, dynamic>?> _transporterProfile(String id) =>
      _transporterStreams.putIfAbsent(
          id, () => _service.transporterPublicProfileStream(id));

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  /// Scans the harvest barcode; it only counts when the server verified it
  /// AND it belongs to this order.
  Future<void> _verifyBarcode(FarmoraOrder currentOrder) async {
    final l = context.l10n;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (!mounted || result == null) return;
    final scannedOrderId = (result['orderId'] ?? '').toString();
    if (result['valid'] == false || scannedOrderId != currentOrder.id) {
      _snack(
          scannedOrderId.isNotEmpty && scannedOrderId != currentOrder.id
              ? 'This barcode belongs to a different order.'
              : l.buyerBarcodeVerifyFailed,
          error: true);
      return;
    }
    _snack(l.harvestAuthenticityVerified);
  }

  Future<void> _cancelOrder(
      FarmoraState state, FarmoraOrder currentOrder) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancelOrder),
        content: Text(l.buyerCancelOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.noKeep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.yesCancel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await state.cancelOrder(currentOrder.id);
      if (!mounted) return;
      _snack(l.orderCancelled);
      Navigator.of(context).pop();
    } catch (e, st) {
      _snack(userMessage(e, action: 'cancel the order', stack: st),
          error: true);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  /// Complaints (with photo evidence) are possible once the farmer has
  /// confirmed the order, until it is cancelled or already disputed.
  bool _canDispute(FarmoraOrder o) =>
      !o.isCancelled && !o.isDisputed && o.statusStep >= 1;

  /// The server accepts one review per order, only once delivered.
  bool _canReview(FarmoraOrder o) =>
      o.statusKey == 'delivered' && !o.isDisputed;

  Widget _buildTrustActions(AppLocalizations l, FarmoraOrder o) {
    final canReview = _canReview(o);
    final canDispute = _canDispute(o);
    if (!canReview && !canDispute) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(l.buyerTrustAndSupport,
            style: Theme.of(context).textTheme.titleMedium),
        if (!canReview)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l.buyerReviewsUnlockHint,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant)),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (canReview)
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => SubmitReviewScreen(order: o)),
                  ),
                  label: Text(l.submitReview),
                ),
              ),
            if (canReview && canDispute) const SizedBox(width: 8),
            if (canDispute)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CreateDisputeScreen(order: o)),
                  ),
                  label: Text(l.openComplaint),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final currentOrder = state.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );
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
                    l.buyerOrderNumber(currentOrder.displayNumber),
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
                _buildStatusBadge(l, currentOrder.statusKey),
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
            if (!currentOrder.isCancelled && currentOrder.statusStep < 3)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(l.verifyHarvestBarcode),
                  onPressed: () => _verifyBarcode(currentOrder),
                ),
              ),
            _buildTrustActions(l, currentOrder),
            const SizedBox(height: 16),
            if (!currentOrder.isCancelled) ...[
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
                              currentOrder.farmerName.isNotEmpty
                                  ? currentOrder.farmerName
                                  : l.farmer,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.farmer,
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
                      if (currentOrder.statusKey == 'pending')
                        IconButton(
                          tooltip: l.editDeliveryAddress,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _editDeliveryAddress(state, currentOrder),
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
                  _buildSummaryRow(
                      l.quantity,
                      currentOrder.unit.isNotEmpty &&
                              !currentOrder.quantity.contains(currentOrder.unit)
                          ? '${currentOrder.quantity} ${currentOrder.unit}'
                          : currentOrder.quantity),
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
            if (_jobStream != null)
              StreamBuilder<List<TransportJob>>(
                stream: _jobStream,
                builder: (context, snap) {
                  final jobs = snap.data ?? const <TransportJob>[];
                  if (jobs.isEmpty) return const SizedBox.shrink();
                  return _buildJobCard(l, jobs.first);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: (() {
            final trackable = !currentOrder.isCancelled &&
                (currentOrder.statusStep == 1 || currentOrder.statusStep == 2);
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
                    onPressed: _cancelling
                        ? null
                        : () => _cancelOrder(state, currentOrder),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _cancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
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
    final currentStep = order.statusStep;
    if (order.isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.statusRejectedBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined,
                color: AppColors.statusRejectedText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${l.buyerOrderStatus}: ${statusLabel(order.statusKey, l)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusRejectedText,
                ),
              ),
            ),
          ],
        ),
      );
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

    // [status] is a normalised FarmoraOrder.statusKey.
    switch (status) {
      case 'confirmed':
      case 'assigned':
      case 'pickedUp':
      case 'inTransit':
      case 'delivered':
      case 'completed':
        bgColor = AppColors.statusApprovedBg;
        textColor = AppColors.statusApprovedText;
        break;
      case 'rejected':
      case 'cancelled':
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

  Future<void> _editDeliveryAddress(
      FarmoraState state, FarmoraOrder order) async {
    final controller = TextEditingController(text: order.deliveryAddress);
    final l = context.l10n;
    var saving = false;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.editDeliveryAddress),
          content: TextField(
            controller: controller,
            enabled: !saving,
            decoration: InputDecoration(
              hintText: l.buyerEnterNewAddress,
              errorText: error,
              errorMaxLines: 3,
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(ctx).pop(false),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      final address = controller.text.trim();
                      if (address.length < 5) {
                        setDialog(() => error = l.buyerEnterAddressToOrder);
                        return;
                      }
                      setDialog(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await state.updateOrderAddress(order.id, address);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e, st) {
                        if (ctx.mounted) {
                          setDialog(() {
                            saving = false;
                            error = userMessage(e,
                                action: 'update the delivery address',
                                stack: st);
                          });
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.commonSave),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true) _snack(l.addressUpdatedSuccessfully);
  }

  Widget _buildJobCard(AppLocalizations l, TransportJob job) {
    final transporterId = (job.transporterId ?? '').isNotEmpty
        ? job.transporterId!
        : (job.requestedTransporterId ?? '');
    final fee = job.deliveryFeeMinor != null
        ? AppFormat.lkr(job.deliveryFeeMinor! / 100, decimals: 2)
        : job.fee;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    statusLabel(job.status, l),
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
            if (transporterId.isEmpty)
              _buildSummaryRow(
                  l.buyerTransportProvider, l.buyerPendingAssignment)
            else
              StreamBuilder<Map<String, dynamic>?>(
                stream: _transporterProfile(transporterId),
                builder: (context, snap) {
                  final name = (snap.data?['displayName'] ?? '').toString();
                  final vehicle = (snap.data?['vehicleType'] ?? '').toString();
                  final label = name.isEmpty ? l.roleTransporter : name;
                  final assigned = (job.transporterId ?? '').isNotEmpty;
                  return _buildSummaryRow(
                    l.buyerTransportProvider,
                    [
                      assigned
                          ? label
                          : '$label (${statusLabel('requested', l)})',
                      if (vehicle.isNotEmpty) vehicle,
                    ].join(' • '),
                  );
                },
              ),
            _buildDivider(),
            _buildSummaryRow(l.buyerRoute, job.route),
            _buildDivider(),
            _buildSummaryRow(l.buyerFee, fee),
          ],
        ),
      ),
    );
  }
}
