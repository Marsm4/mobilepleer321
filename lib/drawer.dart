import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';
import 'package:flutter_player/trackpage.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  AuthService authService = AuthService();
  final String user_id = Supabase.instance.client.auth.currentUser!.id.toString();
  dynamic docs;

  @override
  void initState() {
    getUserById();
    super.initState();
  }

  getUserById() async {
    final userGet = await Supabase.instance.client.from('users').select().eq('id', user_id).single();
    setState(() {
      docs = userGet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey]
          )
        ),
        child: ListView(
          children: [
            DrawerHeader(
              child: UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20)
                ),
                accountName: Text(docs?['name'] ?? 'Гость'), 
                accountEmail: Text(docs?['email'] ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(docs?['avatar'] ?? 'https://rjnwjeopknvsrqsetrsf.supabase.co/storage/v1/object/public/storages//usericon.png'),
                ),
              )
            ),
            // Главная
            ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text("Главная", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.popAndPushNamed(context, '/main');
              },
            ),
            // Поиск
            ListTile(
              leading: Icon(Icons.search, color: Colors.white),
              title: Text("Поиск", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.popAndPushNamed(context, '/search');
              },
            ),
            // Моя музыка
            ListTile(
              leading: Icon(Icons.music_note, color: Colors.white),
              title: Text("Моя музыка", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrackPage()),
                );
              },
            ),
            // Мои плейлисты
            ListTile(
              leading: Icon(Icons.playlist_play, color: Colors.white),
              title: Text("Мои плейлисты", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.popAndPushNamed(context, '/playlists');
              },
            ),
            // Профиль
            ListTile(
              leading: Icon(Icons.person, color: Colors.white),
              title: Text("Профиль", style: TextStyle(color: Colors.white)),
              onTap: () async {
                final supabase = Supabase.instance.client;
                final user = supabase.auth.currentUser;
                if (user != null) {
                  Navigator.popAndPushNamed(
                    context,
                    '/profile',
                    arguments: {'username': docs?['name'] ?? 'Гость'},
                  );
                } else {
                  Navigator.popAndPushNamed(
                    context,
                    '/profile',
                    arguments: {'username': 'Гость'},
                  );
                }
              },
            ),
            Divider(color: Colors.white.withOpacity(0.5)),
            // Выход
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text("Выход", style: TextStyle(color: Colors.white)),
              onTap: () async {
                await authService.logOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                Navigator.popAndPushNamed(context, '/auth');
              },
            ),
          ],
        ),
      ),
    );
  }
}