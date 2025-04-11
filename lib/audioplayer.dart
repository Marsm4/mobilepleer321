import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  final SupabaseClient _supabase = Supabase.instance.client;

  final ValueNotifier<Map<String, dynamic>?> currentTrack = ValueNotifier(null);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isFavorite = ValueNotifier(false);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final List<Map<String, dynamic>> playlist = [];

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _completeSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool get canSkipPrevious => currentIndex.value > 0;
  bool get canSkipNext => currentIndex.value < playlist.length - 1;

  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      position.value = pos;
      if (duration.value.inMilliseconds > 0) {
        progress.value = pos.inMilliseconds / duration.value.inMilliseconds;
      }
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      duration.value = dur;
    });

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (canSkipNext) nextTrack();
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

Future<void> playTrack(
  Map<String, dynamic> track, {
  List<Map<String, dynamic>>? tracks,
  BuildContext? context,
  Duration? initialPosition,
}) async {
  try {
    final url = track['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Invalid audio URL');
    }

    await _player.stop();

    if (tracks != null) {
      playlist
        ..clear()
        ..addAll(tracks);
      currentIndex.value = playlist.indexWhere((t) => t['id'] == track['id']);
    }
    currentTrack.value = Map<String, dynamic>.from(track);
    
    await _player.play(UrlSource(url)).catchError((e) {
      throw Exception('Failed to play audio: ${e.toString()}');
    });
    if (initialPosition != null) {
      await seek(initialPosition);
    }
    await checkIfFavorite();
  } catch (e) {
    debugPrint('Play error: $e');
    _showError(context, 'Playback failed: ${e.toString().replaceAll('Exception: ', '')}');
    rethrow;
  }
}

  Future<void> checkIfFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null || currentTrack.value == null) return;

    try {
      final response = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('track_id', currentTrack.value!['id'].toString())
          .maybeSingle();

      isFavorite.value = response != null;
    } catch (e) {
      debugPrint('Favorite check error: $e');
    }
  }

  Future<void> toggleFavorite() async {
    final user = _supabase.auth.currentUser;
    if (user == null || currentTrack.value == null) return;

    try {
      final trackId = currentTrack.value!['id'].toString();
      final existing = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('track_id', trackId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('track_id', trackId);
        isFavorite.value = false;
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'track_id': trackId,
          'created_at': DateTime.now().toIso8601String(),
        });
        isFavorite.value = true;
      }
    } catch (e) {
      debugPrint('Favorite toggle error: $e');
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playPause() async {
    try {
      if (isPlaying.value) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } catch (e) {
      debugPrint('Play/Pause error: $e');
      isPlaying.value = false;
    }
  }

  Future<void> nextTrack() async {
    if (!canSkipNext) return;
    currentIndex.value++;
    await playTrack(playlist[currentIndex.value]);
  }

  Future<void> previousTrack() async {
    if (!canSkipPrevious) return;
    currentIndex.value--;
    await playTrack(playlist[currentIndex.value]);
  }

final ValueNotifier<List<Map<String, dynamic>>> playlistsNotifier = ValueNotifier([]);

  Future<void> loadUserPlaylists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('list')
          .select('''
            *,
            play_list(
              track:track_id(*, author:author_id(*))
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final playlists = (response as List).map((p) {
        final tracks = (p['play_list'] as List? ?? [])
            .where((t) => t['track'] != null)
            .map((t) => Map<String, dynamic>.from(t['track']))
            .toList();
        
        return {
          ...Map<String, dynamic>.from(p),
          'tracks_count': tracks.length,
          'tracks': tracks,
        };
      }).toList();
      

      playlistsNotifier.value = playlists;
    } catch (e) {
      debugPrint('Ошибка загрузки плейлистов: $e');
      rethrow;
    }
  }

  // Добавление трека в плейлист
Future<void> addToPlaylist(String listId, String trackId) async {
  try {
    await _supabase.from('play_list').insert({
      'list_id': listId,
      'track_id': trackId,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await loadUserPlaylists();
  } on PostgrestException catch (e) {
    if (e.code == '23505') { // duplicate key error
      throw Exception('Трек уже есть в плейлисте');
    }
    rethrow;
  }
}

  // Проверка наличия трека в плейлисте
  Future<bool> isTrackInPlaylist(String listId, String trackId) async {
    final response = await _supabase
        .from('play_list')
        .select()
        .eq('list_id', listId)
        .eq('track_id', trackId)
        .maybeSingle();
    
    return response != null;
  }

  Future<void> removeFromPlaylist(String listId, String trackId) async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', listId)
          .eq('track_id', trackId);
      await loadUserPlaylists();
    } catch (e) {
      debugPrint('Remove from playlist error: $e');
      rethrow;
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', playlistId);
      
      await _supabase
          .from('list')
          .delete()
          .eq('id', playlistId);
      
      await loadUserPlaylists();
    } catch (e) {
      debugPrint('Delete playlist error: $e');
      rethrow;
    }
  }

  void _showError(BuildContext? context, String message) {
    if (context != null && ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
    Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? trackId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Пользователь не авторизован');

    final response = await _supabase
        .from('list')
        .insert({
          'list_name': name,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final playlist = Map<String, dynamic>.from(response);

    if (trackId != null) {
      await addToPlaylist(playlist['id'].toString(), trackId);
    }

    await loadUserPlaylists();
    return playlist;
  }
    Future<void> safeAddToPlaylist(String listId, String trackId) async {
    final exists = await isTrackInPlaylist(listId, trackId);
    if (exists) {
      throw Exception('Трек уже есть в плейлисте');
    }
    await addToPlaylist(listId, trackId);
  }

Future<List<Map<String, dynamic>>> getPlaylistTracks(String listId) async {
  try {
    final response = await _supabase
        .from('play_list')
        .select('track:track_id(*, author:author_id(*))')
        .eq('list_id', listId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((item) => item['track'] != null)
        .map((item) {
          final track = item['track'];
          if (track['url'] == null) {
            debugPrint('Track ${track['id']} has no URL');
          }
          return {
            'id': track['id']?.toString() ?? '',
            'name': track['name']?.toString() ?? 'Без названия',
            'url': track['url']?.toString(), 
            'image': track['image']?.toString(),
            'author': track['author'] != null 
              ? {
                  'name': track['author']['name']?.toString() ?? 'Неизвестный исполнитель',
                  'image': track['author']['image']?.toString(),
                }
              : {'name': 'Неизвестный исполнитель'},
          };
        })
        .where((track) => track['url'] != null) 
        .toList();
  } catch (e) {
    debugPrint('Error loading tracks: $e');
    throw Exception('Failed to load tracks: ${e.toString()}');
  }
}

  Future<void> dispose() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _completeSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
  }
}