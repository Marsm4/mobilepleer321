import 'package:supabase_flutter/supabase_flutter.dart';

class LocalUser {
  String? id;
  String? email;
  String? name;

  // Конструктор по умолчанию
  LocalUser();

  // Именованный конструктор
  LocalUser.fromSupabase(User user) {
    id = user.id;
    email = user.email;
    name = user.userMetadata?['name'] as String?;
  }

  // Метод для получения данных пользователя из таблицы users в Supabase
  static Future<LocalUser> fromSupabaseWithDetails(User user) async {
    final supabase = Supabase.instance.client;

    // Получаем дополнительные данные пользователя из таблицы users
    final response =
        await supabase.from('users').select().eq('id', user.id).single();

    return LocalUser()
      ..id = user.id
      ..email = user.email
      ..name = response['name'] as String?;
  }
}
