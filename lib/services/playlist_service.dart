import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistService {
  final Supabase _supabase = Supabase.instance;

  // Получение плейлистов пользователя без треков (только основные данные)
  Future<List<Map<String, dynamic>>> getUserPlaylists(String userId) async {
    try {
      final response = await _supabase.client.from('list').select('''
            *,
            play_list(
              count
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response.map((playlist) {
        return {
          ...playlist,
          'tracks_count': playlist['play_list'][0]['count'] ?? 0,
        };
      }));
    } catch (e) {
      print('Error fetching playlists: $e');
      return [];
    }
  }

  Future<bool> isTrackInPlaylist(String playlistId, String trackId) async {
    try {
      final response = await _supabase.client
          .from('play_list')
          .select()
          .eq('list_id', playlistId)
          .eq('track_id', trackId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking track in playlist: $e');
      return false;
    }
  }

  // Создание плейлиста с обложкой по умолчанию
  Future<void> createPlaylist(String name, String userId,
      {String? imageUrl}) async {
    try {
      await _supabase.client.from('list').insert({
        'name': name,
        'user_id': userId,
        'image': imageUrl ??
            'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//defaultPlaylistImage.png',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating playlist: $e');
      throw Exception('Failed to create playlist');
    }
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    try {
      await _supabase.client
          .from('play_list')
          .delete()
          .eq('list_id', playlistId)
          .eq('track_id', trackId);
    } catch (e) {
      print('Error removing track from playlist: $e');
      rethrow;
    }
  }

  // Обновление обложки плейлиста
  Future<void> updatePlaylistImage(String playlistId, String imageUrl) async {
    try {
      await _supabase.client
          .from('list')
          .update({'image': imageUrl}).eq('id', playlistId);
    } catch (e) {
      print('Error updating playlist image: $e');
      throw Exception('Failed to update playlist image');
    }
  }

  // Получение треков плейлиста (отдельный запрос)
  Future<List<Map<String, dynamic>>> getPlaylistTracks(
      String playlistId) async {
    try {
      final response = await _supabase.client
          .from('play_list')
          .select('track:track_id(*, author:author_id(*))')
          .eq('list_id', playlistId);

      return List<Map<String, dynamic>>.from(
          response.map((item) => item['track']));
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      return [];
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      await _supabase.client.from('play_list').insert({
        'list_id': playlistId,
        'track_id': trackId,
      });
    } catch (e) {
      print('Error adding track to playlist: $e');
      throw Exception('Failed to add track to playlist');
    }
  }
}
