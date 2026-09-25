import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/notification_model.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../transporter/presentation/transport_request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = FirestoreService();
  String _selectedFilter =
      'All'; // 'All', 'Unread', 'Orders', 'Offers', 'Logistics'
  bool _orderUpdates = true;
  bool _messages = true;
  bool _promos = false;
  bool _quietHours = false;

  Future<void> _savePrefs() async {
    try {
      await _service.updateNotificationPreferences({
        'orderUpdates': _orderUpdates,
        'messages': _messages,
        'promos': _promos,
        'quietHours': _quietHours,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  void _showPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Order status updates'),
                    value: _orderUpdates,
                    onChanged: (v) {
                      setState(() => _orderUpdates = v);
                      setSheetState(() => _orderUpdates = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('New messages & alerts'),
                    value: _messages,
                    onChanged: (v) {
                      setState(() => _messages = v);
                      setSheetState(() => _messages = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Promotions & price updates'),
                    value: _promos,
                    onChanged: (v) {
                      setState(() => _promos = v);
                      setSheetState(() => _promos = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quiet hours (10pm – 7am)'),
                    value: _quietHours,
                    onChanged: (v) {
                      setState(() => _quietHours = v);
                      setSheetState(() => _quietHours = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _savePrefs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final uid = state.currentUserId;

    // Use state.notifications if available, or fallback to direct Firestore Stream
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Preferences',
            icon: const Icon(Icons.tune_rounded, color: AppColors.onSurface),
            onPressed: _showPreferencesSheet,
          ),
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            onPressed: () async {
              await state.markAllNotificationsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All notifications marked as read')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Unread'),
                _buildFilterChip('Orders'),
                _buildFilterChip('Offers'),
                _buildFilterChip('Logistics'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: uid.isNotEmpty
                ? StreamBuilder<List<FarmoraNotification>>(
                    stream: _service.notificationsStream(uid),
                    builder: (context, snapshot) {
                      final l10n = AppLocalizations.of(context);
                      return AsyncStateView(
                        isLoading: !snapshot.hasData && !snapshot.hasError,
                        error: snapshot.hasError ? snapshot.error : null,
                        isEmpty: snapshot.hasData &&
                            _filterNotifications(snapshot.data!).isEmpty,
                        emptyMessage: l10n.emptyState,
                        onRetry: () => setState(() {}),
                        child: _buildListView(
                          _filterNotifications(snapshot.data ?? const []),
                          state,
                        ),
                      );
                    },
                  )
                : Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      final notifs = _filterNotifications(state.notifications);
                      return AsyncStateView(
                        isLoading: false,
                        isEmpty: notifs.isEmpty,
                        emptyMessage: l10n.emptyState,
                        child: _buildListView(notifs, state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<FarmoraNotification> _filterNotifications(
      List<FarmoraNotification> list) {
    switch (_selectedFilter) {
      case 'Unread':
        return list.where((n) => !n.read).toList();
      case 'Orders':
        return list.where((n) => n.type.toLowerCase() == 'order').toList();
      case 'Offers':
        return list.where((n) => n.type.toLowerCase() == 'offer').toList();
      case 'Logistics':
        return list.where((n) => n.type.toLowerCase() == 'logistics').toList();
      default:
        return list;
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = label);
        },
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLow,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<FarmoraNotification> list, FarmoraState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notif = list[index];
        return _buildNotificationCard(notif, state);
      },
    );
  }

  Widget _buildNotificationCard(FarmoraNotification notif, FarmoraState state) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (notif.type.toLowerCase()) {
      case 'order':
        icon = Icons.shopping_basket_rounded;
        iconColor = const Color(0xFF1B6BD8);
        bgColor = const Color(0xFFE8F1FC);
        break;
      case 'offer':
        icon = Icons.local_offer_rounded;
        iconColor = const Color(0xFF1E824C);
        bgColor = const Color(0xFFE7F7EE);
        break;
      case 'logistics':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primaryContainer.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: () async {
        if (!notif.read) {
          state.markNotificationRead(notif.id);
        }
        if (notif.type.toLowerCase() != 'logistics' ||
            notif.referenceId == null ||
            notif.referenceId!.isEmpty ||
            state.currentUserId.isEmpty) {
          return;
        }
        try {
          final job = await _service.getTransportJobForOrder(
            orderId: notif.referenceId!,
            transporterId: state.currentUserId,
          );
          if (!context.mounted) return;
          if (job == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Delivery request is no longer available.')),
            );
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransportRequestDetailScreen(job: job),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open delivery request: $e')),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.read
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.read
                ? AppColors.outlineVariant.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.4),
            width: notif.read ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: notif.read ? 0.02 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight:
                                notif.read ? FontWeight.w600 : FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (!notif.read)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notif.createdAt),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
