import 'package:flutter/material.dart';
import 'package:audio/services/audio_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> trending = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTrending();
  }

  void loadTrending() async {
    try {
      setState(() {
        loading = true;
        errorMessage = null;
      });

      final data = await AudioApiService.getTrending();

      setState(() {
        trending = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi tải trending: $e';
        loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _playAudio(dynamic video, {int? index}) async {
    try {
      // Hiển thị loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Lấy audio stream từ backend
      final audioData = await AudioApiService.getAudio(video['videoId']);

      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog

      // Tìm index của video trong danh sách trending
      final videoIndex = index ?? trending.indexWhere((v) => v['videoId'] == video['videoId']);

      // Chuyển sang player page với audio URL từ backend
      Navigator.pushNamed(context, "/player", arguments: {
        "url": audioData['url'], // ← URL audio từ backend
        "videoId": video['videoId'], // ← YouTube videoId để lưu favorite
        "title": audioData['title'],
        "artist": audioData['author'],
        "thumbnail": audioData['thumbnail'],
        "suggestedVideos": trending, // Danh sách trending làm suggested videos
        "suggestedIndex": videoIndex >= 0 ? videoIndex : -1,
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phát nhạc: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadTrending,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : trending.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Không có videos'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadTrending,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      )
          : ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Trending Now",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...trending.asMap().entries.map((entry) {
            return _buildVideoCard(entry.value, index: entry.key);
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildVideoCard(dynamic video, {required int index}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            video['thumbnail'] ?? '',
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
        title: Text(
          video['title'] ?? 'Unknown',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              video['author'] ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '👁️ ${video['viewCount'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _playAudio(video, index: index),
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
      ),
    );
  }
}