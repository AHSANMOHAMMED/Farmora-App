import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../models/conversation_model.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/firebase_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final String? orderId;
  const ConversationsScreen({super.key, this.orderId});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late final _service = FirestoreService();
  late final Stream<List<FarmoraConversation>> _stream;
  bool _starting = false;
  String? _startError;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _stream = _service.conversationsForUserStream(_uid);
  }

  /// The other party on [order] this user would chat with.
  String _peerFor(FarmoraOrder order) {
    if (order.buyerId == _uid) return order.farmerId;
    if (order.farmerId == _uid) return order.buyerId;
    // Transporter: talk to the farmer who arranged the delivery.
    return order.farmerId;
  }

  Future<void> _startChat(FarmoraOrder order) async {
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final conversation = await _service.ensureConversation(
        orderId: order.id,
        peerId: _peerFor(order),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChatScreen(conversation: conversation),
      ));
    } catch (e, st) {
      if (mounted) {
        setState(() =>
            _startError = userMessage(e, action: 'open the chat', stack: st));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId;
    final order = orderId == null || orderId.isEmpty
        ? null
        : context
            .watch<FarmoraState>()
            .orders
            .where((o) => o.id == orderId)
            .firstOrNull;
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.messages),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<FarmoraConversation>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return _note(userMessage(snap.error!,
                action: 'load conversations', stack: snap.stackTrace));
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data ?? const <FarmoraConversation>[];
          if (orderId != null && orderId.isNotEmpty) {
            items = items.where((c) => c.orderId == orderId).toList();
          }
          if (items.isEmpty) {
            if (order != null && _peerFor(order).isNotEmpty) {
              final peerIsFarmer = order.buyerId == _uid;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 40, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        peerIsFarmer
                            ? l.chatStartWithFarmer
                            : l.chatStartWithBuyer,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _starting ? null : () => _startChat(order),
                        icon: _starting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(peerIsFarmer
                            ? l.chatMessageTheFarmer
                            : l.chatMessageTheBuyer),
                      ),
                      if (_startError != null) ...[
                        const SizedBox(height: 12),
                        Text(_startError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error)),
                      ],
                    ],
                  ),
                ),
              );
            }
            return _note(l.chatNoConversations);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = items[i];
              final unread = c.unreadFor(_uid);
              // Stored previews are English system values; show them in the
              // app language.
              final preview = switch (c.lastMessage) {
                '' => l.chatNoMessagesYet,
                'Photo' => l.chatPhoto,
                'Payment receipt' => l.chatPaymentReceipt,
                final m when m.startsWith('farmora') => l.chatEncryptedMessage,
                final m => m,
              };
              final shortId = c.orderId.substring(
                  0, c.orderId.length > 6 ? 6 : c.orderId.length);
              return ListTile(
                tileColor: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading:
                    const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text(
                    c.orderId.isEmpty
                        ? l.chatOrderTitleNoId
                        : l.chatOrderTitle(shortId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(preview,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: unread > 0
                    ? Semantics(
                        label: l.chatUnreadCount(unread),
                        excludeSemantics: true,
                        child: CircleAvatar(
                            radius: 11,
                            backgroundColor: AppColors.primary,
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11))),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(conversation: c)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _note(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}
