import 'package:flutter/material.dart';

class AudioProvider extends ChangeNotifier {
  bool _isPlaying = false;
  String _currentSong = "Lofi Chill Mix";
  String _currentArtist = "Chill Vibes";
  String _thumbnailUrl = "https://picsum.photos/200?music";
  Duration _duration = const Duration(minutes: 3, seconds: 45);
  Duration _position = const Duration(seconds: 3);
  bool _hasCurrentSong = true;
  final Set<String> _favorites = {};

  bool get isPlaying => _isPlaying;
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

  bool isFavorite(String songTitle) {
    return _favorites.contains(songTitle);
  }

  void toggleFavorite(String songTitle) {
    if (_favorites.contains(songTitle)) {
      _favorites.remove(songTitle);
    } else {
      _favorites.add(songTitle);
    }
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setSong(String song, {String? artist, String? thumbnail}) {
    _currentSong = song;
    _currentArtist = artist ?? "Unknown Artist";
    _thumbnailUrl = thumbnail ?? "https://picsum.photos/200?music";
    _hasCurrentSong = true;
    _isPlaying = true;
    _position = const Duration(seconds: 0);
    notifyListeners();
  }

  void setPosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  void nextSong() {
    // Placeholder for next song logic
    setSong("Next Song", artist: "Next Artist");
  }

  void previousSong() {
    // Placeholder for previous song logic
    setSong("Previous Song", artist: "Previous Artist");
  }

  void clearCurrentSong() {
    _hasCurrentSong = false;
    _isPlaying = false;
    notifyListeners();
  }
}
