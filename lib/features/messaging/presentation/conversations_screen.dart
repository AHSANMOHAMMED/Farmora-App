import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/conversation_model.dart';
import '../../../services/firebase_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  final String? orderId;
  const ConversationsScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<FarmoraConversation>>(
        stream: service.conversationsForUserStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var items = snap.data ?? const <FarmoraConversation>[];
          if (orderId != null && orderId!.isNotEmpty) {
            items = items.where((c) => c.orderId == orderId).toList();
          }
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No messages yet. Open an order and tap Message to contact the other party. Phone numbers stay private.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = items[i];
              final unread = c.unreadFor(uid);
              return ListTile(
                tileColor: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
                title: Text('Order ${c.orderId.isEmpty ? '' : '#${c.orderId.substring(0, c.orderId.length > 6 ? 6 : c.orderId.length)}'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: unread > 0
                    ? CircleAvatar(radius: 11, backgroundColor: AppColors.primary, child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)))
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
}
