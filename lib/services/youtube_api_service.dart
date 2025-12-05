import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeApiService {
  static const String _base = "https://www.googleapis.com/youtube/v3";
  static const String _apiKey = "AIzaSyB8EZIwDtmnrhCM86exVimsFQmRMreauW0";

  /// 🔍 Search videos
  Future<List<dynamic>> searchVideos(String query) async {
    final url = Uri.parse(
      "$_base/search?part=snippet&type=video&maxResults=25&q=$query&key=$_apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data["items"] == null) return [];

    return data["items"];
  }

  /// 🔥 Trending videos
  Future<List<dynamic>> getTrending() async {
    final url = Uri.parse(
      "$_base/videos"
          "?part=snippet,contentDetails,statistics"
          "&chart=mostPopular"
          "&regionCode=VN"          // 🇻🇳 LẤY VIDEO VIỆT NAM
          "&maxResults=25"
          "&key=$_apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    return data["items"] ?? [];
  }

  /// 🎧 Lấy chi tiết video (duration, thumb, title…)
  Future<Map<String, dynamic>?> getVideoDetail(String videoId) async {
    final url = Uri.parse(
      "$_base/videos?part=snippet,contentDetails&key=$_apiKey&id=$videoId",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    if (data["items"] == null || data["items"].isEmpty) return null;

    return data["items"][0];
  }

  /// 📌 Lấy Category (Music, Sport, Education...)
  Future<List<dynamic>> getCategories() async {
    final url = Uri.parse(
      "$_base/videoCategories?part=snippet&regionCode=US&key=$_apiKey",
    );

    final res = await http.get(url);
    final data = jsonDecode(res.body);

    return data["items"] ?? [];
  }
}
