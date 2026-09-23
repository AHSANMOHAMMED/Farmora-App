import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/conversation_model.dart';
import '../../../services/firebase_service.dart';

/// Backend requires 16..20000 chars. Wrap + pad, strip on display.
String encodeChatOutgoing(String text) {
  final payload = 'farmora1:${text.trim()}';
  return payload.length >= 16 ? payload : payload.padRight(16, '.');
}

String decodeChatIncoming(String body) {
  var out = body;
  if (out.startsWith('farmora1:')) out = out.substring('farmora1:'.length);
  return out.replaceAll(RegExp(r'\.+$'), '');
}

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _recipientOf(FarmoraConversation c) {
    return c.participantIds.firstWhere((id) => id != _uid,
        orElse: () => c.participantIds.isNotEmpty ? c.participantIds.first : '');
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _service.sendEncryptedMessage(
        orderId: widget.conversation.orderId,
        recipientId: _recipientOf(widget.conversation),
        ciphertext: encodeChatOutgoing(text),
      );
      _controller.clear();
    } catch (e) {
      setState(() => _error = 'Could not send. Check connection and retry. ($e)');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Order chat'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FarmoraMessage>>(
              stream: _service.messagesStream(widget.conversation.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? const <FarmoraMessage>[];
                if (msgs.isEmpty) {
                  return const Center(child: Text('Say hello — messages are order-scoped and private.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.senderId == _uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.primary : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(decodeChatIncoming(m.body),
                            style: TextStyle(color: mine ? Colors.white : AppColors.onSurface)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
