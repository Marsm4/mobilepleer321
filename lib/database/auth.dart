import 'package:musik_player/database/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService { 
  
  final Supabase _supabase = Supabase.instance;

  Future<LocalUser?> sighIN(String email, String password) async {
    try {
      var userGet = await _supabase.client.auth.signInWithPassword(password: password, email: email);

      User user = userGet.user!;

      return LocalUser.fromSupabase(user);
    } catch (e) {
      
      return null;
    }
  }


   Future<LocalUser?> sighUp(String email, String password) async {
    try {
      var userGet = await _supabase.client.auth.signUp(password: password, email: email);

      User user = userGet.user!;

      return LocalUser.fromSupabase(user);
    } catch (e) {
      return null;
    }
  }

  Future<void> LogOut() async {
    try {
      await _supabase.client.auth.signOut();
    } catch (e) {
      return ;
    }
  }

  Future<void> recoveryPassword(String email) async {
    try {
      await _supabase.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      return;
    }
  }

  
}