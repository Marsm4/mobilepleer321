import 'package:supabase_flutter/supabase_flutter.dart';

class UsersTable {

  final Supabase _supabase = Supabase.instance;
  
  Future<void> addUser(String name, String email, String password) async {
    try {
      await _supabase.client.from('users').insert({
        'name': name,
        'email': email,
        'password': password,
        'avatar': 'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//Default_pfp.jpg'
      });

      final user = _supabase.client.auth.currentUser;
      if (user != null) {
        await _supabase.client.from('list').insert({
          'name': 'Избранное',
          'user_id': user.id,
        });
      }
    } catch (e) {
      print('Error adding user: $e');
    }
  }


  Future<void> updateUser(dynamic uid, String url) async {
    try {
      await _supabase.client.from('users').update({
        'avatar': url,
      }).eq('id', uid);
    } catch (e) {
      return;
    }
  }

  Future<void> deleteUser() async {}
}