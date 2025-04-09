import 'package:flutter/material.dart';
import 'package:music_player/database/landing.dart';
import 'package:music_player/favorites_page.dart';
import 'package:music_player/home.dart';
import 'package:music_player/player.dart';
import 'package:music_player/playlist.dart';
import 'package:music_player/profile.dart';
import 'package:music_player/recovery.dart';
import 'package:music_player/reg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpeWlic3dvanBhdWt0amZyZGFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk4NjcsImV4cCI6MjA1NTUzNTg2N30.qhe23HzNOEXhhAziB7XD335sghfCX-gVGUgHkirKFLs',
    url: 'https://hiyibswojpauktjfrdae.supabase.co',
  );
  runApp(const AppTheme());
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          listTileTheme: ListTileThemeData(
            textColor: Colors.white,
            iconColor: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white),
            backgroundColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          scaffoldBackgroundColor: Colors.transparent,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              foregroundColor: WidgetStatePropertyAll(Colors.blueGrey),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(Colors.white),
              side: WidgetStatePropertyAll(
                BorderSide(color: Colors.white),
              ),
            ),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
          )),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/reg': (context) => RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/home': (context) => TrackListPage(),
        '/player': (context) => PlayerPage(
              urlMusic: '',
            ),
        '/playlists': (context) => PlaylistsPage(),
        '/favorites': (context) => FavoritesPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
