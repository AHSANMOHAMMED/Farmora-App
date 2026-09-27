import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/firebase_values.dart';
import 'service_errors.dart';

/// A community feed post (`community_posts`).
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  factory CommunityPost.fromMap(String id, Map<String, dynamic> d) =>
      CommunityPost(
        id: id,
        authorId: (d['authorId'] ?? '').toString(),
        authorName: (d['authorName'] ?? '').toString(),
        authorRole: (d['authorRole'] ?? '').toString(),
        text: (d['text'] ?? '').toString(),
        imageUrl: (d['imageUrl'] ?? '').toString().isEmpty
            ? null
            : d['imageUrl'].toString(),
        likeCount: firebaseInt(d['likeCount']) ?? 0,
        commentCount: firebaseInt(d['commentCount']) ?? 0,
        createdAt: firebaseDate(d['createdAt']),
      );
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;

  factory PostComment.fromMap(String id, Map<String, dynamic> d) =>
      PostComment(
        id: id,
        authorId: (d['authorId'] ?? '').toString(),
        authorName: (d['authorName'] ?? '').toString(),
        text: (d['text'] ?? '').toString(),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Topics a farmer can ask an expert about.
const kConsultTopics = ['crop', 'pest', 'soil', 'livestock', 'market', 'other'];

/// A farmer's question to an agri expert (`consultations`).
/// open → claimed (an expert takes it) → answered → closed (rated), or
/// cancelled by the farmer while open.
class Consultation {
  const Consultation({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.topic,
    required this.question,
    required this.status,
    this.imageUrl,
    this.expertId = '',
    this.expertName = '',
    this.answer = '',
    this.rating,
    this.createdAt,
  });

  final String id;
  final String farmerId;
  final String farmerName;
  final String topic;
  final String question;
  final String status;
  final String? imageUrl;
  final String expertId;
  final String expertName;
  final String answer;
  final int? rating;
  final DateTime? createdAt;

  factory Consultation.fromMap(String id, Map<String, dynamic> d) =>
      Consultation(
        id: id,
        farmerId: (d['farmerId'] ?? '').toString(),
        farmerName: (d['farmerName'] ?? '').toString(),
        topic: (d['topic'] ?? 'other').toString(),
        question: (d['question'] ?? '').toString(),
        status: (d['status'] ?? 'open').toString(),
        imageUrl: (d['imageUrl'] ?? '').toString().isEmpty
            ? null
            : d['imageUrl'].toString(),
        expertId: (d['expertId'] ?? '').toString(),
        expertName: (d['expertName'] ?? '').toString(),
        answer: (d['answer'] ?? '').toString(),
        rating: firebaseInt(d['rating']),
        createdAt: firebaseDate(d['createdAt']),
      );
}

/// Community feed and expert consultations. Plain client writes; the
/// counters and state machine are enforced by `firestore.rules`.
class CommunityService {
  CommunityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get uid {
    final id = _auth.currentUser?.uid;
    if (id == null) throw UserStateError('Authentication required.');
    return id;
  }

  Future<(String, String)> _me() async {
    final me = (await _db.collection('users').doc(uid).get()).data() ?? {};
    final name = (me['displayName'] ?? me['name'] ?? '').toString().trim();
    return (name.isEmpty ? 'Member' : name, (me['role'] ?? '').toString());
  }

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('community_posts');

  // ── Feed ────────────────────────────────────────────────────

  Stream<List<CommunityPost>> feed({int limit = 25}) => _posts
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => CommunityPost.fromMap(d.id, d.data())).toList());

  Future<void> createPost(String text, {String? imageUrl}) async {
    final body = text.trim();
    if (body.isEmpty || body.length > 2000) {
      throw UserArgumentError('Write something (up to 2000 characters).');
    }
    final (name, role) = await _me();
    await _posts.add({
      'authorId': uid,
      'authorName': name,
      'authorRole': role,
      'text': body,
      'imageUrl': imageUrl,
      'likeCount': 0,
      'commentCount': 0,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Author or admin hides a post (soft delete).
  Future<void> deletePost(String postId) => _posts.doc(postId).update({
        'isDeleted': true,
        'deletedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Stream<bool> likedByMe(String postId) => _posts
      .doc(postId)
      .collection('likes')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists);

  /// Like / unlike together with the counter (rules require both).
  Future<void> setLiked(String postId, bool like) async {
    final batch = _db.batch();
    final likeRef = _posts.doc(postId).collection('likes').doc(uid);
    if (like) {
      batch.set(likeRef, {'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(likeRef);
    }
    batch.update(_posts.doc(postId), {
      'likeCount': FieldValue.increment(like ? 1 : -1),
    });
    await batch.commit();
  }

  Stream<List<PostComment>> comments(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .limit(200)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => PostComment.fromMap(d.id, d.data())).toList());

  Future<void> addComment(String postId, String text) async {
    final body = text.trim();
    if (body.isEmpty || body.length > 1000) {
      throw UserArgumentError('Write a comment (up to 1000 characters).');
    }
    final (name, _) = await _me();
    final batch = _db.batch();
    batch.set(_posts.doc(postId).collection('comments').doc(), {
      'authorId': uid,
      'authorName': name,
      'text': body,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(postId), {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteComment(String postId, String commentId) =>
      _posts.doc(postId).collection('comments').doc(commentId).delete();

  /// Flags a post for admin review (the existing `reports` collection).
  Future<void> reportPost(String postId, String reason) =>
      _db.collection('reports').add({
        'reporterId': uid,
        'targetType': 'community_post',
        'targetId': postId,
        'reason': reason.trim().isEmpty ? 'Inappropriate' : reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ── Consultations ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _consults =>
      _db.collection('consultations');

  Stream<List<Consultation>> _list(Query<Map<String, dynamic>> q) => q
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => Consultation.fromMap(d.id, d.data())).toList());

  Stream<List<Consultation>> myQuestions() =>
      _list(_consults.where('farmerId', isEqualTo: uid));

  Stream<List<Consultation>> openQuestions() =>
      _list(_consults.where('status', isEqualTo: 'open'));

  Stream<List<Consultation>> myCases() =>
      _list(_consults.where('expertId', isEqualTo: uid));

  Stream<Consultation?> watch(String id) => _consults
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Consultation.fromMap(d.id, d.data()!) : null);

  Future<void> ask({
    required String topic,
    required String question,
    String? imageUrl,
  }) async {
    final text = question.trim();
    if (!kConsultTopics.contains(topic) || text.length < 10 || text.length > 2000) {
      throw UserArgumentError('Describe the problem (at least 10 characters).');
    }
    final (name, _) = await _me();
    await _consults.add({
      'farmerId': uid,
      'farmerName': name,
      'topic': topic,
      'question': text,
      'imageUrl': imageUrl,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _set(String id, Map<String, dynamic> data) => _consults
      .doc(id)
      .update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> claim(Consultation c) async {
    final (name, _) = await _me();
    await _set(c.id, {
      'status': 'claimed',
      'expertId': uid,
      'expertName': name,
      'claimedAt': FieldValue.serverTimestamp(),
    });
    await _notify(c.farmerId, 'An expert is on your question',
        '$name is looking at your ${c.topic} question.', c.id);
  }

  Future<void> answer(Consultation c, String text) async {
    final body = text.trim();
    if (body.length < 5 || body.length > 4000) {
      throw UserArgumentError('Write an answer (5–4000 characters).');
    }
    await _set(c.id, {
      'status': 'answered',
      'answer': body,
      'answeredAt': FieldValue.serverTimestamp(),
    });
    await _notify(c.farmerId, 'Your question was answered',
        '${c.expertName.isEmpty ? 'An expert' : c.expertName} answered your question.',
        c.id);
  }

  Future<void> close(Consultation c, int rating) => _set(c.id, {
        'status': 'closed',
        'rating': rating.clamp(1, 5),
        'closedAt': FieldValue.serverTimestamp(),
      });

  Future<void> cancel(Consultation c) => _set(c.id, {'status': 'cancelled'});

  Future<void> _notify(
      String userId, String title, String body, String refId) async {
    if (userId.isEmpty || userId == _auth.currentUser?.uid) return;
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'consultation',
        'referenceId': refId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best effort.
    }
  }
}
