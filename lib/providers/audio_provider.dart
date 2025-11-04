import 'package:flutter/material.dart';

class AudioProvider extends ChangeNotifier {
  bool _isPlaying = false;
  String _currentSong = "Lofi Chill Mix";

  bool get isPlaying => _isPlaying;
  String get currentSong => _currentSong;

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setSong(String song) {
    _currentSong = song;
    notifyListeners();
  }
}
