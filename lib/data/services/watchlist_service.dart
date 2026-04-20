import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/watchlist_model.dart';

class WatchlistService {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _watchlistRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('watchlist');

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  /// Fetch the full watchlist, sorted by most recently added.
  Future<List<WatchlistModel>> getWatchlist() async {
    final snap = await _watchlistRef(_uid)
        .orderBy('addedAt', descending: true)
        .get();
    return snap.docs.map(WatchlistModel.fromFirestore).toList();
  }

  /// Add or update an item (upsert — safe to call multiple times).
  Future<void> add(WatchlistModel item) =>
      _watchlistRef(_uid).doc(item.docId).set(item.toFirestore());

  /// Remove an item.
  Future<void> remove(String docId) =>
      _watchlistRef(_uid).doc(docId).delete();

  /// Check if a specific item is already saved.
  Future<bool> isInWatchlist(String docId) async {
    final doc = await _watchlistRef(_uid).doc(docId).get();
    return doc.exists;
  }
}
