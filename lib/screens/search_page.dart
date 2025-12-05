import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio/services/audio_api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> results = [];
  bool loading = false;
  String? searchQuery;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String query) {
    // Hủy timer trước đó
    _debounce?.cancel();

    // Nếu query rỗng, xóa results
    if (query.trim().isEmpty) {
      setState(() {
        results = [];
        searchQuery = null;
      });
      return;
    }

    // Đặt timer 500ms (chờ user ngừng gõ)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    try {
      setState(() {
        loading = true;
        searchQuery = query;
      });

      final data = await AudioApiService.search(query, maxResults: 15);

      setState(() {
        results = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
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

      // Tìm index của video trong danh sách results
      final videoIndex = index ?? results.indexWhere((v) => v['videoId'] == video['videoId']);

      // Chuyển sang player page
      Navigator.pushNamed(context, "/player", arguments: {
        "url": audioData['url'],
        "videoId": video['videoId'], // ← YouTube videoId để lưu favorite
        "title": audioData['title'],
        "artist": audioData['author'],
        "thumbnail": audioData['thumbnail'],
        "suggestedVideos": results, // Danh sách kết quả search làm suggested videos
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
      body: SafeArea(
        child: ListView(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: const Text(
                "Search",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: "Search YouTube...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        results = [];
                        searchQuery = null;
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),

            // Loading
            if (loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Empty State
            if (!loading && searchQuery == null && results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tìm kiếm video để phát",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // No Results
            if (!loading && searchQuery != null && results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.not_interested,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Không tìm thấy kết quả cho \"$searchQuery\"",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Results List
            ...results.asMap().entries.map((entry) {
              return _buildVideoCard(entry.value, index: entry.key);
            }),

            if (results.isNotEmpty)
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(dynamic video, {int? index}) {
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