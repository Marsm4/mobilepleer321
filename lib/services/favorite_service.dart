import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteService {
  final Supabase _supabase = Supabase.instance;

  Future<void> addFavorite(String trackId) async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.client.from('favorites').insert({
      'user_id': user.id,
      'track_id': trackId,
    });
  }

  Future<void> removeFavorite(String trackId) async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _supabase.client
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('track_id', trackId);
  }

  Future<List<String>> getUserFavorites() async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase.client
        .from('favorites')
        .select('track_id')
        .eq('user_id', user.id);

    return response.map<String>((fav) => fav['track_id'].toString()).toList();
  }

  Future<bool> isFavorite(String trackId) async {
    final user = _supabase.client.auth.currentUser;
    if (user == null) return false;

    final response = await _supabase.client
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('track_id', trackId)
        .maybeSingle();

    return response != null;
  }
}