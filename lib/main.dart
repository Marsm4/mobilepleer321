import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/landing.dart';
import 'package:flutter_player/music/player.dart';
import 'package:flutter_player/playlistpage.dart';
import 'package:flutter_player/profile_page.dart';
import 'package:flutter_player/recovery.dart';
import 'package:flutter_player/auth.dart';
import 'package:flutter_player/reg.dart';
import 'package:flutter_player/home.dart';
import 'package:flutter_player/search_page.dart';
import 'package:flutter_player/trackpage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_player/player_state.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qqqkrrkywhbxzukpuevw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxcWtycmt5d2hieHp1a3B1ZXZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk5MDAsImV4cCI6MjA1NTUzNTkwMH0.RGx0A-bzHZjtewfkvX5Bc8MU1s3DeoPa8krUNBGAt7I',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppPlayerState(), // Используем AppPlayerState вместо PlayerState
      child: const AppTheme(),
    ),
  );
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.blueGrey,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.white),
            foregroundColor: const WidgetStatePropertyAll(Colors.blueGrey),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            side: const WidgetStatePropertyAll(BorderSide(color: Colors.white)),
          ),
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/auth': (context) => AuthPage(),
        '/reg': (context) =>  RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/main': (context) => ScaffoldWithFooter(child: HomePage()),
        '/track': (context) => ScaffoldWithFooter(child: TrackPage()),
        '/playlists': (context) => PlaylistPage(),
        '/player': (context) => ScaffoldWithFooter(child: PlayerPage()),
        '/profile': (context) => ProfilePage(),
        '/search': (context) => ScaffoldWithFooter(
              child: SearchPage(
                onTrackSelected: (url, title, author, image) {
                  Provider.of<AppPlayerState>(context, listen: false) // Используем AppPlayerState
                      .playTrack(url, title, author, image);
                },
              ),
            ),
      },
    );
  }
}

class ScaffoldWithFooter extends StatelessWidget {
  final Widget child;
  const ScaffoldWithFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const Footer(),
    );
  }
}