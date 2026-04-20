import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _userDoc => _db.collection('users').doc(_uid);

  Future<Map<String, dynamic>?> getUserProfile() async {
    final snap = await _userDoc.get();
    return snap.exists ? snap.data() as Map<String, dynamic>? : null;
  }

  Future<void> updateDisplayName(String name) async {
    await Future.wait([
      _userDoc.set({'displayName': name}, SetOptions(merge: true)),
      _auth.currentUser!.updateDisplayName(name),
    ]);
  }

  Future<String> uploadProfilePhoto(File file) async {
    final ref = _storage.ref().child('profile_pictures/$_uid/avatar.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _userDoc.set({'photoUrl': url}, SetOptions(merge: true));
    return url;
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }
}
