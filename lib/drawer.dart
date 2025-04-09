import 'package:flutter/material.dart';
import 'package:flutter_application_1/favorite_tracks.dart';
import 'package:flutter_application_1/playlist.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  final String user_id =
      Supabase.instance.client.auth.currentUser!.id.toString();
  dynamic docs;

  getUserById() async {
    final userGet =
        await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user_id)
            .single();
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.blueGrey]),
        ),
        child: ListView(
          children: [
            DrawerHeader(
              child: UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white10,
                ),
                accountName: Text(docs?['name'] ?? 'Загрузка...'),
                accountEmail: Text(docs?['email'] ?? 'example@mail.com'),
                currentAccountPicture: Container(
                  alignment: Alignment.topCenter,
                  child: CircleAvatar(
                    maxRadius: 20,
                    minRadius: 10,
                    backgroundImage: NetworkImage(
                      'https://qklzkuvjpyvdvzzbiltm.supabase.co/storage/v1/object/public/storages//profil.webp',
                    ),
                  ),
                ),
                otherAccountsPictures: [
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white),
                    onPressed: () {
                      Navigator.popAndPushNamed(context, '/auth');
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteTracksPage(),
                    ),
                  );
                },
                hoverColor: Colors.white.withOpacity(0.2),
                splashColor: Colors.white.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    iconColor: Colors.red,
                    textColor: Colors.white,
                    title: Text("Избранное"),
                    leading: Icon(Icons.music_note),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlaylistsPage(),
                    ),
                  );
                },
                hoverColor: Colors.white.withOpacity(0.2),
                splashColor: Colors.white.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    iconColor: Colors.yellow,
                    textColor: Colors.white,
                    title: Text("Плейлисты"),
                    leading: Icon(Icons.featured_play_list),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}