// services/audio_api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audio/services/youtube_api_service.dart';

class AudioApiService {
  // Thay URL này với URL của backend của bạn
  //static const String baseUrl = "https://audio-youtube-eh2c.onrender.com/api";
  // Hoặc localhost nếu test local
  static const String baseUrl = "http://192.168.1.26:5000/api";

  /// Lấy audio stream từ YouTube video
  /// Returns: {url, title, duration, thumbnail, author}
  static Future<Map<String, dynamic>> getAudio(String videoId) async {
    try {
      print('🎯 Fetch audio for videoId: $videoId');
      if (videoId.isEmpty || videoId.length != 11) {
        throw Exception('Video ID không hợp lệ (phải 11 ký tự)');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/audio/$videoId'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
        throw Exception(data['error'] ?? 'Lỗi không xác định');
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetAudio Error: $e');
      rethrow;
    }
  }

  /// Lấy thông tin video (không lấy audio)
  /// Returns: {videoId, title, duration, thumbnail, author, isLiveContent}
  static Future<Map<String, dynamic>> getVideoInfo(String videoId) async {
    try {
      if (videoId.isEmpty || videoId.length != 11) {
        throw Exception('Video ID không hợp lệ');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/video/$videoId'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
        throw Exception(data['error'] ?? 'Lỗi không xác định');
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetVideoInfo Error: $e');
      rethrow;
    }
  }

  /// Tìm kiếm videos trên YouTube
  /// Returns: List<{videoId, title, thumbnail, duration, author, viewCount}>
  static Future<List<dynamic>> search(String query,
      {int maxResults = 10}) async {
    try {
      if (query.trim().isEmpty) {
        throw Exception('Query không được rỗng');
      }

      if (maxResults > 50) {
        throw Exception('MaxResults tối đa là 50');
      }

      // Sử dụng YouTube API để tìm kiếm
      final youtubeService = YouTubeApiService();
      final items = await youtubeService.searchVideos(query);

      // Parse response từ YouTube API thành format mà UI đang expect
      final List<dynamic> results = [];
      for (var item in items.take(maxResults)) {
        final videoId = item['id']?['videoId'] ?? '';
        if (videoId.isEmpty) continue;

        final snippet = item['snippet'] ?? {};
        final thumbnails = snippet['thumbnails'] ?? {};
        final thumbnail = thumbnails['medium']?['url'] ?? 
                         thumbnails['default']?['url'] ?? '';

        results.add({
          'videoId': videoId,
          'title': snippet['title'] ?? 'Unknown',
          'thumbnail': thumbnail,
          'author': snippet['channelTitle'] ?? 'Unknown',
          'viewCount': 'N/A', // YouTube Search API không trả về viewCount, cần gọi thêm API nếu cần
          'duration': null,
        });
      }

      return results;
    } catch (e) {
      print('❌ Search Error: $e');
      rethrow;
    }
  }

  /// Lấy videos trending
  /// Returns: List<{videoId, title, thumbnail, duration, author, viewCount}>
  static Future<List<dynamic>> getTrending() async {
    try {
      // Sử dụng YouTube API để lấy trending videos
      final youtubeService = YouTubeApiService();
      final items = await youtubeService.getTrending();

      // Parse response từ YouTube API thành format mà UI đang expect
      final List<dynamic> results = [];
      for (var item in items) {
        final videoId = item['id'] ?? '';
        if (videoId.isEmpty) continue;

        final snippet = item['snippet'] ?? {};
        final thumbnails = snippet['thumbnails'] ?? {};
        final thumbnail = thumbnails['medium']?['url'] ?? 
                         thumbnails['default']?['url'] ?? '';
        final statistics = item['statistics'] ?? {};
        final viewCount = statistics['viewCount'] ?? '0';

        results.add({
          'videoId': videoId,
          'title': snippet['title'] ?? 'Unknown',
          'thumbnail': thumbnail,
          'author': snippet['channelTitle'] ?? 'Unknown',
          'viewCount': viewCount,
          'duration': null,
        });
      }

      return results;
    } catch (e) {
      print('❌ GetTrending Error: $e');
      rethrow;
    }
  }

  /// Lấy batch audio cho nhiều videos cùng lúc (tối đa 10)
  /// Returns: List<{videoId, url, title, ...} hoặc {videoId, error}>
  static Future<List<dynamic>> getBatchAudio(List<String> videoIds) async {
    try {
      if (videoIds.isEmpty) {
        throw Exception('Danh sách videos không được rỗng');
      }

      if (videoIds.length > 10) {
        throw Exception('Tối đa 10 videos mỗi request');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/audio/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'videoIds': videoIds}),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'] ?? [];
        }
        throw Exception(data['error'] ?? 'Lỗi không xác định');
      } else {
        throw Exception('Lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GetBatchAudio Error: $e');
      rethrow;
    }
  }

  /// Health check - kiểm tra server có chạy không
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health Check Error: $e');
      return false;
    }
  }
}