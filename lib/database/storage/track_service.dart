import 'package:flutter_application_1/database/storage/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackService {
  final SupabaseClient _supabase;

  TrackService() : _supabase = Supabase.instance.client;

  Future<String> getAuthorName(int authorId) async {
    try {
      final response = await _supabase
          .from('author')
          .select('name')
          .eq('id', authorId)
          .single();

      return response['name'] as String;
    } catch (e) {
      print('Error fetching author: $e');
      return 'Unknown Artist';
    }
  }

  Future<List<Track>> getTracks() async {
    try {
      final response = await _supabase
          .from('track')
          .select('*')
          .order('created_at', ascending: false);

      return response.map((map) => Track.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load tracks: $e');
    }
  }

  Future<List<Track>> getTracksByAuthor(int authorId) async {
    final response = await _supabase
        .from('track')
        .select('*')
        .eq('author_id', authorId);
    
    return response.map((map) => Track.fromMap(map)).toList();
  }
}