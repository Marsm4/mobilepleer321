import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/track.dart';

class TrackService {
  final Supabase _supabase = Supabase.instance;

  Future<List<Track>> getAllTracks() async {
    try {
      final response = await _supabase.client
          .from('track')
          .select('''
            *,
            author:author_id(*)
          ''')
          .order('created_at', ascending: false);
      return response.map<Track>((track) => Track.fromSupabase(track)).toList();
    } catch (e) {
      print('Error fetching tracks: $e');
      return [];
    }
  }

  Future<void> deleteTrack(String trackId) async {
    try {
      await _supabase.client.from('track').delete().eq('id', trackId);
    } catch (e) {
      print('Error deleting track: $e');
      rethrow;
    }
  }
}