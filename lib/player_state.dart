import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as audio;

class PlayerState with ChangeNotifier {
  final audio.AudioPlayer _audioPlayer = audio.AudioPlayer();
  String? _currentTrackUrl;
  String? _currentTrackName;
  String? _currentTrackAuthor;
  String? _currentTrackImage;
  bool _isPlaying = false;
  bool _isLooping = false;
  List<Map<String, dynamic>> _playlist = [];
  int _currentTrackIndex = -1;

  audio.AudioPlayer get audioPlayer => _audioPlayer;
  String? get currentTrackUrl => _currentTrackUrl;
  String? get currentTrackName => _currentTrackName;
  String? get currentTrackAuthor => _currentTrackAuthor;
  String? get currentTrackImage => _currentTrackImage;
  bool get isPlaying => _isPlaying;
  bool get isLooping => _isLooping;
  List<Map<String, dynamic>> get playlist => _playlist;
  int get currentTrackIndex => _currentTrackIndex;

  PlayerState() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!_isLooping && _playlist.isNotEmpty && _currentTrackIndex < _playlist.length - 1) {
        playNext();
      } else if (_isLooping) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      }
    });
  }

  Future<void> playTrack(String url, String name, String author, String? image, 
      {List<Map<String, dynamic>>? playlist, int? index}) async {
    try {
      if (playlist != null) {
        _playlist = playlist;
        _currentTrackIndex = index ?? 0;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(audio.UrlSource(url));
      _currentTrackUrl = url;
      _currentTrackName = name;
      _currentTrackAuthor = author;
      _currentTrackImage = image;
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> playNext() async {
    if (_playlist.isNotEmpty && _currentTrackIndex < _playlist.length - 1) {
      final nextTrack = _playlist[_currentTrackIndex + 1];
      await playTrack(
        nextTrack['url_music'],
        nextTrack['name'] ?? 'Без названия',
        nextTrack['author']?['name'] ?? 'Неизвестный исполнитель',
        nextTrack['image'],
        index: _currentTrackIndex + 1,
      );
    } else if (_isLooping) {
      await playTrack(
        _playlist[0]['url_music'],
        _playlist[0]['name'] ?? 'Без названия',
        _playlist[0]['author']?['name'] ?? 'Неизвестный исполнитель',
        _playlist[0]['image'],
        index: 0,
      );
    }
  }

  Future<void> playPrevious() async {
    if (_playlist.isNotEmpty && _currentTrackIndex > 0) {
      final prevTrack = _playlist[_currentTrackIndex - 1];
      await playTrack(
        prevTrack['url_music'],
        prevTrack['name'] ?? 'Без названия',
        prevTrack['author']?['name'] ?? 'Неизвестный исполнитель',
        prevTrack['image'],
        index: _currentTrackIndex - 1,
      );
    } else if (_isLooping) {
      await playTrack(
        _playlist.last['url_music'],
        _playlist.last['name'] ?? 'Без названия',
        _playlist.last['author']?['name'] ?? 'Неизвестный исполнитель',
        _playlist.last['image'],
        index: _playlist.length - 1,
      );
    }
  }

  Future<void> toggleLoop() async {
    _isLooping = !_isLooping;
    await _audioPlayer.setReleaseMode(
      _isLooping ? audio.ReleaseMode.loop : audio.ReleaseMode.release,
    );
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }
}