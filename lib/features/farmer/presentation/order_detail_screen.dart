import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../messaging/presentation/conversations_screen.dart';
import '../../payments/presentation/order_payment_card.dart';
import 'logistics_tracking_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final FarmoraOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  /// True while a backend call started from this screen is in flight.
  bool _busy = false;

  /// Cached transporter public-profile stream (recreated only when the
  /// assigned transporter changes, not on every rebuild).
  String? _driverId;
  Stream<Map<String, dynamic>?>? _driverStream;

  Stream<Map<String, dynamic>?> _driverProfile(String transporterId) {
    if (_driverStream == null || _driverId != transporterId) {
      _driverId = transporterId;
      _driverStream =
          FirestoreService().transporterPublicProfileStream(transporterId);
    }
    return _driverStream!;
  }

  /// Driver row: the transporter's display name, falling back to
  /// "Assigned transporter" while loading or when no public profile exists.
  Widget _buildDriverRow(String label, String? transporterId, AppLocalizations l) {
    if (transporterId == null || transporterId.isEmpty) {
      return _buildSummaryRow(label, l.statusPending);
    }
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _driverProfile(transporterId),
      builder: (context, snapshot) {
        final name =
            (snapshot.data?['displayName'] ?? '').toString().trim();
        return _buildSummaryRow(
            label, name.isNotEmpty ? name : l.farmerTrackAssignedTransporter);
      },
    );
  }

  /// Runs [action] with the busy flag set; shows [success] only after it
  /// completes and `userMessage(e)` on failure. Returns true on success.
  Future<bool> _run(
    Future<void> Function() action, {
    required String success,
    required String errorAction,
    bool popOnSuccess = false,
    Color? successColor,
  }) async {
    if (_busy) return false;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(
        content: Text(success),
        backgroundColor: successColor ?? AppColors.primary,
      ));
      if (popOnSuccess && mounted) navigator.pop();
      return true;
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(userMessage(e, action: errorAction)),
        backgroundColor: AppColors.error,
      ));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _callBuyer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start a call to $phone.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(userMessage(e, action: 'call the buyer'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final state = context.watch<FarmoraState>();
    final currentOrder = state.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );
    final canConfirmHandover = (currentOrder.statusKey == 'assigned' ||
            currentOrder.statusKey == 'pickedUp') &&
        currentOrder.farmerHandedOverAt == null;
    final buyerPhone = currentOrder.buyerPhone.trim();
    final linkedJobForOrder =
        state.jobs.where((j) => j.orderId == currentOrder.id).firstOrNull;
    final canRequestTransport = linkedJobForOrder == null ||
        linkedJobForOrder.isRequested ||
        linkedJobForOrder.status == 'cancelled';
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
          l.farmerOrderDetailTitle,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Order Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                      l.farmerOrderNumberUpper(currentOrder.displayNumber.toUpperCase()),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentOrder.isPending
                                  ? AppColors.primaryContainer
                                  : currentOrder.isAccepted
                                      ? AppColors.primary
                                      : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel(currentOrder.status, l).toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentOrder.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
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
                        currentOrder.requestedDate.contains('Requested')
                            ? currentOrder.requestedDate
                            : l.farmerOrderRequestedFor(currentOrder.requestedDate),
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

                // 2. Buyer Info Card
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
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: SafeImage(
                                path: currentOrder.buyerAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const CircleAvatar(
                                  backgroundColor: AppColors.surfaceContainerHigh,
                                  child: Icon(Icons.person, color: AppColors.primary),
                                ),
                              ),
                            ),
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
                          Row(
                            children: [
                              if (buyerPhone.isNotEmpty) ...[
                                _buildActionCircle(
                                  icon: Icons.call_outlined,
                                  onTap: () => _callBuyer(buyerPhone),
                                ),
                                const SizedBox(width: 8),
                              ],
                              _buildActionCircle(
                                icon: Icons.chat_bubble_outline,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ConversationsScreen(orderId: currentOrder.id),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppColors.outlineVariant.withValues(alpha: 0.4), height: 1),
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
                                  l.farmerOrderDeliveryAddress,
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
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Order Summary Card
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
                        l.farmerOrderSummary,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow(l.farmerOrderProduct, currentOrder.productName.isNotEmpty ? currentOrder.productName : currentOrder.title),
                      _buildDivider(),
                      _buildSummaryRow(l.quantity, currentOrder.quantity),
                      _buildDivider(),
                      _buildSummaryRow(l.farmerOrderUnitPrice, currentOrder.unitPrice),
                      _buildDivider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
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
                            Text(
                              currentOrder.displayTotal,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!currentOrder.isDeclined) ...[
                  const SizedBox(height: 20),
                  OrderPaymentCard(order: currentOrder, viewerIsFarmer: true),
                ],
                if (!currentOrder.isPending && !currentOrder.isDeclined) ...[
                  const SizedBox(height: 20),
                  _AuthenticityBarcodeCard(orderId: currentOrder.id),
                ],
                if (linkedJob != null) ...[
                  const SizedBox(height: 20),
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
                                l.farmerOrderTransportJob,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                statusLabel(linkedJob.status, l).toUpperCase(),
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
                        _buildDriverRow(l.farmerOrderDriver, linkedJob.transporterId, l),
                        _buildDivider(),
                        _buildSummaryRow(l.farmerOrderFee, linkedJob.fee),
                      ],
                    ),
                  ),
                ],
                if (canConfirmHandover) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                                () => state.confirmHandover(currentOrder.id),
                                success:
                                    'Handover confirmed for ${currentOrder.displayNumber}.',
                                errorAction: 'confirm the handover',
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      icon: const Icon(Icons.handshake_outlined, size: 20),
                      label: const Text('Confirm handed to transporter'),
                    ),
                  ),
                ] else if (currentOrder.farmerHandedOverAt != null &&
                    !currentOrder.isCompleted) ...[
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            'You confirmed the handover to the transporter.'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Buttons
          if (currentOrder.isPending)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => state.declineOrder(currentOrder.id),
                                  success: l.orderRejected,
                                  successColor: AppColors.error,
                                  errorAction: 'decline the order',
                                  popOnSuccess: true,
                                ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.errorContainer, width: 2),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: Text(
                          l.reject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => state.acceptOrder(currentOrder.id),
                                  success: l.farmerOrderAcceptedBalance,
                                  errorAction: 'accept the order',
                                  popOnSuccess: true,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          l.farmerOrderAccept,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (currentOrder.isAccepted)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LogisticsTrackingScreen(order: currentOrder),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: Text(
                          l.farmerOrderTrackLogistics,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (canRequestTransport) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                          final feeController = TextEditingController(
                            text: currentOrder.deliveryFeeMinor > 0
                                ? (currentOrder.deliveryFeeMinor / 100)
                                    .toStringAsFixed(0)
                                : '500',
                          );
                          final fee = await showDialog<int>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l.transportFeeLkr),
                              content: TextField(
                                controller: feeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l.farmerOrderOfferedFee,
                                  prefixText: 'LKR ',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(l.commonCancel),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final major =
                                        int.tryParse(feeController.text.trim()) ?? 0;
                                    Navigator.pop(ctx, major * 100);
                                  },
                                  child: Text(l.request),
                                ),
                              ],
                            ),
                          );
                          if (fee == null || fee < 0 || !context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _busy = true);
                          try {
                            await state.requestTransportForOrder(
                              currentOrder.id,
                              deliveryFeeMinor: fee,
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l.farmerOrderTransportRequested),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(l.farmerOrderTransportRequestFailed(
                                      userMessage(e,
                                          action: 'request transport')))),
                            );
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: Text(
                          l.farmerOrderRequestTransport,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCircle({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
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
}

class _AuthenticityBarcodeCard extends StatefulWidget {
  final String orderId;

  const _AuthenticityBarcodeCard({required this.orderId});

  @override
  State<_AuthenticityBarcodeCard> createState() =>
      _AuthenticityBarcodeCardState();
}

class _AuthenticityBarcodeCardState extends State<_AuthenticityBarcodeCard> {
  final _service = FirestoreService();
  bool _busy = false;
  String? _scanPayload;
  String? _error;

  Future<void> _issue() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.issueOrderBarcode(widget.orderId);
      if (!mounted) return;
      setState(() => _scanPayload = result['scanPayload']);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = userMessage(e, action: 'issue the order barcode'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
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
            l.farmerBarcodeTitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.farmerBarcodeHint,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_scanPayload != null) ...[
            Center(
              child: QrImageView(
                data: _scanPayload!,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _scanPayload!,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _scanPayload!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.barcodePayloadCopied)),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l.copyPayload),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _issue,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2),
                label: Text(_busy ? l.farmerBarcodeIssuing : l.farmerBarcodeIssue),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
