import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/order.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';

class OrderDetailScreen extends StatefulWidget {
  final FarmoraOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late FarmoraOrder currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final isFarmer = state.role == Role.farmer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: currentOrder.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: currentOrder.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(currentOrder.status),
                        color: currentOrder.color,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              currentOrder.detail,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      Text(
                        currentOrder.status,
                        style: TextStyle(
                          color: currentOrder.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: currentOrder.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(currentOrder.color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order timeline
            const Text(
              'Order Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),

            const SizedBox(height: 24),

            // Action buttons based on role and status
            if (isFarmer && currentOrder.status == 'Pending')
              _buildFarmerActions(),
            if (!isFarmer && currentOrder.status == 'In transit')
              _buildBuyerActions(),

            const SizedBox(height: 24),

            // Contact info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xffdcefe2),
                    child: Icon(
                      isFarmer ? Icons.shopping_cart : Icons.agriculture,
                      color: const Color(0xff1f7a4d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFarmer ? 'Buyer' : 'Farmer',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          isFarmer ? 'Colombo Restaurant' : 'Nuwara Eliya Farm',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement chat
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement call
                    },
                    icon: const Icon(Icons.phone_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        subtitle: 'Buyer placed the order',
        icon: Icons.check_circle,
        isCompleted: true,
      ),
      _TimelineStep(
        title: 'Farmer Confirms',
        subtitle: currentOrder.status == 'Pending' ? 'Waiting for confirmation' : 'Confirmed by farmer',
        icon: currentOrder.status == 'Pending' ? Icons.radio_button_unchecked : Icons.check_circle,
        isCompleted: currentOrder.status != 'Pending',
      ),
      _TimelineStep(
        title: 'In Transit',
        subtitle: currentOrder.status == 'In transit' ? 'On the way' : 'Waiting for dispatch',
        icon: currentOrder.status == 'In transit' ? Icons.check_circle : Icons.radio_button_unchecked,
        isCompleted: currentOrder.status == 'In transit' || currentOrder.status == 'Delivered',
      ),
      _TimelineStep(
        title: 'Delivered',
        subtitle: currentOrder.status == 'Delivered' ? 'Successfully delivered' : 'Waiting for delivery',
        icon: currentOrder.status == 'Delivered' ? Icons.check_circle : Icons.radio_button_unchecked,
        isCompleted: currentOrder.status == 'Delivered',
      ),
    ];

    return Column(
      children: steps.map((step) => _buildTimelineItem(step)).toList(),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Column(
            children: [
              Icon(
                step.icon,
                color: step.isCompleted ? const Color(0xff1f7a4d) : Colors.grey,
                size: 24,
              ),
              if (step != _TimelineStep(
                title: 'Delivered',
                subtitle: '',
                icon: Icons.check_circle,
                isCompleted: false,
              ))
                Container(
                  width: 2,
                  height: 30,
                  color: step.isCompleted ? const Color(0xff1f7a4d) : Colors.grey.shade300,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: step.isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _updateOrderStatus('Cancelled', 0.0, const Color(0xffE53935));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () {
              _updateOrderStatus('In transit', 0.5, const Color(0xff3478c5));
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff1f7a4d),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Confirm Order'),
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerActions() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          _updateOrderStatus('Delivered', 1.0, const Color(0xff1f7a4d));
        },
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff1f7a4d),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Mark as Delivered'),
      ),
    );
  }

  void _updateOrderStatus(String status, double progress, Color color) {
    setState(() {
      currentOrder = FarmoraOrder(
        id: currentOrder.id,
        title: currentOrder.title,
        detail: currentOrder.detail,
        status: status,
        progress: progress,
        color: color,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order status updated to $status'),
        backgroundColor: const Color(0xff1f7a4d),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.access_time;
      case 'In transit':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
  });
}
