import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/image_upload.dart';
import '../../../core/widgets/safe_image.dart';
import '../../../models/user_role.dart';
import '../../../providers/farmora_state.dart';
import '../../../services/community_service.dart';
import '../../../services/firebase_service.dart';

void _fail(BuildContext context, Object e, String action) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(userMessage(e, action: action)),
    backgroundColor: AppColors.error,
  ));
}

Widget _note(String text) => Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.onSurfaceVariant)),
    );

String _roleLabel(String role) =>
    Role.values.where((r) => r.name == role).firstOrNull?.label ?? role;

// ── Feed ──────────────────────────────────────────────────────

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key, this.showAppBar = true});

  /// False when shown as a home tab that has its own chrome.
  final bool showAppBar;

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _service = CommunityService();
  final _text = TextEditingController();
  PickedImage? _photo;
  bool _posting = false;
  int _limit = 25;
  late Stream<List<CommunityPost>> _feed = _service.feed(limit: _limit);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      String? url;
      if (_photo != null) {
        url = (await FirestoreService().uploadProductImage(_photo!)).url;
      }
      await _service.createPost(_text.text, imageUrl: url);
      _text.clear();
      setState(() => _photo = null);
    } catch (e) {
      if (mounted) _fail(context, e, 'post');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = context.select<FarmoraState, Role>((s) => s.role);
    final canPost =
        role == Role.farmer || role == Role.expert || role == Role.admin;
    final body = StreamBuilder<List<CommunityPost>>(
      stream: _feed,
      builder: (context, snap) {
        final posts = snap.data ?? const <CommunityPost>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            if (canPost) _composer(l) else _note(l.comReadOnly),
            if (snap.hasError) _note(userMessage(snap.error!)),
            if (!snap.hasData && !snap.hasError)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (snap.hasData && posts.isEmpty) _note(l.comEmpty),
            for (final p in posts) PostCard(post: p, service: _service),
            if (posts.length >= _limit)
              Center(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _limit += 25;
                    _feed = _service.feed(limit: _limit);
                  }),
                  child: Text(l.loadMore),
                ),
              ),
          ],
        );
      },
    );
    if (!widget.showAppBar) return body;
    return Scaffold(appBar: AppBar(title: Text(l.comTitle)), body: body);
  }

  Widget _composer(AppLocalizations l) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _text,
              maxLines: 3,
              minLines: 1,
              maxLength: 2000,
              decoration: InputDecoration(
                  hintText: l.comComposeHint, border: InputBorder.none),
            ),
            if (_photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_photo!.bytes, height: 120, fit: BoxFit.cover),
              ),
            Row(children: [
              IconButton(
                tooltip: l.supAddPhoto,
                icon: const Icon(Icons.photo_outlined),
                onPressed: _posting
                    ? null
                    : () async {
                        final img = await ImagePickerHelper().pickOne();
                        if (img != null) setState(() => _photo = img);
                      },
              ),
              const Spacer(),
              FilledButton(
                onPressed: _posting ? null : _post,
                child: Text(l.comPost),
              ),
            ]),
          ]),
        ),
      );
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.service,
      this.openDetail = true});

  final CommunityPost post;
  final CommunityService service;
  final bool openDetail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.read<FarmoraState>();
    final mine = post.authorId == state.currentUserId;
    final admin = state.role == Role.admin;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: openDetail
            ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post)))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(post.authorName.isEmpty
                      ? '?'
                      : post.authorName[0].toUpperCase()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        [
                          _roleLabel(post.authorRole),
                          if (post.createdAt != null)
                            AppFormat.date(post.createdAt!),
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    try {
                      if (v == 'delete') {
                        await service.deletePost(post.id);
                      } else {
                        await service.reportPost(post.id, 'Inappropriate');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.comReported)));
                        }
                      }
                    } catch (e) {
                      if (context.mounted) _fail(context, e, v);
                    }
                  },
                  itemBuilder: (_) => [
                    if (mine || admin)
                      PopupMenuItem(value: 'delete', child: Text(l.delete)),
                    if (!mine)
                      PopupMenuItem(value: 'report', child: Text(l.comReport)),
                  ],
                ),
              ]),
              const SizedBox(height: 8),
              Text(post.text),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SafeImage(
                      path: post.imageUrl!, height: 200, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 4),
              Row(children: [
                _LikeButton(post: post, service: service),
                const SizedBox(width: 12),
                const Icon(Icons.mode_comment_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(l.comComments('${post.commentCount}'),
                    style: const TextStyle(color: AppColors.onSurfaceVariant)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.post, required this.service});

  final CommunityPost post;
  final CommunityService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
        stream: service.likedByMe(post.id),
        builder: (context, snap) {
          final liked = snap.data ?? false;
          return TextButton.icon(
            onPressed: snap.hasData
                ? () => service
                    .setLiked(post.id, !liked)
                    .catchError((Object e) => _fail(context, e, 'like'))
                : null,
            icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18),
            label: Text('${post.likeCount}'),
          );
        },
      );
}

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _service = CommunityService();
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.addComment(widget.post.id, _comment.text);
      _comment.clear();
    } catch (e) {
      if (mounted) _fail(context, e, 'comment');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = context.read<FarmoraState>();
    return Scaffold(
      appBar: AppBar(title: Text(l.comTitle)),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<PostComment>>(
            stream: _service.comments(widget.post.id),
            builder: (context, snap) => ListView(
              padding: const EdgeInsets.all(12),
              children: [
                PostCard(
                    post: widget.post, service: _service, openDetail: false),
                for (final c in snap.data ?? const <PostComment>[])
                  ListTile(
                    leading: const Icon(Icons.subdirectory_arrow_right),
                    title: Text(c.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.text),
                    trailing: c.authorId == state.currentUserId ||
                            state.role == Role.admin
                        ? IconButton(
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _service
                                .deleteComment(widget.post.id, c.id)
                                .catchError(
                                    (Object e) => _fail(context, e, 'delete')),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _comment,
                  maxLength: 1000,
                  decoration: InputDecoration(
                      hintText: l.comAddComment, counterText: ''),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                tooltip: l.comPost,
                icon: const Icon(Icons.send_rounded),
                onPressed: _sending ? null : _send,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Consultations ─────────────────────────────────────────────

String consultTopicLabel(AppLocalizations l, String t) => switch (t) {
      'crop' => l.conTopicCrop,
      'pest' => l.conTopicPest,
      'soil' => l.conTopicSoil,
      'livestock' => l.conTopicLivestock,
      'market' => l.conTopicMarket,
      _ => l.conTopicOther,
    };

String consultStatusLabel(AppLocalizations l, String s) => switch (s) {
      'claimed' => l.conStatusClaimed,
      'answered' => l.conStatusAnswered,
      'closed' => l.conStatusClosed,
      'cancelled' => l.conStatusCancelled,
      _ => l.conStatusOpen,
    };

Widget _consultTile(BuildContext context, Consultation c) {
  final l = context.l10n;
  return Card(
    child: ListTile(
      leading: const Icon(Icons.support_agent_rounded, color: AppColors.primary),
      title: Text(c.question, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        consultTopicLabel(l, c.topic),
        consultStatusLabel(l, c.status),
        if (c.createdAt != null) AppFormat.date(c.createdAt!),
      ].join(' · ')),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConsultationDetailScreen(id: c.id))),
    ),
  );
}

/// Farmer: their questions to experts, and asking a new one.
class AskExpertScreen extends StatelessWidget {
  const AskExpertScreen({super.key});

  Future<void> _ask(BuildContext context) async {
    final l = context.l10n;
    final question = TextEditingController();
    var topic = 'pest';
    PickedImage? photo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(l.conNewQuestion),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: topic,
                decoration: InputDecoration(labelText: l.conTopic),
                items: [
                  for (final t in kConsultTopics)
                    DropdownMenuItem(
                        value: t, child: Text(consultTopicLabel(l, t))),
                ],
                onChanged: (v) => setDialog(() => topic = v ?? topic),
              ),
              TextField(
                controller: question,
                maxLines: 5,
                maxLength: 2000,
                decoration: InputDecoration(labelText: l.conQuestion),
              ),
              if (photo != null)
                Image.memory(photo!.bytes, height: 100, fit: BoxFit.cover),
              TextButton.icon(
                onPressed: () async {
                  final img = await ImagePickerHelper().pickOne();
                  if (img != null) setDialog(() => photo = img);
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l.conAddPhoto),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.conSend)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      String? url;
      if (photo != null) {
        url = (await FirestoreService().uploadProductImage(photo!)).url;
      }
      await CommunityService()
          .ask(topic: topic, question: question.text, imageUrl: url);
    } catch (e) {
      if (context.mounted) _fail(context, e, 'send the question');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.conAskExpert)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ask(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l.conNewQuestion),
      ),
      body: StreamBuilder<List<Consultation>>(
        stream: CommunityService().myQuestions(),
        builder: (context, snap) {
          if (snap.hasError) return _note(userMessage(snap.error!));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data!.isEmpty) return _note(l.conNoQuestions);
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            children: [for (final c in snap.data!) _consultTile(context, c)],
          );
        },
      ),
    );
  }
}

/// Expert home: open questions and the ones they took.
class ExpertQueueScreen extends StatelessWidget {
  const ExpertQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = CommunityService();
    Widget list(Stream<List<Consultation>> s, String empty) =>
        StreamBuilder<List<Consultation>>(
          stream: s,
          builder: (context, snap) {
            if (snap.hasError) return _note(userMessage(snap.error!));
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.data!.isEmpty) return _note(empty);
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [for (final c in snap.data!) _consultTile(context, c)],
            );
          },
        );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.roleExpert),
          bottom: TabBar(tabs: [
            Tab(text: l.conOpenQueue),
            Tab(text: l.conMyCases),
          ]),
        ),
        body: TabBarView(children: [
          list(service.openQuestions(), l.conQueueEmpty),
          list(service.myCases(), l.conQueueEmpty),
        ]),
      ),
    );
  }
}

class ConsultationDetailScreen extends StatefulWidget {
  const ConsultationDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  final _service = CommunityService();
  final _answer = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _do(Future<void> Function() action, String name) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _fail(context, e, name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final uid = context.read<FarmoraState>().currentUserId;
    return Scaffold(
      appBar: AppBar(title: Text(l.conAskExpert)),
      body: StreamBuilder<Consultation?>(
        stream: _service.watch(widget.id),
        builder: (context, snap) {
          final c = snap.data;
          if (c == null) {
            return snap.hasError
                ? _note(userMessage(snap.error!))
                : const Center(child: CircularProgressIndicator());
          }
          final isFarmer = c.farmerId == uid;
          final isMyCase = c.expertId == uid;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Chip(label: Text(consultStatusLabel(l, c.status))),
              Text('${consultTopicLabel(l, c.topic)} · ${c.farmerName}',
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(c.question, style: const TextStyle(fontSize: 16)),
              if (c.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SafeImage(
                      path: c.imageUrl!, height: 220, fit: BoxFit.cover),
                ),
              ],
              if (c.answer.isNotEmpty) ...[
                const Divider(height: 32),
                Text(l.conAnswerFrom(c.expertName),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(c.answer),
              ],
              const SizedBox(height: 20),
              if (isFarmer && c.status == 'open')
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _do(() => _service.cancel(c), 'cancel'),
                  child: Text(l.conCancelQuestion),
                ),
              if (isFarmer && c.status == 'answered') ...[
                Text(l.conRateAnswer),
                Row(children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i',
                      icon: const Icon(Icons.star_rounded, color: Colors.amber),
                      onPressed: _busy
                          ? null
                          : () => _do(() => _service.close(c, i), 'rate'),
                    ),
                ]),
              ],
              if (c.rating != null)
                Row(children: [
                  for (var i = 1; i <= c.rating!; i++)
                    const Icon(Icons.star_rounded, color: Colors.amber),
                ]),
              if (!isFarmer && c.status == 'open')
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _do(() => _service.claim(c), 'claim'),
                  child: Text(l.conClaim),
                ),
              if (isMyCase && c.status == 'claimed') ...[
                TextField(
                  controller: _answer,
                  maxLines: 6,
                  maxLength: 4000,
                  decoration: InputDecoration(
                      labelText: l.conYourAnswer,
                      border: const OutlineInputBorder()),
                ),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _do(
                          () => _service.answer(c, _answer.text), 'answer'),
                  child: Text(l.conSendAnswer),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
