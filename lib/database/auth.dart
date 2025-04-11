import 'package:flutter_player/database/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthService {
final SupabaseClient _supabase = Supabase.instance.client;


  Future<LocalUser?> signIn(String email, String password) async {
    try {
      var userGet = await _supabase.auth.signInWithPassword(password: password, email: email);
    
      User user = userGet.user!;

      return LocalUser.fromSupabase(user);
    }
    catch (e) { return null; }
  }

  Future<LocalUser?> signUp(String email, String password) async {
    try {
      print("Пытаемся зарегистрировать пользователя: $email"); // Отладочный вывод
      var userGet = await _supabase.auth.signUp(password: password, email: email);
      User user = userGet.user!;
      print("Пользователь успешно зарегистрирован: ${user.email}"); // Отладочный вывод
      return LocalUser.fromSupabase(user);
    } catch (e) {
      print("Ошибка регистрации: $e"); // Отладочный вывод
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Ошибка при выходе: $e');
    }
  }
  Future<void> recoveryPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Ошибка восстановления пароля: $e');
    }
  }
}