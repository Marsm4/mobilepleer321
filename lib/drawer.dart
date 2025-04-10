import 'package:flutter/material.dart';
import 'package:musik_player/home.dart';
import 'package:musik_player/myfavorites.dart';
import 'package:musik_player/myplaylists.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final String userId = Supabase.instance.client.auth.currentUser!.id.toString();
  dynamic userData;
  bool _isLoading = true;

  Future<void> _fetchUserData() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        userData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50), // Темный серо-голубой
              Color(0xFF4CA1AF), // Голубовато-серый
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            _buildMenuItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: userData?['avatar'] != null
                ? NetworkImage(userData!['avatar'])
                : null,
            child: userData?['avatar'] == null
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            userData?['name'] ?? 'Пользователь',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userData?['email'] ?? 'email@example.com',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home, color: Colors.white),
          title: const Text('Главная', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.white),
          title: const Text('Мои треки', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyFavoritesPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.playlist_play, color: Colors.white),
          title: const Text('Мои плейлисты', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyPlaylistsPage(),
              ),
            );
          },
        ),
        const Divider(color: Colors.white54),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Выйти', style: TextStyle(color: Colors.white)),
          onTap: _signOut,
        ),
      ],
    );
  }
}