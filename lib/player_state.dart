import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AppPlayerState extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _currentTrackId;
  String? _currentTrackTitle;
  String? _currentTrackAuthor;
  String? _currentTrackImage;
  String? _currentTrackUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration? _currentPosition;
  Duration? _currentDuration;
  
  // Геттеры
  String? get currentTrackId => _currentTrackId;
  String? get currentTrackUrl => _currentTrackUrl;
  String? get currentTrackTitle => _currentTrackTitle;
  String? get currentTrackAuthor => _currentTrackAuthor;
  String? get currentTrackImage => _currentTrackImage;
  bool get isPlaying => _playerState == PlayerState.playing;
  Duration? get currentPosition => _currentPosition;
  Duration? get currentDuration => _currentDuration;

   List<Map<String, dynamic>> _playlist = [];
  int? _currentTrackIndex;

  Future<void> playTrack(
    String url, 
    String title, 
    String author, 
    String? image, {
    List<Map<String, dynamic>>? playlist,
    int? index,
  }) async {
    if (playlist != null) {
      _playlist = playlist;
      _currentTrackIndex = index;
    }

    _currentTrackUrl = url;
    _currentTrackTitle = title;
    _currentTrackAuthor = author;
    _currentTrackImage = image;
    _currentPosition = Duration.zero;
    
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentTrackUrl == null) return;
    
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    notifyListeners();
  }

  Future<void> nextTrack() async {
    // Реализуйте логику перехода к следующему треку
    notifyListeners();
  }

  Future<void> previousTrack() async {
    // Реализуйте логику перехода к предыдущему треку
    notifyListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      _currentDuration = duration;
      notifyListeners();
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  AppPlayerState() {
    _setupListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}