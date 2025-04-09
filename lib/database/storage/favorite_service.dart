import 'package:flutter_application_1/database/storage/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Track>> getFavoriteTracks(String userId) async {
    final response = await supabase
        .from('favorite_tracks')
        .select('track:track_id(*)')
        .eq('user_id', userId);
    
    return response.map((t) => Track.fromMap(t['track'])).toList();
  }

  Future<void> addFavorite(String userId, int trackId) async {
    await supabase
        .from('favorite_tracks')
        .insert({'user_id': userId, 'track_id': trackId});
  }

  Future<void> removeFavorite(String userId, int trackId) async {
    await supabase
        .from('favorite_tracks')
        .delete()
        .eq('user_id', userId)
        .eq('track_id', trackId);
  }

  Future<bool> isFavorite(String userId, int trackId) async {
    final response = await supabase
        .from('favorite_tracks')
        .select()
        .eq('user_id', userId)
        .eq('track_id', trackId);
    
    return response.isNotEmpty;
  }
}