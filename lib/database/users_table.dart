import 'package:supabase_flutter/supabase_flutter.dart';


class UsersTable {
  final Supabase _supabase = Supabase.instance;

  Future<void> addUser(String name, String email, String password) async {
    try {
      await _supabase.client.from('users').insert({
        'name':name,
        'email':email,
        'password':password,
        'avatar':'https://rjnwjeopknvsrqsetrsf.supabase.co/storage/v1/object/public/storages//usericon.png',
      });
    }
    catch (e) {
      print(e);
      return;
    }
  }

  Future<void> updateUser(dynamic uid, String url) async {
    
    try {
      await _supabase.client.from('users').update({
        'avatar':url,
      }).eq('id', uid);
    }
    catch (e) {
      return;
    }
  }
  
  Future<void> addUserTrack(String userId, int trackId) async {
    try {
      print(userId);
      print(trackId);
      await _supabase.client.from('usertrack').insert({
        'user_id':userId,
        'track_id':trackId
      });
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> deleteUserTrack(int id) async {
    try {
      await _supabase.client.from('usertrack').delete().eq('id', id);
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> addUserList(String listName, String userId) async {
    print(userId);
    print(listName);
    try {
      await _supabase.client.from('list').insert({
        'list_name':listName,
        'user_id':userId,
      });
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> deleteUserList(String listId) async {
    try {
      await _supabase.client.from('list').delete().eq('id', listId);
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> addTrackToPlaylist(String listId, int trackId) async {
    print(listId);
    print(trackId);
    try {
      await _supabase.client.from('playlist').insert({
        'track_id':trackId,
        'list_id':listId
      });
    } catch (e) {
      print(e);
      return;
    }
  }
  
  Future<void> deleteTrackFromPlaylist(int id) async {
    try {
      await _supabase.client.from('playlist').delete().eq('id', id);
    } catch (e) {
      print(e);
      return;
    }
  }

  Future<void> deleteUser() async {
    
  }
}