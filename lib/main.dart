import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player/recovery.dart';
import 'package:music_player/auth.dart';
import 'package:music_player/reg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/mainpage.dart';
import 'package:music_player/profilepage.dart';
import 'package:music_player/tracks_page.dart';
import 'package:music_player/player_state.dart';
import 'package:music_player/player_page.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:music_player/artist_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gutkldvbfpfcpjuljchk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1dGtsZHZiZnBmY3BqdWxqY2hrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2NzA0MzQsImV4cCI6MjA1OTI0NjQzNH0.RH3zcDAua_ij49gZ1XhBG-udtLIrjRvITI8hdkWRpy0',
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final supabase = Supabase.instance.client;
  final session = supabase.auth.currentSession;

  runApp(
    ChangeNotifierProvider(
      create: (context) => PlayerState(),
      child: AppTheme(initialRoute: session != null ? '/main' : '/'),
    ),
  );
}

class AppTheme extends StatelessWidget {
  final String initialRoute;

  const AppTheme({super.key, this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.blueGrey,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.blueGrey),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            side: WidgetStatePropertyAll(BorderSide(color: Colors.white)),
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
  '/': (context) => AuthPage(),
  '/reg': (context) => RegPage(),
  '/recovery': (context) => RecoveryPage(),
  '/main': (context) => MainPage(),
  '/profile': (context) => ProfilePage(),
  '/tracks': (context) => TracksPage(),
  '/player': (context) => PlayerPage(),
  '/artist': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return ArtistPage(
      artistId: args['artistId'],
      artistName: args['artistName'],
      artistImage: args['artistImage'],
    );
  },
},
    );
  }
}