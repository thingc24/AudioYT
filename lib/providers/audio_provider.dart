import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/audio_handler.dart';
import '../services/firestore_service.dart';
import '../services/audio_api_service.dart';

class AudioProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  AppAudioHandler? _audioHandler;
  AudioPlayer? _player;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;
  
  AudioPlayer get player {
    // Luôn ưu tiên sử dụng player từ audioHandler nếu có
    if (_audioHandler != null) {
      _player = _audioHandler!.player;
      return _player!;
    }
    // Chỉ tạo player mới nếu chưa có và chưa có audioHandler
    _player ??= AudioPlayer();
    return _player!;
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    super.dispose();
  }
  
  AppAudioHandler? get audioHandler => _audioHandler;
  
  Future<void> initializeAudioHandler() async {
    if (_audioHandler == null) {
      _audioHandler = await AudioService.init(
        builder: () => AppAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.audio.app.channel.audio',
          androidNotificationChannelName: 'Audio Playback',
          androidNotificationChannelDescription: 'Audio playback controls',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'drawable/ic_audio_notification',
        ),
      );
      _player = _audioHandler!.player;
      _attachPlayerListeners();
    }
  }

  void _attachPlayerListeners() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();

    if (_player == null) return;

    _durationSub = _player!.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    _positionSub = _player!.positionStream.listen((position) {
      _position = position;
      
      // Kiểm tra nếu audio đã kết thúc và replay đang bật
      if (_duration.inMilliseconds > 0 && 
          position.inMilliseconds >= _duration.inMilliseconds - 100 && 
          _isRepeating) {
        // Tự động phát lại từ đầu (trừ 100ms để tránh loop vô hạn)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_isRepeating && _player != null) {
            _player!.seek(Duration.zero);
            _player!.play();
          }
        });
      }
      
      notifyListeners();
    });

    _playerStateSub = _player!.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }
  bool _isPlaying = false;
  bool _isRepeating = false;
  String _currentSong = '';
  String _currentArtist = '';
  String _thumbnailUrl = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _hasCurrentSong = false;
  final Set<String> _favorites = {};

  bool get isPlaying => _isPlaying;
  bool get isRepeating => _isRepeating;
  String get currentSong => _currentSong;
  String get currentArtist => _currentArtist;
  String get thumbnailUrl => _thumbnailUrl;
  Duration get duration => _duration;
  Duration get position => _position;
  bool get hasCurrentSong => _hasCurrentSong;
  Set<String> get favorites => _favorites;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;


  bool isInitialized = false;
  String _currentUrl = '';

  String get currentUrl => _currentUrl;

  // Context cho next/previous
  String? _playlistId;
  List<Map<String, dynamic>> _playlistTracks = [];
  int _currentPlaylistIndex = -1;
  List<Map<String, dynamic>> _suggestedVideos = [];
  int _currentSuggestedIndex = -1;
  List<Map<String, dynamic>> _playHistory = []; // Lịch sử các bài đã phát (cho previous)

  String? get playlistId => _playlistId;

  void markInitialized() {
    isInitialized = true;
  }

  bool isFavorite(String songTitle) {
    return _favorites.contains(songTitle);
  }

  /// Load favorites từ Firestore
  Future<void> loadFavorites() async {
    final uid = _firestore.currentUid();
    if (uid == null) return;

    try {
      final snapshot = await _firestore.streamFavorites(uid).first;
      _favorites.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        if (title != null) {
          _favorites.add(title);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String songTitle, {String? artist, String? thumbnail, String? videoId}) async {
    final uid = _firestore.currentUid();
    
    if (uid == null) {
      print('⚠️ Cannot toggle favorite: User not logged in');
      return;
    }
    
    try {
      if (_favorites.contains(songTitle)) {
        // Remove favorite
        _favorites.remove(songTitle);
        print('🗑️ Removing favorite: $songTitle');
        await _firestore.removeFavorite(uid, songTitle);
        print('✅ Favorite removed from Firestore');
      } else {
        // Add favorite
        _favorites.add(songTitle);
        print('❤️ Adding favorite: $songTitle');
        
        final favoriteData = <String, dynamic>{
          'title': songTitle,
          'addedAt': FieldValue.serverTimestamp(),
        };
        
        // Thêm thông tin bổ sung nếu có
        if (artist != null) {
          favoriteData['artist'] = artist;
          print('  - Artist: $artist');
        }
        if (thumbnail != null) {
          favoriteData['thumbnail'] = thumbnail;
          print('  - Thumbnail: $thumbnail');
        }
        if (videoId != null) {
          favoriteData['videoId'] = videoId;
          print('  - VideoId: $videoId');
        }
        
        print('📝 Saving to Firestore: users/$uid/favorites/$songTitle');
        await _firestore.addFavorite(uid, songTitle, favoriteData);
        print('✅ Favorite saved to Firestore successfully');
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      // Revert local state on error
      if (_favorites.contains(songTitle)) {
        _favorites.remove(songTitle);
      } else {
        _favorites.add(songTitle);
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> createPlaylistForUser(String title, List<Map<String, dynamic>> tracks) async {
    final uid = _firestore.currentUid();
    if (uid == null) return null;
    final playlistId = await _firestore.createPlaylist(uid, {
      'title': title,
      'tracks': tracks,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return playlistId;
  }

  Future<void> setSong(
    String song, {
    String? artist,
    String? thumbnail,
    String? url,
    String? videoId,
    // Context cho next/previous
    String? playlistId,
    List<Map<String, dynamic>>? playlistTracks,
    int? playlistIndex,
    List<Map<String, dynamic>>? suggestedVideos,
    int? suggestedIndex,
  }) async {
    _currentSong = song;
    _currentArtist = artist ?? "Unknown Artist";
    _thumbnailUrl = thumbnail ?? "https://picsum.photos/200?music";
    if (url != null) {
      _currentUrl = url;
    }
    _hasCurrentSong = true;
    _isPlaying = true;
    _position = const Duration(seconds: 0);
    // Tắt replay khi chuyển sang bài mới
    _isRepeating = false;

    // Lưu context cho next/previous
    _playlistId = playlistId;
    _playlistTracks = playlistTracks ?? [];
    _currentPlaylistIndex = playlistIndex ?? -1;
    _suggestedVideos = suggestedVideos ?? [];
    _currentSuggestedIndex = suggestedIndex ?? -1;

    // Thêm vào lịch sử phát (cho previous)
    if (videoId != null && url != null) {
      _playHistory.add({
        'title': song,
        'artist': artist ?? 'Unknown',
        'thumbnail': thumbnail ?? '',
        'videoId': videoId,
        'url': url,
      });
      // Giới hạn lịch sử tối đa 50 bài
      if (_playHistory.length > 50) {
        _playHistory.removeAt(0);
      }
    }

    notifyListeners();
    
    // Cập nhật audio service với media item mới
    if (_audioHandler != null && url != null) {
      try {
        final mediaItem = MediaItem(
          id: url,
          title: song,
          artist: artist ?? "Unknown Artist",
          artUri: Uri.tryParse(thumbnail ?? ''),
        );
        await _audioHandler!.setMediaItem(mediaItem);
        // Đảm bảo _player trỏ đến player từ audioHandler
        _player = _audioHandler!.player;
        _attachPlayerListeners();

        // Lưu history vào Firestore khi bắt đầu playback (nếu user đăng nhập)
        final uid = _firestore.currentUid();
        if (uid != null) {
          await _firestore.addHistory(uid, {
            'videoId': url,
            'title': song,
            'artist': artist ?? 'Unknown',
            'thumbnail': thumbnail ?? '',
            'playedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        print('Error setting media item in audio handler: $e');
      }
    }
  }

  Future<void> setPosition(Duration position) async {
    _position = position;

    if (_audioHandler != null) {
      try {
        await _audioHandler!.seek(position);
      } catch (e) {
        print('Error seeking in audio handler: $e');
      }
    } else {
      // Nếu chưa có audioHandler, sử dụng player trực tiếp
      try {
        await player.seek(position);
      } catch (e) {
        print('Error seeking: $e');
      }
    }
    notifyListeners();
  }

  Future<void> nextSong() async {
    // Nếu đang phát từ playlist
    if (_playlistId != null && _playlistTracks.isNotEmpty) {
      if (_currentPlaylistIndex >= 0 && _currentPlaylistIndex < _playlistTracks.length - 1) {
        // Chuyển đến bài tiếp theo trong playlist
        final nextIndex = _currentPlaylistIndex + 1;
        final nextTrack = _playlistTracks[nextIndex];
        await _playTrackFromContext(
          nextTrack,
          playlistId: _playlistId,
          playlistTracks: _playlistTracks,
          playlistIndex: nextIndex,
        );
        return;
      }
    }

    // Nếu có suggested videos
    if (_suggestedVideos.isNotEmpty) {
      if (_currentSuggestedIndex >= 0 && _currentSuggestedIndex < _suggestedVideos.length - 1) {
        // Chuyển đến video đề xuất tiếp theo
        final nextIndex = _currentSuggestedIndex + 1;
        final nextVideo = _suggestedVideos[nextIndex];
        await _playTrackFromContext(
          nextVideo,
          suggestedVideos: _suggestedVideos,
          suggestedIndex: nextIndex,
        );
        return;
      }
    }

    // Nếu không có next, không làm gì
    print('⚠️ No next song available');
  }

  Future<void> previousSong() async {
    // Nếu đang phát từ playlist
    if (_playlistId != null && _playlistTracks.isNotEmpty) {
      if (_currentPlaylistIndex > 0) {
        // Chuyển về bài trước đó trong playlist
        final prevIndex = _currentPlaylistIndex - 1;
        final prevTrack = _playlistTracks[prevIndex];
        await _playTrackFromContext(
          prevTrack,
          playlistId: _playlistId,
          playlistTracks: _playlistTracks,
          playlistIndex: prevIndex,
        );
        return;
      }
    }

    // Nếu có lịch sử phát (cho previous từ home/search)
    if (_playHistory.length > 1) {
      // Xóa bài hiện tại khỏi history
      _playHistory.removeLast();
      // Lấy bài trước đó
      final prevTrack = _playHistory.last;
      await _playTrackFromContext(
        prevTrack,
        suggestedVideos: _suggestedVideos,
        suggestedIndex: _currentSuggestedIndex > 0 ? _currentSuggestedIndex - 1 : -1,
      );
      return;
    }

    // Nếu không có previous, không làm gì
    print('⚠️ No previous song available');
  }

  Future<void> _playTrackFromContext(
    Map<String, dynamic> track, {
    String? playlistId,
    List<Map<String, dynamic>>? playlistTracks,
    int? playlistIndex,
    List<Map<String, dynamic>>? suggestedVideos,
    int? suggestedIndex,
  }) async {
    try {
      final title = track['title'] ?? 'Unknown';
      final artist = track['artist'] ?? 'Unknown';
      final thumbnail = track['thumbnail'] ?? '';
      final videoId = track['videoId'] ?? '';

      if (videoId.isEmpty) {
        throw Exception('Không tìm thấy video ID');
      }

      String audioUrl;
      
      // Kiểm tra xem videoId có phải là URL audio không
      if (videoId.startsWith('http')) {
        audioUrl = videoId;
      } else {
        // Gọi backend để lấy audio URL
        final audioData = await AudioApiService.getAudio(videoId);
        audioUrl = audioData['url'] ?? '';
      }

      if (audioUrl.isEmpty) {
        throw Exception('Không thể lấy audio URL');
      }

      // Phát bài hát với context
      await setSong(
        title,
        artist: artist,
        thumbnail: thumbnail,
        url: audioUrl,
        videoId: videoId,
        playlistId: playlistId,
        playlistTracks: playlistTracks,
        playlistIndex: playlistIndex,
        suggestedVideos: suggestedVideos,
        suggestedIndex: suggestedIndex,
      );
    } catch (e) {
      print('❌ Error playing next/previous song: $e');
      rethrow;
    }
  }

  void clearCurrentSong() {
    _hasCurrentSong = false;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    await setIsPlaying(!_isPlaying);
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    notifyListeners();
  }

  Future<void> setIsPlaying(bool value) async {
    _isPlaying = value;

    if (_audioHandler != null) {
      try {
        if (value) {
          await _audioHandler!.play();
        } else {
          await _audioHandler!.pause();
        }
      } catch (e) {
        print('Error setting playing state in audio handler: $e');
      }
    } else {
      try {
        if (value) {
          await player.play();
        } else {
          await player.pause();
        }
      } catch (e) {
        print('Error setting playing state: $e');
      }
    }

    notifyListeners();
  }
}
