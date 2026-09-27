import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/utils/app_errors.dart';
import '../../../core/utils/firebase_values.dart';
import '../../../services/community_service.dart';

/// Admin: content people reported (community posts, chat messages). A
/// reported post can be hidden; any report can be dismissed.
class ContentReportsScreen extends StatelessWidget {
  const ContentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final db = FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l.admReportsTitle)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(userMessage(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text(l.admReportsEmpty));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final d in docs) _ReportCard(doc: d)],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = doc.data();
    final type = (r['targetType'] ?? '').toString();
    final targetId = (r['targetId'] ?? '').toString();
    final created = firebaseDate(r['createdAt']);
    final isPost = type == 'community_post';

    Future<void> run(Future<void> Function() f) async {
      try {
        await f();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(userMessage(e, action: 'moderate')),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.flag_outlined, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${isPost ? l.comTitle : type} · ${r['reason'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (created != null)
                Text(AppFormat.date(created),
                    style: const TextStyle(fontSize: 12)),
            ]),
            if ((r['details'] ?? '').toString().isNotEmpty)
              Text(r['details'].toString()),
            if (isPost && targetId.isNotEmpty)
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('community_posts')
                    .doc(targetId)
                    .get(),
                builder: (context, post) {
                  final p = post.data?.data();
                  if (p == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                        '${p['authorName'] ?? ''}: ${p['text'] ?? ''}'
                        '${p['isDeleted'] == true ? '\n(${l.admReportsHidden})' : ''}'),
                  );
                },
              ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => run(() => doc.reference.delete()),
                  child: Text(l.admReportsDismiss),
                ),
                if (isPost)
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error),
                    onPressed: () => run(() async {
                      await CommunityService().deletePost(targetId);
                      await doc.reference.delete();
                    }),
                    child: Text(l.admReportsHidePost),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
