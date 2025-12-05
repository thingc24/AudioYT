// lib/services/history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/history_entry.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy collection lịch sử của người dùng hiện tại
  CollectionReference<Map<String, dynamic>>? _getHistoryCollection() {
    final user = _auth.currentUser;
    if (user == null) {
      print('Lỗi: Người dùng chưa đăng nhập.');
      return null;
    }
    // Cấu trúc: /users/{userId}/history/{videoId}
    return _firestore.collection('users').doc(user.uid).collection('history');
  }

  // Thêm hoặc cập nhật một mục trong lịch sử
  Future<void> addOrUpdateEntry(HistoryEntry entry) async {
    final collection = _getHistoryCollection();
    if (collection == null) return;

    try {
      // Dùng videoId làm document ID để tự động ghi đè và cập nhật
      await collection.doc(entry.videoId).set(entry.toJson());
      print('✅ Đã lưu lịch sử lên Firestore cho video: ${entry.videoId}');
    } catch (e) {
      print('🔥🔥🔥 LỖI KHI LƯU LỊCH SỬ: $e');
    }
  }

  // Lấy stream của lịch sử để UI tự động cập nhật
  Stream<List<HistoryEntry>> getHistoryStream() {
    final collection = _getHistoryCollection();
    if (collection == null) {
      return Stream.value([]); // Trả về stream rỗng nếu chưa đăng nhập
    }

    return collection
        .orderBy('lastPlayed', descending: true)
        .limit(100) // Giới hạn 100 bài gần nhất
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HistoryEntry.fromSnapshot(doc))
          .toList();
    });
  }

  // ====================================================
  // 🔥 PHẦN TÔI THÊM — BẠN KHÔNG CÓ, NHƯNG CẦN CHO APP
  // ====================================================

  // Lấy lịch sử → dùng cho HistoryPage (không dùng stream)
  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    final collection = _firestore
        .collection("users")
        .doc(userId)
        .collection("history");

    final query = await collection
        .orderBy("lastPlayed", descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();

      // Format thời gian dễ đọc (HH:mm)
      final timestamp = data["lastPlayed"] as Timestamp?;
      final date = timestamp?.toDate();
      final playedAtStr = date != null
          ? "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
          : "--:--";

      return {
        "videoId": data["videoId"],
        "title": data["title"],
        "artist": data["artist"],
        "thumbnail": data["thumbnail"],
        "duration": data["duration"] ?? "0:00",
        "playedAt": playedAtStr,
        "rawDate": date,
      };
    }).toList();
  }

  // Xoá 1 mục lịch sử
  Future<void> deleteEntry(String videoId) async {
    final collection = _getHistoryCollection();
    if (collection == null) return;

    await collection.doc(videoId).delete();
    print("🗑️ Đã xoá lịch sử: $videoId");
  }

  // Xoá toàn bộ lịch sử
  Future<void> clearHistory() async {
    final collection = _getHistoryCollection();
    if (collection == null) return;

    final snapshots = await collection.get();
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }

    print("🔥 Đã xoá toàn bộ lịch sử");
  }
}
