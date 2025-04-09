import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';
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

  getUserById() async {
    final userGet = await Supabase.instance.client.from('users').select().eq('id', user_id).single();

    setState(() {
      docs = userGet;
    });
  }

  @override
  void initState() {
    getUserById();
    super.initState();
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
                accountName: Text(docs['name']), 
                accountEmail: Text(docs['email']),
                currentAccountPicture: Container(
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    maxRadius: 20,
                    minRadius: 10,
                    backgroundImage: NetworkImage(docs['avatar']),
                  ),
                ),
                otherAccountsPictures: [
                  IconButton(onPressed: () async {
                    await authService.logOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', false);
                    Navigator.popAndPushNamed(context, '/auth');
                  }, icon: Icon(Icons.logout, color: Colors.white,))
                ],
              )
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () {
                Navigator.popAndPushNamed(context, '/tracks');
              },
              title: Text("Моя музыка"),
              leading: Icon(Icons.music_note),
            ),
            ListTile(
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: (){
                Navigator.popAndPushNamed(context, '/playlists');
              },
              title: Text("Мои плейлисты"),
              leading: Icon(Icons.featured_play_list),
            ),
          ],
        ),
      ),
    );
  }
}