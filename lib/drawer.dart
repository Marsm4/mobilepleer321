import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:musicplayer52/auth_service.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        setState(() {
          _userData = response;
          _nameController.text = response['name'] ?? '';
          _avatarController.text = response['avatar'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных пользователя: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            TextField(
              controller: _avatarController,
              decoration: const InputDecoration(labelText: 'Ссылка на аватар'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                await Supabase.instance.client.from('users').update({
                  'name': _nameController.text,
                  'avatar': _avatarController.text,
                }).eq('id', userId);
                if (mounted) Navigator.pop(context);
                await _fetchUserData();
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  DrawerHeader(
                    child: _userData != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: _userData!['avatar'] != null
                                        ? NetworkImage(_userData!['avatar'])
                                        : null,
                                    child: _userData!['avatar'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    onPressed: _showEditDialog,
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userData!['name'] ?? 'Имя не указано',
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _userData!['email'] ?? 'Email не указан',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    leading: const Icon(Icons.library_music),
                    title: const Text("Все треки"),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    leading: const Icon(Icons.music_note),
                    title: const Text("Моя музыка"),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/track');
                    },
                  ),
                  ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    leading: const Icon(Icons.featured_play_list),
                    title: const Text("Мои плейлисты"),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/playlists');
                    },
                  ),
                  ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    leading: const Icon(Icons.logout),
                    title: const Text("Выйти"),
                    onTap: () async {
                      await _authService.logOut();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', false);
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                  ),
                ],
              ),
      ),
    );
  }
}