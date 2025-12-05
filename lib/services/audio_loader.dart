import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/audio_optimization.dart';

class AudioLoader {
  final AudioPlayer player;
  final int maxRetries;

  AudioLoader(this.player, {this.maxRetries = 3});

  Future<bool> loadMediaItem(MediaItem item) async {
    final url = item.id;
    Duration bufferDelay = const Duration(milliseconds: 500);

    try {
      final quality = await AudioOptimization.checkAudioQuality(url);
      if (quality != null) {
        bufferDelay = AudioOptimization.calculateOptimalBufferDelay(quality.estimatedBitrate);
      }
    } catch (e) {
      print('audio quality check failed: $e');
    }

    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        try {
          final source = AudioSource.uri(Uri.parse(url));
          await player.setAudioSource(source);
        } catch (e) {
          await player.setUrl(url);
        }

        await Future.delayed(bufferDelay);

        if (player.processingState == ProcessingState.ready || player.processingState == ProcessingState.buffering) {
          await player.play();
          return true;
        }

        throw Exception('Player not ready after buffering (state: ${player.processingState})');
      } catch (e) {
        attempt++;
        print('load attempt $attempt failed for $url: $e');
        if (attempt >= maxRetries) break;
        final backoff = Duration(milliseconds: 400 * attempt);
        await Future.delayed(backoff);
      }
    }

    return false;
  }

  Future<void> preloadNext(String nextUrl) async {
    final temp = AudioPlayer();
    try {
      await temp.setUrl(nextUrl);
      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      print('preload failed for $nextUrl: $e');
    } finally {
      await temp.dispose();
    }
  }
}

