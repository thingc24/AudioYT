import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/audio_provider.dart';
import '../services/firestore_service.dart';
import '../services/audio_api_service.dart';
import 'playlist_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int selectedTab = 0; // 0 = Favorites, 1 = Playlists
  bool isGridView = false;
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load favorites khi trang được mở
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget buildTabButton(String text, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: selectedTab == 0
                    ? "Search favorites..."
                    : "Search playlists...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.grid_view,
                      color: !isGridView ? Colors.grey : Colors.deepPurple),
                  onPressed: () {
                    setState(() {
                      isGridView = true;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.view_list,
                      color: isGridView ? Colors.grey : Colors.deepPurple),
                  onPressed: () {
                    setState(() {
                      isGridView = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playAudio(Map<String, dynamic> favoriteData) async {
    try {
      final title = favoriteData['title'] ?? 'Unknown';
      final artist = favoriteData['artist'] ?? 'Unknown';
      final thumbnail = favoriteData['thumbnail'] ?? '';
      final videoId = favoriteData['videoId'] ?? '';

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

  Widget buildFavoriteCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = data['title'] ?? 'Unknown';
    final artist = data['artist'] ?? 'Unknown';
    final thumbnail = data['thumbnail'] ?? '';
    final audioProvider = Provider.of<AudioProvider>(context);
    final isFavorite = audioProvider.isFavorite(title);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        subtitle: Text(
          artist,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trái tim yêu thích
            GestureDetector(
              onTap: () async {
                try {
                  await audioProvider.toggleFavorite(
                    title,
                    artist: artist,
                    thumbnail: thumbnail,
                    videoId: data['videoId']?.toString(),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi lưu yêu thích: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Nút play
            GestureDetector(
              onTap: () => _playAudio(data),
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
          ],
        ),
      ),
    );
  }

  Widget buildFavoritesList(BuildContext context) {
    final uid = _firestore.currentUid();
    
    if (uid == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Vui lòng đăng nhập để xem favorites",
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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.streamFavorites(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải favorites: ${snapshot.error}',
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No favorites yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the heart icon to add favorites",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter favorites based on search query
        List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final artist = (data['artist'] ?? '').toString().toLowerCase();
            return title.contains(query) || artist.contains(query);
          }).toList();
        }

        if (filteredDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Không tìm thấy kết quả",
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

        return Column(
          children: filteredDocs.map((doc) {
            return buildFavoriteCard(context, doc);
          }).toList(),
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Playlist Mới'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên playlist',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createPlaylist(result);
    }
  }

  Future<void> _createPlaylist(String name) async {
    final uid = _firestore.currentUid();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập')),
        );
      }
      return;
    }

    try {
      await _firestore.createPlaylist(uid, {
        'title': name,
        'tracks': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo playlist "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo playlist: $e')),
        );
      }
    }
  }

  Widget buildPlaylistsList(BuildContext context) {
    final uid = _firestore.currentUid();
    
    if (uid == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Vui lòng đăng nhập để xem playlists",
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

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.streamPlaylists(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi tải playlists: ${snapshot.error}',
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No playlists yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create your first playlist",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Playlist'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter playlists based on search query
        List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(query);
          }).toList();
        }

        if (filteredDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Không tìm thấy kết quả",
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

        return Column(
          children: [
            // Nút tạo playlist mới
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Tạo Playlist Mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Danh sách playlists
            ...filteredDocs.map((doc) {
              return buildPlaylistCard(context, doc);
            }),
          ],
        );
      },
    );
  }

  Widget buildPlaylistCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = data['title'] ?? 'Unknown';
    final tracks = List<Map<String, dynamic>>.from(data['tracks'] ?? []);
    final trackCount = tracks.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF6750A4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.playlist_play,
            color: Color(0xFF6750A4),
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '$trackCount bài hát',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.grey),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailPage(
                  playlistId: doc.id,
                  playlistTitle: title,
                ),
              ),
            );
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailPage(
                playlistId: doc.id,
                playlistTitle: title,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildListContent(BuildContext context) {
    if (selectedTab == 0) {
      return buildFavoritesList(context);
    } else {
      return buildPlaylistsList(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Library",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  buildTabButton("Favorites", 0),
                  const SizedBox(width: 10),
                  buildTabButton("Playlists", 1),
                ],
              ),
            ),
            buildSearchBar(),
            buildListContent(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
