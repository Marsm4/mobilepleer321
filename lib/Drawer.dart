import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final AuthService _authService = AuthService();
  late final String _userId;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      if (_userId.isNotEmpty) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', _userId)
            .single();
        
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.popAndPushNamed(context, '/track');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при выходе: $e')),
        );
      }
    }
  }

  Widget _buildUserHeader() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: _userData['avatar'] != null
                    ? CircleAvatar(
                        radius: 42,
                        backgroundImage: NetworkImage(_userData['avatar']),
                      )
                    : Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Text(
                _userData['name'] ?? 'Пользователь',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(2, 2),
                      
                  )
                ],
                )
              ),
              const SizedBox(height: 5),
              Text(
                _userData['email'] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Выйти",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(IconData icon, String text, String routeName) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      },
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildMenuButton(Icons.music_note, "Моя музыка", '/track'),
                const Divider(color: Colors.white70, height: 1),
                _buildMenuButton(
                    Icons.featured_play_list, "Мои плейлисты", "/playlists"),
                const Divider(color: Colors.white70, height: 1),
                _buildMenuButton(
                    Icons.favorite, "Любимые треки", "/favorites"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 2,
            colors: [
              Color(0xFF151515),
              Colors.blue,
              Colors.cyan,
            ],
            stops: [0.5, 0.6, 0.8],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildUserHeader(),
              _buildMenuSection(),
            ],
          ),
        ),
      ),
    );
  }
}