import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'landing.dart';
import 'auth.dart';
import 'music/player.dart';
import 'registration.dart';
import 'recovery.dart';
import 'home.dart';
import 'trackpage.dart';
import 'playlistpage.dart';
import 'profile.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://tpuiptskdlpwbypqefmy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwdWlwdHNrZGxwd2J5cHFlZm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMjY4NjgsImV4cCI6MjA1NzkwMjg2OH0.ahJV8GS1yzv08D2y-MCiaXTLUmCQ7Cn28lLjoOnRkKo',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          color: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blueGrey,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const LandingPage(),
        '/auth': (context) => const AuthPage(),
        '/reg': (context) => const RegPage(),
        '/recovery': (context) => const RecoveryPage(),
        '/home': (context) => const HomePage(),
        '/track': (context) => const TrackPage(),
        '/playlists': (context) => const PlaylistPage(),
        '/player': (context) =>  PlayerPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
