import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_session.dart';
import '../models/user_profile.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _collection = FirebaseFirestore.instance.collection('sessions');

  /// Save a session and return the new document ID
  Future<String> saveSession(SavedSession session) async {
    final doc = await _collection.add(session.toMap());
    return doc.id;
  }

  final _usersCollection = FirebaseFirestore.instance.collection('users');

  /// Save or update a user's profile
  Future<void> saveProfile(String userId, UserProfile profile) async {
    await _usersCollection.doc(userId).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Get a user's profile from Firestore
  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  /// Stream of sessions, filtered by userId if provided, newest first
  Stream<List<SavedSession>> sessionsStream({String? userId}) {
    Query query = _collection;
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedSession.fromDoc).toList());
  }

  /// Delete a session by ID
  Future<void> deleteSession(String id) => _collection.doc(id).delete();
}
