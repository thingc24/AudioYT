import 'package:just_audio/just_audio.dart';
import 'dart:async';

class BufferStatus {
  final Duration? duration;
  final Duration bufferedPosition;
  final Duration currentPosition;
  final ProcessingState processingState;
  final bool isBuffering;

  BufferStatus({
    required this.duration,
    required this.bufferedPosition,
    required this.currentPosition,
    required this.processingState,
    required this.isBuffering,
  });

  double get bufferPercentage {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return bufferedPosition.inMilliseconds / duration!.inMilliseconds;
  }

  @override
  String toString() => 'Buffer: ${bufferPercentage * 100}% (${bufferedPosition.inSeconds}s/${duration?.inSeconds}s) state=$processingState';
}

class BufferMonitor {
  static Stream<BufferStatus> monitorBuffer(AudioPlayer player) {
    return player.playerStateStream.map((state) {
      return BufferStatus(
        duration: player.duration,
        bufferedPosition: player.bufferedPosition,
        currentPosition: player.position,
        processingState: state.processingState,
        isBuffering: state.processingState == ProcessingState.buffering,
      );
    });
  }
}
