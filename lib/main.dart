import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/PlaylistPage.dart';
import 'package:music_player/ProfilePage.dart';
import 'package:music_player/auth.dart';
import 'package:music_player/bottom.dart';
import 'package:music_player/drawer.dart';
import 'package:music_player/home.dart';
import 'package:music_player/playerProvider';
import 'package:provider/provider.dart';
import 'reg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: "https://fpiuuepqttgwrrofahwq.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwaXV1ZXBxdHRnd3Jyb2ZhaHdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzNjI1NjcsImV4cCI6MjA1NTkzODU2N30.94lkCuVyxsvO2tGt8GdpLm8lUO1XGMz3i_p23gebvEE",
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
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
        iconTheme: const IconThemeData(color: Colors.white),
        scaffoldBackgroundColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.blueGrey),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            side: const WidgetStatePropertyAll(
              BorderSide(color: Colors.white),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GradientBackground(child: AuthPage()),
        '/reg': (context) => const GradientBackground(child: RegPage()),
        '/home': (context) => const MainLayout(child: HomePage()),
        '/profile': (context) => const MainLayout(child: ProfilePage()),
        '/author': (context) {
          final authorId = ModalRoute.of(context)!.settings.arguments as int;
          return MainLayout(child: AuthorPage(authorId: authorId),);
        },
        '/playlist': (context) {
          final playlistId = ModalRoute.of(context)!.settings.arguments as int;
          return MainLayout(
            child: PlaylistPage(playlistId: playlistId),
          );
        },
      },
    );
  }
}

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: Colors.transparent,
        body: child,
        bottomNavigationBar: const BottomPlayer(),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),
      child: child,
    );
  }
}