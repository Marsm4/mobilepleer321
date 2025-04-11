import 'package:flutter/material.dart';
import 'package:flutter_player/audioplayer.dart';
import 'package:flutter_player/landing.dart';
import 'package:flutter_player/auth.dart';
import 'package:flutter_player/recovery.dart';
import 'package:flutter_player/reg.dart';
import 'package:flutter_player/home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://oirwhgmoojxlsbortalp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pcndoZ21vb2p4bHNib3J0YWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NjI2MDEsImV4cCI6MjA1NTUzODYwMX0.Gr9AheyCe7PIyL180D1VKnvfkKK8ur8IP_8lyKw8C50',
  );
  final audioService = AudioPlayerService();
  await audioService.init();
  runApp(const AppTheme());
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/auth': (context) => AuthPage(),
        '/reg': (context) => RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
