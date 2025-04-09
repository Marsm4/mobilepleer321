import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/track_service.dart';

class AudioPlayerService with ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Track? _currentTrack;
  List<Track> _trackList = [];
  int _currentTrackIndex = 0;
  PlayerState _playerState = PlayerState.stopped;

  // Геттеры
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  Track? get currentTrack => _currentTrack;
  List<Track> get trackList => List.unmodifiable(_trackList);
  int get currentTrackIndex => _currentTrackIndex;
  AudioPlayer get audioPlayer => _audioPlayer;
  PlayerState get playerState => _playerState;

  AudioPlayerService._internal() {
    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _playNextTrack();
    });
  }

  Future<void> loadTrack(
  Track track, {
  List<Track>? trackList,
  int? initialIndex,
  bool autoPlay = true,
}) async {
  _currentTrack = track;
  if (trackList != null) {
    _trackList = trackList;
    _currentTrackIndex = initialIndex ?? _findTrackIndex(track);
  }
  await _audioPlayer.stop();
  await _audioPlayer.setSource(UrlSource(track.musicUrl));
  _position = Duration.zero;
  if (autoPlay) await _audioPlayer.resume();
  notifyListeners();
}

  int _findTrackIndex(Track track) {
    return _trackList.indexWhere((t) => t.id == track.id);
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_playerState == PlayerState.stopped) {
        await _audioPlayer.setSource(UrlSource(_currentTrack!.musicUrl));
      }
      await _audioPlayer.resume();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
    _position = position;
    notifyListeners();
  }


  Future<void> _playNextTrack() async {
    if (_trackList.isEmpty) return;

    // Обнуляем позицию перед загрузкой следующего трека
    _position = Duration.zero;
    _currentTrackIndex = (_currentTrackIndex + 1) % _trackList.length;
    await loadTrack(_trackList[_currentTrackIndex]);
    notifyListeners();
  }

  Future<void> playNextTrack() async {
    await _playNextTrack();
  }

  Future<void> playPreviousTrack() async {
    if (_trackList.isEmpty) return;

    // Обнуляем позицию перед загрузкой предыдущего трека
    _position = Duration.zero;
    _currentTrackIndex = (_currentTrackIndex - 1) % _trackList.length;
    await loadTrack(_trackList[_currentTrackIndex]);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _audioPlayer.dispose();
  }

    Future<void> refreshTracks() async {
    try {
      final tracks = await TrackService().getAllTracks();
      _trackList = tracks;
      notifyListeners();
    } catch (e) {
      print('Error refreshing tracks: $e');
    }
  }
}
