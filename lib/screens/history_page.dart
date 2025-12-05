import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/audio_api_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final uid = _firestore.currentUid();
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final snapshot = await _firestore.getHistory(uid, limit: 100);
      setState(() {
        _allHistory = snapshot.docs;
        _loading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e')),
        );
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredHistory {
    if (_searchQuery.isEmpty) {
      return _allHistory;
    }
    final query = _searchQuery.toLowerCase();
    return _allHistory.where((doc) {
      final data = doc.data();
      final title = (data['title'] ?? '').toString().toLowerCase();
      final artist = (data['artist'] ?? '').toString().toLowerCase();
      return title.contains(query) || artist.contains(query);
    }).toList();
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupByDate(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> history) {
    final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};

    for (var doc in history) {
      final data = doc.data();
      final playedAt = data['playedAt'] as Timestamp?;
      if (playedAt == null) continue;

      final date = playedAt.toDate();
      final dateKey = DateFormat('dd/MM/yyyy').format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(doc);
    }

    // Sort dates descending
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd/MM/yyyy').parse(a);
        final dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    final sortedMap = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }


  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử?'),
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
      // Delete all history documents
      final snapshot = await _firestore.getHistory(uid, limit: 1000);
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _allHistory = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch sử')),
        );
      }
    } catch (e) {
      print('Error clearing history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa lịch sử: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final data = doc.data();
      final videoId = data['videoId'] ?? '';
      final title = data['title'] ?? 'Unknown';
      final artist = data['artist'] ?? 'Unknown';
      final thumbnail = data['thumbnail'] ?? '';

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

      // Chuyển sang player page
      Navigator.pushNamed(context, "/player", arguments: {
        "url": audioUrl,
        "title": title,
        "artist": artist,
        "thumbnail": thumbnail,
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

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Search history...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget buildSectionTitle(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoryCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = data['title'] ?? 'Unknown';
    final artist = data['artist'] ?? 'Unknown';
    final thumbnail = data['thumbnail'] ?? '';
    final playedAt = data['playedAt'] as Timestamp?;
    final startTime = _formatTime(playedAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
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
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              artist,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  startTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _playAudio(doc),
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

  Widget buildHistoryList(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filtered = _filteredHistory;
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.history : Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Chưa có lịch sử phát'
                    : 'Không tìm thấy kết quả',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = _groupByDate(filtered);
    final List<Widget> widgets = [];

    grouped.forEach((date, docs) {
      widgets.add(buildSectionTitle(date));
      for (var doc in docs) {
        widgets.add(buildHistoryCard(context, doc));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "History",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (_allHistory.isNotEmpty)
            GestureDetector(
              onTap: _clearHistory,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.black54),
                  SizedBox(width: 6),
                  Text(
                    "Clear History",
                    style: TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _firestore.currentUid();
    
    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text('Vui lòng đăng nhập để xem lịch sử'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          children: [
            buildHeader(),
            buildSearchBar(),
            buildHistoryList(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
