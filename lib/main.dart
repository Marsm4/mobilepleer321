import 'package:flutter/material.dart';
import 'package:musik_player/auth.dart';
import 'package:musik_player/database/landing.dart';
import 'package:musik_player/home.dart';
import 'package:musik_player/music/player.dart';
import 'package:musik_player/play_list.dart';
import 'package:musik_player/recovery.dart';
import 'package:musik_player/reg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpod2dlYnVndmJmdXRyemd1dnhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk4NTAsImV4cCI6MjA1NTUzNTg1MH0.PyZ6VfMCoh7l2SDGeSuVpcAlGw8sn7NT4i1dDkQ6q-M',
    url: 'https://zhwgebugvbfutrzguvxr.supabase.co'
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
          iconTheme: IconThemeData(
            color: Colors.white
          ),
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
        '/auth': (context) => AuthPage(),
        '/reg': (context) => RegPage(),
        '/recovery' : (context) => RecoveryPage(),
        '/home' : (context) => HomePage(),
        '/player' : (context) => PlayerPage(),
        '/playlists' : (context) => PlaylistPage(playlistId: '', playlistName: '',)

      },
    );
  }
}
