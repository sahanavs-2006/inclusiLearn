import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_session.dart';

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

  /// Stream of all sessions, newest first
  Stream<List<SavedSession>> sessionsStream() {
    return _collection
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedSession.fromDoc).toList());
  }

  /// Delete a session by ID
  Future<void> deleteSession(String id) => _collection.doc(id).delete();
}
