import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Текущий трек
  String? _currentTrackName;
  String? _currentArtist;
  String? _currentTrackUrl;
  String? _currentCoverUrl;
  int? _currentTrackId;
  int? _currentTrackIndex;
  
  // Состояние плеера
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Список треков
  List<Map<String, dynamic>> _trackList = [];
  
  // Избранное
  int? _favoritePlaylistId;
  bool _isCurrentTrackFavorite = false;
  bool _isFavoriteLoading = false;

  PlayerProvider() {
    _setupListeners();
    _initializeFavoritePlaylist();
  }

  void _setupListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = _duration;
      notifyListeners();
      _playNextTrack();
    });
  }

  Future<void> _initializeFavoritePlaylist() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final response = await _supabase
        .from('list')
        .select('id')
        .eq('user_id', currentUser.id)
        .eq('list_name', 'Любимое')
        .single()
        .catchError((_) => null);

    if (response != null) {
      _favoritePlaylistId = response['id'] as int;
    }
  }

  Future<void> _createFavoritePlaylist() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final response = await _supabase
        .from('list')
        .insert({
          'list_name': 'Любимое',
          'user_id': currentUser.id,
        })
        .select('id')
        .single();

    _favoritePlaylistId = response['id'] as int;
  }

  Future<void> _updateFavoriteStatus() async {
    if (_currentTrackId == null) {
      _isCurrentTrackFavorite = false;
      notifyListeners();
      return;
    }

    // Если плейлиста "Любимое" нет - трек точно не в избранном
    if (_favoritePlaylistId == null) {
      _isCurrentTrackFavorite = false;
      notifyListeners();
      return;
    }

    try {
      final existing = await _supabase
          .from('playlist')
          .select('*')
          .eq('list_id', _favoritePlaylistId!)
          .eq('track_id', _currentTrackId!)
          .maybeSingle();

      _isCurrentTrackFavorite = existing != null;
    } catch (e) {
      _isCurrentTrackFavorite = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleFavorite() async {
    if (_currentTrackId == null) return;
    
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      // Если плейлиста "Любимое" нет - создаем
      if (_favoritePlaylistId == null) {
        await _createFavoritePlaylist();
      }

      if (_isCurrentTrackFavorite) {
        // Удаляем из избранного
        await _supabase
            .from('playlist')
            .delete()
            .eq('list_id', _favoritePlaylistId!)
            .eq('track_id', _currentTrackId!);
      } else {
        // Добавляем в избранное
        await _supabase.from('playlist').insert({
          'list_id': _favoritePlaylistId,
          'track_id': _currentTrackId,
        });
      }
      
      // Обновляем статус
      _isCurrentTrackFavorite = !_isCurrentTrackFavorite;
    } catch (e) {
      // В случае ошибки оставляем статус как был
    } finally {
      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> playTrack({
    required String name,
    required String artist,
    required String url,
    String? coverUrl,
    int? index,
    int? trackId,
    List<Map<String, dynamic>>? trackList,
  }) async {
    // Обновляем данные о текущем треке
    _currentTrackName = name;
    _currentArtist = artist;
    _currentTrackUrl = url;
    _currentCoverUrl = coverUrl;
    _currentTrackIndex = index;
    _currentTrackId = trackId;
    
    if (trackList != null) {
      _trackList = trackList;
    }

    // Начинаем воспроизведение
    await _audioPlayer.play(UrlSource(url));
    _isPlaying = true;
    
    // Обновляем статус "избранного" для нового трека
    await _updateFavoriteStatus();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else if (_currentTrackUrl != null) {
      await _audioPlayer.play(UrlSource(_currentTrackUrl!));
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Future<void> _playNextTrack() async {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;
    
    final nextIndex = _currentTrackIndex! + 1;
    if (nextIndex < _trackList.length) {
      final nextTrack = _trackList[nextIndex];
      await playTrack(
        name: nextTrack['name'] ?? 'Без названия',
        artist: nextTrack['artists']['name'] ?? 'Неизвестный исполнитель',
        url: nextTrack['musicurl'] ?? '',
        coverUrl: nextTrack['cover_url'] ?? nextTrack['artists']['image_url'],
        index: nextIndex,
        trackId: nextTrack['id'],
        trackList: _trackList,
      );
    }
  }

  Future<void> playNext() async => _playNextTrack();

  Future<void> playPrevious() async {
    if (_trackList.isEmpty || _currentTrackIndex == null) return;
    
    final prevIndex = _currentTrackIndex! - 1;
    if (prevIndex >= 0) {
      final prevTrack = _trackList[prevIndex];
      await playTrack(
        name: prevTrack['name'] ?? 'Без названия',
        artist: prevTrack['artists']['name'] ?? 'Неизвестный исполнитель',
        url: prevTrack['musicurl'] ?? '',
        coverUrl: prevTrack['cover_url'] ?? prevTrack['artists']['image_url'],
        index: prevIndex,
        trackId: prevTrack['id'],
        trackList: _trackList,
      );
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  // Getters
  String? get currentTrackName => _currentTrackName;
  String? get currentArtist => _currentArtist;
  String? get currentTrackUrl => _currentTrackUrl;
  String? get currentCoverUrl => _currentCoverUrl;
  int? get currentTrackId => _currentTrackId;
  int? get currentTrackIndex => _currentTrackIndex;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  List<Map<String, dynamic>> get trackList => _trackList;
  bool get isCurrentTrackFavorite => _isCurrentTrackFavorite;
  bool get isFavoriteLoading => _isFavoriteLoading;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}