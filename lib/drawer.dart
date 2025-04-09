import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  dynamic userData;
  bool isLoading = true;

  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await supabase.from('users').select().eq('id', userId).single();

      setState(() {
        userData = response;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: Color(0xFFE53935), // Красный для ошибок
          ),
        );
      }
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212), // Темный фон
              Color(0xFF282828), // Немного светлее низ
            ],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954), // Акцентный зеленый
                ),
              )
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    margin: EdgeInsets.zero,
                    accountName: Text(
                      userData?['name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    accountEmail: Text(
                      userData?['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    currentAccountPicture: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF1DB954), // Акцентный зеленый
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: userData?['avatar'] != null
                            ? Image.network(
                                userData!['avatar'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    otherAccountsPictures: [
                      IconButton(
                        onPressed: _signOut,
                        icon: Icon(Icons.logout, size: 20),
                        color: Colors.white,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  ListTile(
                    title: Text(
                      "Главная",
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: Icon(Icons.home, color: Colors.white),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    title: Text(
                      "My Music",
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: Icon(Icons.music_note, color: Colors.white),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/favorites');
                    },
                  ),
                  ListTile(
                    title: Text(
                      "My Playlists",
                      style: TextStyle(color: Colors.white),
                    ),
                    leading: Icon(Icons.playlist_play, color: Colors.white),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/playlists');
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
