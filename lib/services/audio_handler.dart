import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_loader.dart';

class AppAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;

  late final AudioLoader _loader;

  AppAudioHandler() {
    _loader = AudioLoader(_player);

    // Khởi tạo playbackState ban đầu TRƯỚC khi gọi _init()
    playbackState.add(PlaybackState(
      controls: [],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
      bufferedPosition: Duration.zero,
      speed: 1.0,
      queueIndex: 0,
    ));
    _init();
  }

  void _init() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      final processingState = state.processingState == ProcessingState.loading
          ? AudioProcessingState.loading
          : state.processingState == ProcessingState.buffering
              ? AudioProcessingState.buffering
              : state.processingState == ProcessingState.ready
                  ? AudioProcessingState.ready
                  : AudioProcessingState.idle;

      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing)
            MediaControl.pause
          else
            MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ));
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(
        updatePosition: position,
      ));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        final item = _queue.isNotEmpty ? _queue[_currentIndex] : null;
        if (item != null) {
          mediaItem.add(item.copyWith(duration: duration));
        }
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    final item = _queue[index];
    await _loadMediaItem(item);
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      await skipToQueueItem(_currentIndex);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await skipToQueueItem(_currentIndex);
    }
  }

  Future<void> _loadMediaItem(MediaItem item) async {
    try {
      queue.add(_queue);
      mediaItem.add(item);

      // Use Level3 loader (retry + dynamic buffer + preload options)
      final success = await _loader.loadMediaItem(item);

      if (!success) {
        print('AppAudioHandler: failed to load media item ${item.id} via Level3 loader');
      }
    } catch (e) {
      print('Error loading media item: $e');
    }
  }

  Future<void> setMediaItem(MediaItem item) async {
    _queue.clear();
    _queue.add(item);
    _currentIndex = 0;
    await _loadMediaItem(item);
  }

  Future<void> addQueueItem(MediaItem item) async {
    _queue.add(item);
    queue.add(_queue);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    // Chỉ dừng nếu chưa bắt đầu phát, để notification phát nhạc hiển thị khi app thoát
    if (!_player.playing) {
      await stop();
    }
    return super.onTaskRemoved();
  }

  // Cleanup method - gọi khi cần dispose
  Future<void> dispose() async {
    await _player.dispose();
  }

  AudioPlayer get player => _player;
}
