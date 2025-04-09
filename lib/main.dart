import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/landing.dart';
import 'package:flutter_player/music/player.dart';
import 'package:flutter_player/playlistpage.dart';
import 'package:flutter_player/recovery.dart';
import 'package:flutter_player/auth.dart';
import 'package:flutter_player/reg.dart';
import 'package:flutter_player/home.dart';
import 'package:flutter_player/trackpage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rjnwjeopknvsrqsetrsf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqbndqZW9wa252c3Jxc2V0cnNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzODAyMTksImV4cCI6MjA1NTk1NjIxOX0.Pya-1YGfYitWolWGAhs9a50LjqTdKbAKzt5WCCxXEkA',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => PlayerService(),
      child: const AppTheme()
    )
  );
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          iconTheme: IconThemeData(
            color: Colors.white
          )
        ),
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.blueGrey)
          )
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            side: WidgetStatePropertyAll(BorderSide(color: Colors.white)),
          )
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white)
        )
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/auth': (context) => AuthPage(),
        '/reg': (context) => RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/main': (context) => HomePage(),
        '/tracks': (context) => TrackPage(),
        '/playlists': (context) => PlaylistPage(),
        '/player': (context) => PlayerPage(),
      }
    );
  }
}