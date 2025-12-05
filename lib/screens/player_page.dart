import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/audio_provider.dart';
import '../services/firestore_service.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  bool _isInitializing = false;
  final FirestoreService _firestore = FirestoreService();
  late AnimationController _repeatAnimationController;
  late Animation<double> _repeatAnimation;

  @override
  void initState() {
    super.initState();
    // Animation controller cho hiệu ứng replay
    _repeatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _repeatAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _repeatAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _repeatAnimationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audio = Provider.of<AudioProvider>(context, listen: false);
    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    if (args != null) {
      final url = args["url"] ?? '';
      final title = args["title"] ?? 'Unknown';
      final artist = args["artist"] ?? 'Unknown Artist';
      final thumbnail = args["thumbnail"] ?? '';

      // Kiểm tra nếu URL mới khác với URL hiện tại, hoặc chưa được khởi tạo
      if ((!audio.isInitialized || audio.currentUrl != url) && !_isInitializing) {
        _initializeAndLoadAudio(audio, url, title, artist, thumbnail, args);
      }
    }
  }

  Future<void> _initializeAndLoadAudio(
    AudioProvider audio,
    String url,
    String title,
    String artist,
    String thumbnail,
    Map? args,
  ) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Đảm bảo audio handler được khởi tạo
      if (audio.audioHandler == null) {
        await audio.initializeAudioHandler();
      }

      // Lấy context từ arguments
      final videoId = args?['videoId'] ?? '';
      final playlistId = args?['playlistId'];
      final playlistTracks = args?['playlistTracks'] as List<Map<String, dynamic>>?;
      final playlistIndex = args?['playlistIndex'] as int?;
      final suggestedVideos = args?['suggestedVideos'] as List<dynamic>?;
      final suggestedIndex = args?['suggestedIndex'] as int?;

      // Convert suggestedVideos to List<Map<String, dynamic>>
      List<Map<String, dynamic>>? suggestedVideosList;
      if (suggestedVideos != null) {
        suggestedVideosList = suggestedVideos.map((v) => {
          'title': v['title'] ?? '',
          'artist': v['author'] ?? v['artist'] ?? '',
          'thumbnail': v['thumbnail'] ?? '',
          'videoId': v['videoId'] ?? '',
        }).toList();
      }

      await audio.setSong(
        title,
        artist: artist,
        thumbnail: thumbnail,
        url: url,
        videoId: videoId,
        playlistId: playlistId,
        playlistTracks: playlistTracks,
        playlistIndex: playlistIndex,
        suggestedVideos: suggestedVideosList,
        suggestedIndex: suggestedIndex,
      );
      audio.markInitialized();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context, AudioProvider audio) async {
    final uid = _firestore.currentUid();
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    // Lấy videoId từ args
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final videoId = args?['videoId'] ?? args?['url'] ?? audio.currentUrl;
    
    final trackData = {
      'title': audio.currentSong,
      'artist': audio.currentArtist,
      'thumbnail': audio.thumbnailUrl,
      'videoId': videoId,
      'addedAt': DateTime.now().toIso8601String(), // Dùng DateTime thay vì FieldValue.serverTimestamp() vì không hỗ trợ trong arrays
    };

    // Lấy danh sách playlists
    final playlistsSnapshot = await _firestore.listPlaylists(uid);
    final playlists = playlistsSnapshot.docs;

    if (!mounted) return;

    // Hiển thị dialog chọn playlist hoặc tạo mới
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm vào Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Nút tạo playlist mới
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Color(0xFF6750A4)),
                title: const Text('Tạo Playlist Mới'),
                onTap: () => Navigator.pop(context, 'CREATE_NEW'),
              ),
              const Divider(),
              // Danh sách playlists
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Chưa có playlist nào',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...playlists.map((doc) {
                  final data = doc.data();
                  final title = data['title'] ?? 'Unknown';
                  return ListTile(
                    leading: const Icon(Icons.playlist_play, color: Color(0xFF6750A4)),
                    title: Text(title),
                    subtitle: Text('${(data['tracks'] as List?)?.length ?? 0} bài hát'),
                    onTap: () => Navigator.pop(context, doc.id),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'CREATE_NEW') {
      // Tạo playlist mới
      await _showCreatePlaylistAndAddDialog(context, uid, trackData);
    } else {
      // Thêm vào playlist đã chọn
      await _addTrackToPlaylist(context, uid, result, trackData);
    }
  }

  Future<void> _showCreatePlaylistAndAddDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> trackData,
  ) async {
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
      try {
        // Tạo playlist mới với track đầu tiên
        final playlistId = await _firestore.createPlaylist(uid, {
          'title': result,
          'tracks': [trackData],
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tạo playlist "$result" và thêm bài hát')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _addTrackToPlaylist(
    BuildContext context,
    String uid,
    String playlistId,
    Map<String, dynamic> trackData,
  ) async {
    try {
      await _firestore.addTrackToPlaylist(uid, playlistId, trackData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào playlist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi thêm vào playlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Now Playing",
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Album Art
              Hero(
                tag: 'album-art',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    audio.thumbnailUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.music_note, color: Colors.grey, size: 80),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title + Artist + Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.currentSong,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          audio.currentArtist,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Consumer<AudioProvider>(
                    builder: (context, audioProvider, _) {
                      final isFavorite = audioProvider.isFavorite(audio.currentSong);
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : const Color(0xFF94A3B8),
                          size: 28,
                        ),
                        onPressed: () async {
                          try {
                            // Lấy videoId từ args (YouTube videoId) hoặc từ currentUrl
                            final args = ModalRoute.of(context)?.settings.arguments as Map?;
                            // Ưu tiên lấy videoId từ args (YouTube videoId thực sự)
                            // Nếu không có, mới lấy từ url (có thể là audio URL)
                            final videoId = args?['videoId'] ?? args?['url'] ?? audioProvider.currentUrl;
                            
                            await audioProvider.toggleFavorite(
                              audio.currentSong,
                              artist: audio.currentArtist,
                              thumbnail: audio.thumbnailUrl,
                              videoId: videoId,
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
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Progress bar
              Slider(
                value: audio.progress.clamp(0.0, 1.0),
                onChanged: (v) async {
                  final newPos = Duration(
                    milliseconds: (v * audio.duration.inMilliseconds).round(),
                  );
                  await audio.setPosition(newPos);
                },
                activeColor: const Color(0xFF6366F1),
                inactiveColor: const Color(0xFFE2E8F0),
              ),

              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(audio.position), style: const TextStyle(color: Color(0xFF94A3B8))),
                  Text(_formatDuration(audio.duration), style: const TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 12),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Consumer<AudioProvider>(
                    builder: (context, audioProvider, _) {
                      final isRepeating = audioProvider.isRepeating;
                      
                      // Bắt đầu animation khi replay được bật
                      if (isRepeating && !_repeatAnimationController.isAnimating) {
                        _repeatAnimationController.repeat(reverse: true);
                      } else if (!isRepeating && _repeatAnimationController.isAnimating) {
                        _repeatAnimationController.stop();
                        _repeatAnimationController.reset();
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          audioProvider.toggleRepeat();
                        },
                        child: AnimatedBuilder(
                          animation: _repeatAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isRepeating ? _repeatAnimation.value : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isRepeating 
                                      ? const Color(0xFF6750A4).withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.repeat,
                                  color: isRepeating 
                                      ? const Color(0xFF6750A4)
                                      : const Color(0xFF475569),
                                  size: 24,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 36, color: Color(0xFF475569)),
                    onPressed: () async => await audio.previousSong(),
                  ),

                  // PLAY / PAUSE
                  GestureDetector(
                    onTap: () async {
                      await audio.togglePlayPause();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6366F1)),
                      child: Icon(
                        audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 36, color: Color(0xFF475569)),
                    onPressed: () async => await audio.nextSong(),
                  ),

                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Color(0xFF475569)),
                    onPressed: () => _showAddToPlaylistDialog(context, audio),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
