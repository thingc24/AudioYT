import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/audio_api_service.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String playlistTitle;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistTitle,
  });

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final FirestoreService _firestore = FirestoreService();

  Future<void> _playAudio(Map<String, dynamic> track, List<Map<String, dynamic>> allTracks, int index) async {
    try {
      final title = track['title'] ?? 'Unknown';
      final artist = track['artist'] ?? 'Unknown';
      final thumbnail = track['thumbnail'] ?? '';
      final videoId = track['videoId'] ?? '';

      if (videoId.isEmpty) {
        throw Exception('Không tìm thấy video ID');
      }

      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      String audioUrl;
      
      // Kiểm tra xem videoId có phải là URL audio không (chứa http)
      if (videoId.startsWith('http')) {
        // Nếu là URL audio trực tiếp, dùng luôn
        audioUrl = videoId;
      } else {
        // Nếu là videoId, gọi backend để lấy audio URL
        final audioData = await AudioApiService.getAudio(videoId);
        audioUrl = audioData['url'] ?? '';
      }

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog

      if (audioUrl.isEmpty) {
        throw Exception('Không thể lấy audio URL');
      }

      // Chuyển sang player page với context playlist
      Navigator.pushNamed(context, "/player", arguments: {
        "url": audioUrl,
        "videoId": videoId,
        "title": title,
        "artist": artist,
        "thumbnail": thumbnail,
        "playlistId": widget.playlistId,
        "playlistTracks": allTracks,
        "playlistIndex": index,
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog nếu còn mở
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phát nhạc: $e')),
        );
      }
    }
  }

  Future<void> _removeTrack(String videoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài hát'),
        content: const Text('Bạn có chắc chắn muốn xóa bài hát này khỏi playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final uid = _firestore.currentUid();
    if (uid == null) return;

    try {
      await _firestore.removeTrackFromPlaylist(uid, widget.playlistId, videoId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài hát khỏi playlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa bài hát: $e')),
        );
      }
    }
  }

  Widget buildTrackCard(Map<String, dynamic> track, int index, List<Map<String, dynamic>> allTracks) {
    final title = track['title'] ?? 'Unknown';
    final artist = track['artist'] ?? 'Unknown';
    final thumbnail = track['thumbnail'] ?? '';
    final videoId = track['videoId'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbnail,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  );
                },
              ),
            ),
            // Số thứ tự
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          artist,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nút play
            GestureDetector(
              onTap: () => _playAudio(track, allTracks, index),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF6750A4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            // Nút xóa
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeTrack(videoId),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firestore.currentUid();

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.playlistTitle),
        ),
        body: const Center(
          child: Text('Vui lòng đăng nhập'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.playlistTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('playlists')
            .doc(widget.playlistId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải playlist: ${snapshot.error}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_remove,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Playlist không tồn tại',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final playlistData = snapshot.data!.data()!;
          final tracks = List<Map<String, dynamic>>.from(playlistData['tracks'] ?? []);

          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Playlist trống',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm bài hát vào playlist từ player page',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              // Header với thông tin playlist
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6750A4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.playlist_play,
                        color: Color(0xFF6750A4),
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.playlistTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${tracks.length} bài hát',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                  // Danh sách tracks
                  ...tracks.asMap().entries.map((entry) {
                    return buildTrackCard(entry.value, entry.key, tracks);
                  }),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
