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

  /// Optional explicit chat partner for [orderId]. When omitted the screen
  /// offers every other party of the order (never assumes the farmer).
  final String? peerId;
  const ConversationsScreen({super.key, this.orderId, this.peerId});

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

  /// The parties of [order] this user may chat with, labelled by role.
  List<_Peer> _peersFor(FarmoraOrder order, AppLocalizations l) {
    final explicit = widget.peerId;
    final peers = <_Peer>[
      if (order.farmerId.isNotEmpty && order.farmerId != _uid)
        _Peer(order.farmerId, l.chatStartWithFarmer, l.chatMessageTheFarmer),
      if (order.buyerId.isNotEmpty && order.buyerId != _uid)
        _Peer(order.buyerId, l.chatStartWithBuyer, l.chatMessageTheBuyer),
      if (order.transporterId.isNotEmpty && order.transporterId != _uid)
        _Peer.transporterFor(order.transporterId),
    ];
    if (explicit != null && explicit.isNotEmpty) {
      return peers.where((p) => p.id == explicit).toList();
    }
    return peers;
  }

  Future<void> _startChat(FarmoraOrder order, String peerId) async {
    setState(() {
      _starting = true;
      _startError = null;
    });
    try {
      final conversation = await _service.ensureConversation(
        orderId: order.id,
        peerId: peerId,
      );
      if (!mounted) return;
      // A conversation that does not exist yet (exists == false) is
      // created by the first message.
      await Navigator.of(context).push(MaterialPageRoute(
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
    final state = context.watch<FarmoraState>();
    final order = orderId == null || orderId.isEmpty
        ? null
        : state.orders.where((o) => o.id == orderId).firstOrNull;
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
          // Parties of this order without a conversation yet.
          final missing = order == null
              ? const <_Peer>[]
              : _peersFor(order, l)
                  .where((p) =>
                      !items.any((c) => c.participantIds.contains(p.id)))
                  .toList();
          if (items.isEmpty) {
            if (order != null && missing.isNotEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 40, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        missing.length == 1
                            ? missing.first.intro
                            : 'Start a private chat about order '
                                '${order.displayNumber}. Phone numbers stay '
                                'private.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      for (final peer in missing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _startButton(order, peer),
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
          final header = order == null || missing.isEmpty ? 0 : 1;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + header,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (header == 1 && index == 0) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final peer in missing) _startButton(order!, peer),
                    if (_startError != null)
                      Text(_startError!,
                          style: const TextStyle(color: AppColors.error)),
                  ],
                );
              }
              final c = items[index - header];
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
              final convoOrder = c.orderId == order?.id
                  ? order
                  : state.orders.where((o) => o.id == c.orderId).firstOrNull;
              final shortId = convoOrder?.displayNumber ??
                  c.orderId.substring(
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

  Widget _startButton(FarmoraOrder order, _Peer peer) => FilledButton.icon(
        onPressed: _starting ? null : () => _startChat(order, peer.id),
        icon: _starting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send, size: 18),
        label: Text(peer.action),
      );

  Widget _note(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

class _Peer {
  const _Peer(this.id, this.intro, this.action);
  const _Peer.transporterFor(this.id)
      : intro = 'Start a private chat with the transporter about this '
            'delivery.',
        action = 'Message the transporter';
  final String id;
  final String intro;
  final String action;
}
