import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/conversation_model.dart';
import '../../../models/notification_model.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import '../../home/presentation/order_navigation.dart';
import '../../messaging/presentation/chat_screen.dart';

/// A notification plus its routing helpers. The model already parses the
/// backend's extra fields (`conversationId`, `senderId`, `orderId`, `jobId`)
/// and Timestamp `createdAt` values.
class _NotifItem {
  _NotifItem(this.notif);

  final FarmoraNotification notif;

  String get conversationId => notif.conversationId ?? '';
  String get senderId => notif.senderId ?? '';
  String get orderId => notif.orderId ?? notif.referenceId ?? '';

  static _NotifItem fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      _NotifItem(FarmoraNotification.fromMap(doc.id, doc.data()));
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = FirestoreService();
  // Internal filter ids (not shown): 'All', 'Unread', 'Orders', 'Offers',
  // 'Logistics', 'Messages'. Labels come from [_filterLabel].
  String _selectedFilter = 'All';
  bool _orderUpdates = true;
  bool _messages = true;
  bool _promos = false;
  bool _quietHours = false;

  /// Created once (not per build) so rebuilds don't resubscribe.
  Stream<List<_NotifItem>>? _stream;
  final Set<String> _opening = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<FarmoraState>();
    _loadPrefs(state.notificationPrefs);
    _stream = _createStream(state.currentUserId);
  }

  Stream<List<_NotifItem>>? _createStream(String uid) {
    if (uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(_NotifItem.fromDoc).toList());
  }

  void _loadPrefs(Map<String, dynamic> prefs) {
    _orderUpdates = prefs['orderUpdates'] != false;
    _messages = prefs['messages'] != false;
    _promos = prefs['promos'] == true;
    _quietHours = prefs['quietHoursStart'] != null ||
        prefs['quietHours'] == true; // legacy flag
  }

  Future<void> _savePrefs() async {
    final state = context.read<FarmoraState>();
    try {
      await state.updateNotificationPrefs({
        'orderUpdates': _orderUpdates,
        'messages': _messages,
        'promos': _promos,
        'quietHoursStart': _quietHours ? 22 : null,
        'quietHoursEnd': _quietHours ? 7 : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notifPrefsSaved)),
        );
      }
    } catch (e, st) {
      if (mounted) {
        // Show what is really saved.
        setState(() => _loadPrefs(state.notificationPrefs));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage(e,
                action: 'save notification preferences', stack: st)),
          ),
        );
      }
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _markAllRead(FarmoraState state) async {
    try {
      await state.markAllNotificationsRead();
      if (mounted) _snack(context.l10n.notifAllMarkedRead);
    } catch (e, st) {
      _snack(userMessage(e, action: 'mark notifications read', stack: st));
    }
  }

  /// Deletes on swipe; the item only disappears when the delete succeeded.
  Future<bool> _delete(FarmoraState state, _NotifItem item) async {
    try {
      await state.deleteNotification(item.notif.id);
      return true;
    } catch (e, st) {
      _snack(userMessage(e, action: 'delete the notification', stack: st));
      return false;
    }
  }

  Future<void> _open(FarmoraState state, _NotifItem item) async {
    final notif = item.notif;
    if (_opening.contains(notif.id)) return;
    _opening.add(notif.id);
    try {
      if (!notif.read) {
        try {
          await state.markNotificationRead(notif.id);
        } catch (e, st) {
          _snack(userMessage(e, action: 'mark the notification read',
              stack: st));
        }
      }
      if (!mounted) return;
      final type = notif.type.toLowerCase();
      if (type == 'message' || item.conversationId.isNotEmpty) {
        await _openChat(item);
        return;
      }
      final orderId = item.orderId;
      if (orderId.isEmpty) return;
      final order = state.orders.where((o) => o.id == orderId).firstOrNull;
      if (order == null) {
        if (const {'order', 'logistics', 'transport', 'payment'}
            .contains(type)) {
          _snack('This order is no longer available.');
        }
        return;
      }
      openOrderDetail(context, order);
    } finally {
      _opening.remove(notif.id);
    }
  }

  Future<void> _openChat(_NotifItem item) async {
    try {
      FarmoraConversation? conversation;
      if (item.orderId.isNotEmpty && item.senderId.isNotEmpty) {
        conversation = await _service.ensureConversation(
          orderId: item.orderId,
          peerId: item.senderId,
        );
      } else if (item.conversationId.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(item.conversationId)
            .get();
        final data = snap.data();
        if (data != null) {
          conversation = FarmoraConversation.fromMap(snap.id, data);
        }
      }
      if (!mounted) return;
      if (conversation == null) {
        _snack('This conversation is no longer available.');
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation!),
      ));
    } catch (e, st) {
      _snack(userMessage(e, action: 'open the chat', stack: st));
    }
  }

  void _showPreferencesSheet() {
    var saved = false;
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
            final l = ctx.l10n;
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
                      Expanded(
                        child: Text(
                          l.notifPreferencesTooltip,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.commonClose,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.notifPrefOrderUpdates),
                    value: _orderUpdates,
                    onChanged: (v) {
                      setState(() => _orderUpdates = v);
                      setSheetState(() => _orderUpdates = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.notifPrefMessages),
                    value: _messages,
                    onChanged: (v) {
                      setState(() => _messages = v);
                      setSheetState(() => _messages = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.promotionsPriceUpdates),
                    value: _promos,
                    onChanged: (v) {
                      setState(() => _promos = v);
                      setSheetState(() => _promos = v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.quietHours10pm7am),
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
                        saved = true;
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
                      child: Text(l.savePreferences),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Closed without saving: show the saved preferences again.
      if (!saved && mounted) {
        setState(() =>
            _loadPrefs(context.read<FarmoraState>().notificationPrefs));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FarmoraState>();
    final l = context.l10n;
    final stream = _stream;

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
        title: Text(
          l.notifications,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l.notifPreferencesTooltip,
            icon: const Icon(Icons.tune_rounded, color: AppColors.onSurface),
            onPressed: _showPreferencesSheet,
          ),
          IconButton(
            tooltip: l.markAllRead,
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            onPressed: () => _markAllRead(state),
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
                _buildFilterChip('Messages'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: stream != null
                ? StreamBuilder<List<_NotifItem>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      final items = _filterNotifications(
                          snapshot.data ?? const <_NotifItem>[]);
                      return AsyncStateView(
                        isLoading: !snapshot.hasData && !snapshot.hasError,
                        error: snapshot.hasError ? snapshot.error : null,
                        isEmpty: snapshot.hasData && items.isEmpty,
                        emptyMessage: _emptyMessage(l),
                        onRetry: () => setState(() {
                          _stream = _createStream(state.currentUserId);
                        }),
                        child: _buildListView(items, state),
                      );
                    },
                  )
                : Builder(
                    builder: (context) {
                      final items = _filterNotifications(state.notifications
                          .map(_NotifItem.new)
                          .toList());
                      return AsyncStateView(
                        isLoading: false,
                        isEmpty: items.isEmpty,
                        emptyMessage: _emptyMessage(l),
                        child: _buildListView(items, state),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_NotifItem> _filterNotifications(List<_NotifItem> list) {
    String type(_NotifItem i) => i.notif.type.toLowerCase();
    switch (_selectedFilter) {
      case 'Unread':
        return list.where((i) => !i.notif.read).toList();
      case 'Orders':
        return list
            .where((i) => const {'order', 'payment'}.contains(type(i)))
            .toList();
      case 'Offers':
        return list.where((i) => type(i) == 'offer').toList();
      case 'Logistics':
        return list
            .where((i) => const {'logistics', 'transport'}.contains(type(i)))
            .toList();
      case 'Messages':
        return list.where((i) => type(i) == 'message').toList();
      default:
        return list;
    }
  }

  String _emptyMessage(AppLocalizations l) =>
      _selectedFilter == 'All' ? l.noNotificationsYet : l.notifEmptyFiltered;

  String _filterLabel(String filter) {
    final l = context.l10n;
    return switch (filter) {
      'Unread' => l.notifFilterUnread,
      'Orders' => l.orders,
      'Offers' => l.homeNavOffers,
      'Logistics' => l.homeNavLogistics,
      'Messages' => l.messages,
      _ => l.commonAll,
    };
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_filterLabel(filter)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = filter);
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

  Widget _buildListView(List<_NotifItem> list, FarmoraState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        return Dismissible(
          key: ValueKey('notif_${item.notif.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _delete(state, item),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.white),
          ),
          child: _buildNotificationCard(item, state),
        );
      },
    );
  }

  Widget _buildNotificationCard(_NotifItem item, FarmoraState state) {
    final notif = item.notif;
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
      case 'transport':
        icon = Icons.local_shipping_rounded;
        iconColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        iconColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFF3E8FF);
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppColors.primary;
        bgColor = AppColors.primaryContainer.withValues(alpha: 0.3);
    }

    return InkWell(
      onTap: () => _open(state, item),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    AppFormat.relative(notif.createdAt),
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
}
