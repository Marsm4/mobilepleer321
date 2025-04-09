import 'package:flutter_player/database/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
  final Supabase _supabase = Supabase.instance;

  Future<LocalUser?> signIn(String email, String password) async {
    try {
      var userGet = await _supabase.client.auth.signInWithPassword(password: password, email: email);
    
      User user = userGet.user!;

      return LocalUser.fromSupabase(user);
    }
    catch (e) { return null; }
  }

  Future<LocalUser?> signUp(String email, String password) async {
    try {
      print("Пытаемся зарегистрировать пользователя: $email"); // Отладочный вывод
      var userGet = await _supabase.client.auth.signUp(password: password, email: email);
      User user = userGet.user!;
      print("Пользователь успешно зарегистрирован: ${user.email}"); // Отладочный вывод
      return LocalUser.fromSupabase(user);
    } catch (e) {
      print("Ошибка регистрации: $e"); // Отладочный вывод
      return null;
    }
  }

  Future<void> logOut() async {
    try {
      await _supabase.client.auth.signOut();
    }
    catch (e) { return; }
  }

  Future<void> recoveryPassword(String email) async {
    try {
      await _supabase.client.auth.resetPasswordForEmail(email);
    }
    catch (e) { return; }
  }
}
