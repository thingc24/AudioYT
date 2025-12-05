// lib/models/history_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryEntry {
  final String videoId; // Dùng làm ID trên Firestore
  final String title;
  final String artist; // Trong API của bạn là 'author'
  final String? artworkUrl; // Trong API của bạn là 'thumbnail'
  final int duration; // tính bằng giây
  final DateTime lastPlayed;

  HistoryEntry({
    required this.videoId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    required this.duration,
    required this.lastPlayed,
  });

  // ==========================
  // 🔥 THÊM: format duration
  // ==========================
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return "${minutes.toString()}:${seconds.toString().padLeft(2, '0')}";
  }

  // ==========================
  // 🔥 THÊM: format giờ nghe
  // ==========================
  String get playedAtFormatted {
    final h = lastPlayed.hour.toString().padLeft(2, '0');
    final m = lastPlayed.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // ==========================
  // 🔥 THÊM: lấy ngày dạng dd/MM/yyyy
  // ==========================
  String get playedDate {
    final d = lastPlayed.day.toString().padLeft(2, '0');
    final mo = lastPlayed.month.toString().padLeft(2, '0');
    final y = lastPlayed.year;
    return "$d/$mo/$y";
  }

  // Chuyển đổi đối tượng thành Map để gửi lên Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'duration': duration,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
    };
  }

  // Tạo đối tượng từ DocumentSnapshot của Firestore
  factory HistoryEntry.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HistoryEntry(
      videoId: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      artist: data['artist'] ?? 'Không rõ nghệ sĩ',
      artworkUrl: data['artworkUrl'],
      duration: data['duration'] ?? 0,
      lastPlayed: (data['lastPlayed'] as Timestamp).toDate(),
    );
  }
}
