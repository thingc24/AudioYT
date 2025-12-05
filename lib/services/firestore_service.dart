import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users collection: users/{uid}
  Future<void> setUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Playlists: users/{uid}/playlists/{playlistId}
  Future<String> createPlaylist(String uid, Map<String, dynamic> playlistData) async {
    final data = Map<String, dynamic>.from(playlistData);
    data.putIfAbsent('createdAt', () => FieldValue.serverTimestamp());
    final ref = await _db.collection('users').doc(uid).collection('playlists').add(data);
    return ref.id;
  }

  Future<void> updatePlaylist(String uid, String playlistId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).collection('playlists').doc(playlistId).set(data, SetOptions(merge: true));
  }

  Future<void> deletePlaylist(String uid, String playlistId) async {
    await _db.collection('users').doc(uid).collection('playlists').doc(playlistId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> listPlaylists(String uid) async {
    return await _db.collection('users').doc(uid).collection('playlists').get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPlaylists(String uid) {
    return _db.collection('users').doc(uid).collection('playlists').snapshots();
  }

  /// Thêm track vào playlist
  Future<void> addTrackToPlaylist(String uid, String playlistId, Map<String, dynamic> trackData) async {
    final playlistRef = _db.collection('users').doc(uid).collection('playlists').doc(playlistId);
    
    // Lấy playlist hiện tại
    final playlistDoc = await playlistRef.get();
    if (!playlistDoc.exists) {
      throw Exception('Playlist not found');
    }
    
    final playlistData = playlistDoc.data()!;
    final tracks = List<Map<String, dynamic>>.from(playlistData['tracks'] ?? []);
    
    // Kiểm tra xem track đã tồn tại chưa (dựa trên videoId hoặc title)
    final trackVideoId = trackData['videoId'];
    final trackTitle = trackData['title'];
    final exists = tracks.any((track) => 
      track['videoId'] == trackVideoId || track['title'] == trackTitle
    );
    
    if (!exists) {
      tracks.add(trackData);
      await playlistRef.update({
        'tracks': tracks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Xóa track khỏi playlist
  Future<void> removeTrackFromPlaylist(String uid, String playlistId, String videoId) async {
    final playlistRef = _db.collection('users').doc(uid).collection('playlists').doc(playlistId);
    
    final playlistDoc = await playlistRef.get();
    if (!playlistDoc.exists) {
      throw Exception('Playlist not found');
    }
    
    final playlistData = playlistDoc.data()!;
    final tracks = List<Map<String, dynamic>>.from(playlistData['tracks'] ?? []);
    
    tracks.removeWhere((track) => track['videoId'] == videoId);
    
    await playlistRef.update({
      'tracks': tracks,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Favorites: users/{uid}/favorites/{trackId}
  Future<void> addFavorite(String uid, String trackId, Map<String, dynamic>? data) async {
    try {
      final docData = Map<String, dynamic>.from(data ?? {});
      docData.putIfAbsent('addedAt', () => FieldValue.serverTimestamp());
      
      print('🔥 Firestore: Adding favorite');
      print('  - Path: users/$uid/favorites/$trackId');
      print('  - Data: $docData');
      
      await _db.collection('users').doc(uid).collection('favorites').doc(trackId).set(docData);
      
      print('✅ Firestore: Favorite added successfully');
    } catch (e) {
      print('❌ Firestore: Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String uid, String trackId) async {
    await _db.collection('users').doc(uid).collection('favorites').doc(trackId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getFavorite(String uid, String trackId) async {
    return await _db.collection('users').doc(uid).collection('favorites').doc(trackId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFavorites(String uid) {
    return _db.collection('users').doc(uid).collection('favorites').snapshots();
  }

  // History: users/{uid}/history/{autoId}
  Future<void> addHistory(String uid, Map<String, dynamic> data) async {
    final docData = Map<String, dynamic>.from(data);
    docData.putIfAbsent('playedAt', () => FieldValue.serverTimestamp());
    await _db.collection('users').doc(uid).collection('history').add(docData);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHistory(String uid, {int limit = 100}) async {
    return await _db.collection('users').doc(uid).collection('history').orderBy('playedAt', descending: true).limit(limit).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamHistory(String uid, {int limit = 100}) {
    return _db.collection('users').doc(uid).collection('history').orderBy('playedAt', descending: true).limit(limit).snapshots();
  }

  // Utility: get current uid from FirebaseAuth
  String? currentUid() {
    final u = FirebaseAuth.instance.currentUser;
    return u?.uid;
  }
}
