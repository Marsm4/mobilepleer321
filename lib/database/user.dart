import 'package:supabase_flutter/supabase_flutter.dart';

class LocalUser{
  String? id;
  String ? email;

  LocalUser.fromSupabase(User user){
    id = user.id;
    email = user.email;
  }
}