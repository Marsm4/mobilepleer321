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
  Future<void> deleteUser() async {
    
  }
}