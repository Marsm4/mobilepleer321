import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_player/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final ImagePicker _picker = ImagePicker();
  String _login = '';
  String _email = '';
  String _avatarUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await _prefs;
    final userId = prefs.getInt('userId');

    if (userId != null) {
      final response = await _supabase
          .from('User')
          .select('login, email, avatar_url')
          .eq('id', userId)
          .single();

      
        setState(() {
          _login = response['login'] ?? 'Неизвестный пользователь';
          _email = response['email'] ?? 'Нет почты';
          _avatarUrl = response['avatar_url'] ?? '';
        });
    }
  }

  Future<void> _uploadAvatar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final prefs = await _prefs;
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final file = File(image.path);
      final fileName = 'avatar_$userId.${image.path.split('.').last}';
      final filePath = 'avatars/$fileName';

      await _supabase.storage.from('avatars').upload(filePath, file);

      final String publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filePath);

      await _supabase
          .from('User')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      setState(() {
        _avatarUrl = publicUrl;
      });
    } catch (e) {
      print('Ошибка при загрузке аватарки: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await _prefs;
      await prefs.remove('userId');

      if (mounted) {
        Navigator.popUntil(context, ModalRoute.withName('/'));
        Navigator.pushNamed(context, '/');
      }
    } catch (e) {
      print('Ошибка при выходе: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(child: Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),child: Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Профиль', style: TextStyle(color: Colors.white))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
          leading: IconButton(onPressed: () {Navigator.pop(context);}, icon: Icon(Icons.arrow_back, color: Colors.white,)),
        actions: [Padding(padding: EdgeInsets.all(8.0), child: IconButton(icon: Icon(Icons.person), onPressed: () {}, style: ButtonStyle(iconColor: WidgetStateColor.transparent), hoverColor: WidgetStateColor.transparent,))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _uploadAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarUrl.isNotEmpty
                      ? NetworkImage(_avatarUrl)
                      : AssetImage('images/default_avatar.png') as ImageProvider,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Логин: $_login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Почта: $_email',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: Text('Выйти из аккаунта'),
              ),
            ),
          ],
        ),
      ),
    )
    ));
  }
}