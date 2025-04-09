// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:music_player/auth.dart';
import 'package:music_player/author_page.dart';
import 'package:music_player/home.dart';
import 'package:music_player/landing.dart';
import 'package:music_player/medialibrary.dart';
import 'package:music_player/music/player.dart';
import 'package:music_player/playlist.dart';
import 'package:music_player/profile.dart';
import 'package:music_player/profile_settings.dart';
import 'package:music_player/recovery_pass.dart';
import 'package:music_player/reg.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/uploaded_tracks.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5taWRjbXN4a3FiZ3NqaGhudmZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk3NTYsImV4cCI6MjA1NTUzNTc1Nn0.cOmTMXTTj9x2y8zEr17w_ne8HTEaMN0meQ0UAbgAH1A',
    url: 'https://nmidcmsxkqbgsjhhnvfo.supabase.co',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AudioPlayerService(),
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
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          scaffoldBackgroundColor: Colors.transparent,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Colors.white),
              foregroundColor: MaterialStatePropertyAll(Colors.blueGrey),
              padding:
                  MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              )),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: const ButtonStyle(
              foregroundColor: MaterialStatePropertyAll(Colors.white),
              padding:
                  MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
              side: MaterialStatePropertyAll(BorderSide(color: Colors.white)),
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              )),
            ),
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white),
            titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 21, 101, 192),
                  Color.fromARGB(255, 58, 76, 85),
                ],
              ),
            ),
            child: child,
          );
        },
        initialRoute: "/",
        routes: {
          '/': (context) => const LandingPage(),
          '/auth': (context) => const AuthPage(),
          '/reg': (context) => const RegPage(),
          '/recovery': (context) => const RecoveryPage(),
          '/home': (context) => const HomePage(),
          '/medialibrary': (context) => const MediaLibraryPage(),
          '/profile': (context) => const ProfilePage(),
          '/player': (context) => const PlayerPage(),
          '/uploaded_tracks': (context) => const UploadedTracksPage(),
          '/profile_settings': (context) => const ProfileSettingsPage(),
          '/author': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return AuthorPage(
              authorId: args['id'],
              authorName: args['name'],
              authorImage: args['image'],
            );
          },
          '/playlist': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            return PlaylistPage(
              playlistId: args['id'],
              playlistName: args['name'],
              playlistImage: args['image'],
              onBack: () {},
            );
          },
        });
  }
}
