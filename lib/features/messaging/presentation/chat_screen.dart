import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/chat_outbox_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/conversation_model.dart';
import '../../../services/chat_crypto.dart';
import '../../../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final FarmoraConversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _service = FirestoreService();
  bool _sending = false;
  String? _error;
  String? _peerPublicKey;

  @override
  void initState() {
    super.initState();
    _bootstrapKeys();
  }

  Future<void> _bootstrapKeys() async {
    try {
      final pub = await ChatCrypto.instance.publicKeyBase64();
      await _service.publishChatPublicKey(pub);
      final peerId = _recipientOf(widget.conversation);
      final peerKey = await _service.fetchChatPublicKey(peerId);
      if (mounted) setState(() => _peerPublicKey = peerKey);
    } catch (_) {
      // Crypto bootstrap is best-effort; send will surface errors.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _recipientOf(FarmoraConversation c) {
    return c.participantIds.firstWhere((id) => id != _uid,
        orElse: () =>
            c.participantIds.isNotEmpty ? c.participantIds.first : '');
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final peerKey = _peerPublicKey ??
          await _service.fetchChatPublicKey(_recipientOf(widget.conversation));
      if (peerKey == null || peerKey.isEmpty) {
        throw StateError(
            'Recipient has no chat key yet. Ask them to open chat once.');
      }
      String? ciphertext;
      try {
        ciphertext = await ChatCrypto.instance.encrypt(
          plaintext: text,
          peerPublicKeyB64: peerKey,
        );
        await _service.sendEncryptedMessage(
          orderId: widget.conversation.orderId,
          recipientId: _recipientOf(widget.conversation),
          ciphertext: ciphertext,
        );
        _controller.clear();
      } catch (e) {
        if (ciphertext != null) {
          await ChatOutboxService.enqueue(PendingMessage(
            orderId: widget.conversation.orderId,
            recipientId: _recipientOf(widget.conversation),
            ciphertext: ciphertext,
          ));
          _controller.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved offline. Will retry automatically.')),
            );
          }
        } else {
          setState(() => _error = 'Could not encrypt message. Check keys.');
        }
      }
    } catch (e) {
      setState(() => _error = 'Key error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String> _decode(String body) async {
    final peerKey = _peerPublicKey;
    if (peerKey == null || peerKey.isEmpty) {
      if (body.startsWith('farmora1:')) {
        return body
            .substring('farmora1:'.length)
            .replaceAll(RegExp(r'\.+$'), '');
      }
      if (body.startsWith(ChatCrypto.currentCiphertextPrefix) ||
          body.startsWith(ChatCrypto.ciphertextPrefix)) {
        return '[encrypted]';
      }
      return body;
    }
    try {
      return await ChatCrypto.instance.decrypt(
        ciphertext: body,
        peerPublicKeyB64: peerKey,
      );
    } catch (_) {
      return '[undecryptable]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
          title: const Text('Order chat'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FarmoraMessage>>(
              stream: _service.messagesStream(
                widget.conversation.id,
                orderId: widget.conversation.orderId,
                uid: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? const <FarmoraMessage>[];
                if (msgs.isEmpty) {
                  return const Center(
                      child: Text(
                          'Say hello — messages are order-scoped and encrypted for the recipient.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.senderId == _uid;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.primary
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FutureBuilder<String>(
                          future: _decode(m.body),
                          builder: (context, dec) {
                            return Text(
                              dec.data ?? '…',
                              style: TextStyle(
                                  color: mine
                                      ? Colors.white
                                      : AppColors.onSurface),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
