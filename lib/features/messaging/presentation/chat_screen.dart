import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/conversation_model.dart';
import '../../../models/order.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/chat_crypto.dart';
import '../../../services/chat_outbox_service.dart';
import '../../../services/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  final FarmoraConversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _OutgoingStatus { sending, failed }

/// A message the user sent that the server hasn't confirmed yet. Shown
/// immediately; removed once the realtime stream delivers the real message.
class _Outgoing {
  _Outgoing.text(this.text)
      : image = null,
        kind = ChatAttachmentKind.photo;
  _Outgoing.image(PickedImage this.image, {required this.kind}) : text = null;

  final String localId = UniqueKey().toString();
  final String? text;
  final PickedImage? image;
  final String kind;

  /// Set once the photo is in Storage, so a retry doesn't upload it again.
  StoredImage? uploaded;
  bool proofRecorded = false;
  _OutgoingStatus status = _OutgoingStatus.sending;
  double progress = 0;
  String? error;
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  late final _service = FirestoreService();
  final _picker = ImagePickerHelper();
  final List<_Outgoing> _outgoing = [];
  final Map<String, Future<String>> _decoded = {};
  late final Stream<List<FarmoraMessage>> _messages;
  String? _peerPublicKey;
  bool _keysReady = false;

  FarmoraConversation get _conversation => widget.conversation;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _recipientId => _conversation.participantIds.firstWhere(
        (id) => id != _uid,
        orElse: () => _conversation.participantIds.isNotEmpty
            ? _conversation.participantIds.first
            : '',
      );

  @override
  void initState() {
    super.initState();
    _messages = _service.messagesStream(
      _conversation.id,
    );
    _bootstrapKeys();
    _flushOutbox();
  }

  Future<void> _bootstrapKeys() async {
    try {
      final pub = await ChatCrypto.instance.publicKeyBase64();
      await _service.publishChatPublicKey(pub);
      final peerKey = await _service.fetchChatPublicKey(_recipientId);
      if (mounted) setState(() => _peerPublicKey = peerKey);
    } catch (e, st) {
      // Text can't be encrypted without keys; photos still work.
      userMessage(e, action: 'set up chat encryption', stack: st);
    } finally {
      if (mounted) setState(() => _keysReady = true);
    }
  }

  /// Re-sends text messages that were saved offline for this order.
  Future<void> _flushOutbox() async {
    try {
      final pending = await ChatOutboxService.getPending();
      for (final msg in pending) {
        if (msg.orderId != _conversation.orderId) continue;
        await _service.sendEncryptedMessage(
          orderId: msg.orderId,
          recipientId: msg.recipientId,
          ciphertext: msg.ciphertext,
        );
        await ChatOutboxService.remove(msg);
      }
    } catch (_) {
      // Still offline; the outbox is retried next time the chat opens.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  FarmoraOrder? _order(FarmoraState state) =>
      state.orders.where((o) => o.id == _conversation.orderId).firstOrNull;

  // ── Sending ─────────────────────────────────────────────

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final item = _Outgoing.text(text);
    setState(() => _outgoing.add(item));
    _deliver(item);
  }

  Future<void> _pickAndSendImage({required bool paymentProof}) async {
    final source = await _chooseSource(paymentProof
        ? context.l10n.chatSendDepositSlip
        : context.l10n.chatSendPhoto);
    if (source == null || !mounted) return;
    final PickedImage? image;
    try {
      image = await _picker.pickOne(source: source);
    } catch (e, st) {
      _snack(userMessage(e, action: 'open the photo', stack: st));
      return;
    }
    if (image == null || !mounted) return; // cancelled
    final item = _Outgoing.image(
      image,
      kind: paymentProof
          ? ChatAttachmentKind.paymentProof
          : ChatAttachmentKind.photo,
    );
    setState(() => _outgoing.add(item));
    _deliver(item);
  }

  /// Uploads (if needed) and sends [item]. Safe to call again to retry.
  Future<void> _deliver(_Outgoing item) async {
    final state = context.read<FarmoraState>();
    setState(() {
      item.status = _OutgoingStatus.sending;
      item.error = null;
    });
    String? ciphertext;
    try {
      ChatAttachment? attachment;
      if (item.text != null) {
        final peerKey =
            _peerPublicKey ?? await _service.fetchChatPublicKey(_recipientId);
        if (peerKey == null || peerKey.isEmpty) {
          throw AppException(L10n.current.chatNoPeerKey);
        }
        _peerPublicKey = peerKey;
        ciphertext = await ChatCrypto.instance
            .encrypt(plaintext: item.text!, peerPublicKeyB64: peerKey);
      } else {
        final isProof = item.kind == ChatAttachmentKind.paymentProof;
        item.uploaded ??= isProof
            ? await state.uploadPaymentSlip(
                orderId: _conversation.orderId,
                image: item.image!,
                onProgress: (p) {
                  if (mounted) setState(() => item.progress = p);
                },
              )
            : await _service.uploadChatImage(
                orderId: _conversation.orderId,
                image: item.image!,
                onProgress: (p) {
                  if (mounted) setState(() => item.progress = p);
                },
              );
        if (isProof && !item.proofRecorded) {
          await state.recordPaymentProof(_conversation.orderId, item.uploaded!);
          item.proofRecorded = true;
        }
        attachment = ChatAttachment(
          url: item.uploaded!.url,
          path: item.uploaded!.path,
          kind: item.kind,
        );
      }
      await _service.sendChatMessage(
        conversation: _conversation,
        recipientId: _recipientId,
        ciphertext: ciphertext,
        attachment: attachment,
      );
      if (mounted) setState(() => _outgoing.remove(item));
      if (item.kind == ChatAttachmentKind.paymentProof) {
        _snack(L10n.current.chatReceiptSent);
      }
    } catch (e, st) {
      if (ciphertext != null) {
        // Encrypted but not delivered: keep it in the offline outbox.
        await ChatOutboxService.enqueue(PendingMessage(
          orderId: _conversation.orderId,
          recipientId: _recipientId,
          ciphertext: ciphertext,
        ));
        if (!mounted) return;
        setState(() => _outgoing.remove(item));
        _snack('Saved offline. Will retry automatically.');
        return;
      }
      if (!mounted) return;
      setState(() {
        item.status = _OutgoingStatus.failed;
        item.error = userMessage(e, action: 'send the message', stack: st);
      });
    }
  }

  void _discard(_Outgoing item) => setState(() => _outgoing.remove(item));

  Future<ImageSource?> _chooseSource(String title) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(ctx.l10n.widgetTakePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(ctx.l10n.widgetChooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachMenu(FarmoraOrder? order) async {
    final canSendProof =
        order != null && order.buyerId == _uid && order.canSubmitProof;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(ctx.l10n.chatPhoto),
              subtitle: Text(ctx.l10n.chatPhotoSubtitle),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            if (canSendProof)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.primary),
                title: Text(ctx.l10n.chatPaymentReceipt),
                subtitle:
                    Text(ctx.l10n.chatReceiptSubtitle(order.displayTotal)),
                onTap: () => Navigator.pop(ctx, 'proof'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _pickAndSendImage(paymentProof: choice == 'proof');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Decoding ────────────────────────────────────────────

  Future<String> _decode(FarmoraMessage m) {
    return _decoded.putIfAbsent('${m.id}|${_peerPublicKey ?? ''}', () async {
      final body = m.body;
      if (body.isEmpty) return '';
      final peerKey = _peerPublicKey;
      if (peerKey == null || peerKey.isEmpty) {
        if (body.startsWith('farmora1:')) {
          return body
              .substring('farmora1:'.length)
              .replaceAll(RegExp(r'\.+$'), '');
        }
        if (body.startsWith(ChatCrypto.currentCiphertextPrefix) ||
            body.startsWith(ChatCrypto.ciphertextPrefix)) {
          return _keysReady ? L10n.current.chatEncryptedPlaceholder : '…';
        }
        return body;
      }
      try {
        return await ChatCrypto.instance
            .decrypt(ciphertext: body, peerPublicKeyB64: peerKey);
      } catch (_) {
        return L10n.current.chatUndecryptable;
      }
    });
  }

  // ── UI ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final order = _order(context.watch<FarmoraState>());
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          order == null
              ? l.orderChat
              : l.chatOrderChatWith(order.productName.isNotEmpty
                  ? order.productName
                  : order.title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<FarmoraMessage>>(
              stream: _messages,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _CenteredNote(
                    icon: Icons.cloud_off_outlined,
                    text: userMessage(snap.error!,
                        action: 'load messages', stack: snap.stackTrace),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? const <FarmoraMessage>[];
                if (msgs.isEmpty && _outgoing.isEmpty) {
                  return _CenteredNote(
                    icon: Icons.lock_outline,
                    text: l.chatEmpty,
                  );
                }
                // Newest at the bottom; reverse list keeps it in view.
                final pending = _outgoing.reversed.toList();
                final sent = msgs.reversed.toList();
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length + sent.length,
                  itemBuilder: (context, i) {
                    if (i < pending.length) return _pendingBubble(pending[i]);
                    return _messageBubble(sent[i - pending.length]);
                  },
                );
              },
            ),
          ),
          _composer(order),
        ],
      ),
    );
  }

  Widget _bubble({required bool mine, required Widget child}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  Widget _text(String text, bool mine) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(text,
            style: TextStyle(color: mine ? Colors.white : AppColors.onSurface)),
      );

  Widget _proofLabel(bool mine) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 14, color: mine ? Colors.white : AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(context.l10n.chatPaymentReceipt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: mine ? Colors.white : AppColors.primary)),
            ),
          ],
        ),
      );

  Widget _messageBubble(FarmoraMessage m) {
    final mine = m.senderId == _uid;
    return _bubble(
      mine: mine,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.isPaymentProof) _proofLabel(mine),
          if (m.hasImage)
            Semantics(
              button: true,
              label: m.isPaymentProof
                  ? context.l10n.chatOpenReceipt
                  : context.l10n.chatOpenPhoto,
              child: GestureDetector(
                onTap: () => showImageViewer(context,
                    url: m.attachmentUrl!,
                    title: m.isPaymentProof
                        ? context.l10n.chatPaymentReceipt
                        : context.l10n.chatPhoto),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: SafeImage(
                      path: m.attachmentUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (m.body.isNotEmpty)
            FutureBuilder<String>(
              future: _decode(m),
              builder: (context, dec) => _text(dec.data ?? '…', mine),
            ),
        ],
      ),
    );
  }

  Widget _pendingBubble(_Outgoing item) {
    final failed = item.status == _OutgoingStatus.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Opacity(
          opacity: failed ? 0.6 : 0.85,
          child: _bubble(
            mine: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.kind == ChatAttachmentKind.paymentProof)
                  _proofLabel(true),
                if (item.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(item.image!.bytes, fit: BoxFit.cover),
                          if (!failed)
                            Container(
                              color: Colors.black38,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value:
                                    item.uploaded == null && item.progress > 0
                                        ? item.progress
                                        : null,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (item.text != null) _text(item.text!, true),
                if (!failed)
                  const Padding(
                    padding: EdgeInsets.only(right: 4, top: 2),
                    child:
                        Icon(Icons.schedule, size: 12, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
        if (failed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6),
                  child: Text(item.error ?? context.l10n.chatNotSent,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => _deliver(item),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(context.l10n.chatRetry),
                ),
                TextButton(
                  onPressed: () => _discard(item),
                  child: Text(context.l10n.chatDiscard),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _composer(FarmoraOrder? order) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: context.l10n.chatAttachPhoto,
              onPressed: () => _openAttachMenu(order),
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.primary),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: context.l10n.chatTypeMessage,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: IconButton.filled(
                tooltip: context.l10n.send,
                onPressed: _sendText,
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredNote extends StatelessWidget {
  const _CenteredNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
