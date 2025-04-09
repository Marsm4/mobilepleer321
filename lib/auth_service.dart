import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Храним клиент Supabase в приватном поле
  final SupabaseClient _client = Supabase.instance.client;

  Future<dynamic> signIn(String email, String password) async {
    // Теперь обращаемся к _client, а не к supabase
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      return response.user;
    }
    return null;
  }

  Future<dynamic> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null) {
      return response.user;
    }
    return null;
  }

  Future<void> logOut() async {
    await _client.auth.signOut();
  }

  Future<void> recoveryPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
