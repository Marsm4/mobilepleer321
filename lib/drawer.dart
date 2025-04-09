import 'package:flutter/material.dart';
import 'package:music_player/MyMusicPage.dart';
import 'package:music_player/MyPlaylistsPage.dart';
import 'package:music_player/ProfilePage.dart';
import 'package:music_player/SearchPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _login = 'Загрузка...';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId != null) {
        final response = await Supabase.instance.client
            .from('User')
            .select('login, avatar_url')
            .eq('id', userId)
            .single();

        if (mounted) {
          setState(() {
            _login = response['login'] ?? 'Пользователь';
            _avatarUrl = response['avatar_url'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _login = 'Ошибка загрузки';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Профиль',
              route: const ProfilePage(),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.music_note,
              title: 'Моя музыка',
              route: const FavoritesPage(),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.search,
              title: 'Поиск',
              route: const SearchPage(),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.playlist_play,
              title: 'Мои плейлисты',
              route: const MyPlaylistsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : CircleAvatar(
                  radius: 30,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : const AssetImage('images/default_avatar.png')
                          as ImageProvider,
                ),
          const SizedBox(height: 10),
          Text(
            _login,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget route,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => route),
        );
      },
    );
  }
}