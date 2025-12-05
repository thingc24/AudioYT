
import 'package:just_audio/just_audio.dart';
import 'dart:async';

import '../services/audio_api_service.dart';
import '../services/history_service.dart';
import '../models/history_entry.dart';
import '../screens/history_page.dart';

// AudioManager.dart
// ...'

class AudioManager {
  final AudioPlayer player = AudioPlayer();
  final HistoryService _historyService = HistoryService();

  StreamSubscription? _positionSubscription;
  bool _isHistorySavedForCurrentTrack = false;
  HistoryEntry? _currentEntry; // Lưu thông tin bài hát đang chuẩn bị phát

  AudioManager() {
    // Theo dõi trạng thái player để quyết định khi nào lưu lịch sử
    player.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _startPlaybackTracking();
      } else {
        _stopPlaybackTracking();
      }
    });

    // Reset cờ khi bài hát thay đổi
    player.sequenceStateStream.listen((_) {
      _isHistorySavedForCurrentTrack = false;
    });
  }

  // Hàm này được gọi từ UI khi người dùng chọn một bài hát
  Future<void> playFromVideoId(String videoId) async {
    try {
      // 1. Gọi API của bạn để lấy thông tin và URL stream
      final audioData = await AudioApiService.getAudio(videoId);

      // 2. Chuẩn bị đối tượng HistoryEntry
      _currentEntry = HistoryEntry(
        videoId: videoId,
        title: audioData['title'],
        artist: audioData['author'], // Khớp với API của bạn
        artworkUrl: audioData['thumbnail'], // Khớp với API của bạn
        duration: audioData['duration'],
        lastPlayed: DateTime.now(), // Thời gian này sẽ được cập nhật lại trước khi lưu
      );

      // 3. Phát nhạc
      await player.setUrl(audioData['url']);
      player.play();

    } catch (e) {
      print("Lỗi khi phát nhạc từ videoId: $e");
      // TODO: Hiển thị lỗi cho người dùng
    }
  }

  void _startPlaybackTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = player.positionStream.listen((position) {
      // Điều kiện lưu: nghe hơn 30 giây VÀ bài này chưa được lưu trong lần phát này
      if (!_isHistorySavedForCurrentTrack && position.inSeconds > 30) {
        print('💾 Đủ điều kiện, đang lưu vào lịch sử...');
        _saveCurrentTrackToHistory();
        _isHistorySavedForCurrentTrack = true; // Đánh dấu đã lưu
        _stopPlaybackTracking(); // Ngừng theo dõi để tiết kiệm tài nguyên
      }
    });
  }

  void _stopPlaybackTracking() {
    _positionSubscription?.cancel();
  }

  Future<void> _saveCurrentTrackToHistory() async {
    if (_currentEntry == null) return;

    // Cập nhật lại thời gian nghe cuối cùng ngay trước khi lưu
    final entryToSave = HistoryEntry(
        videoId: _currentEntry!.videoId,
        title: _currentEntry!.title,
        artist: _currentEntry!.artist,
        artworkUrl: _currentEntry!.artworkUrl,
        duration: _currentEntry!.duration,
        lastPlayed: DateTime.now() // Lấy thời gian hiện tại
    );

    await _historyService.addOrUpdateEntry(entryToSave);
  }

  void dispose() {
    player.dispose();
    _positionSubscription?.cancel();
  }
}
