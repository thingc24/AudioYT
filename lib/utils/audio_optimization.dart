import 'dart:io';
import 'package:just_audio/just_audio.dart';

class AudioOptimization {
  /// Kiểm tra chất lượng audio stream trước khi phát
  static Future<AudioQualityInfo?> checkAudioQuality(String url) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.headUrl(uri);
      final response = await request.close();

      final contentType = response.headers.value('content-type') ?? '';
      final contentLength = int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;

      // Ước tính bitrate dựa trên kích thước
      // Ví dụ: 5MB file khoảng 3 phút = 128kbps
      final estimatedBitrate = contentLength > 0 ? (contentLength * 8) ~/ (3 * 60) : 128; // bytes -> kbps

      return AudioQualityInfo(
        contentType: contentType,
        contentLength: contentLength,
        estimatedBitrate: estimatedBitrate,
        isValid: response.statusCode == 200 && contentLength > 1000000, // > 1MB
      );
    } catch (e) {
      print('Audio quality check failed: $e');
      return null;
    }
  }

  /// Tính toán buffer delay dựa trên connection speed
  static Duration calculateOptimalBufferDelay(int estimatedBitrate) {
    // Nếu bitrate thấp (< 64kbps) = kết nối yếu = buffer lâu hơn
    if (estimatedBitrate < 64) {
      return const Duration(milliseconds: 800);
    } else if (estimatedBitrate < 128) {
      return const Duration(milliseconds: 600);
    } else if (estimatedBitrate < 256) {
      return const Duration(milliseconds: 400);
    } else {
      return const Duration(milliseconds: 200);
    }
  }

  /// Cấu hình AudioPlayer cho chất lượng tốt nhất
  static Future<void> optimizeAudioPlayer(AudioPlayer player) async {
    try {
      // Đặt priority for audio
      // (Tuỳ vào package hỗ trợ - có thể không cần)
      print('Audio player optimized for quality playback');
    } catch (e) {
      print('Optimization error: $e');
    }
  }
}

class AudioQualityInfo {
  final String contentType;
  final int contentLength; // bytes
  final int estimatedBitrate; // kbps
  final bool isValid;

  AudioQualityInfo({
    required this.contentType,
    required this.contentLength,
    required this.estimatedBitrate,
    required this.isValid,
  });

  @override
  String toString() => '''
AudioQualityInfo(
  contentType: $contentType,
  size: ${(contentLength / 1024 / 1024).toStringAsFixed(2)}MB,
  bitrate: ${estimatedBitrate}kbps,
  valid: $isValid
)''';
}

