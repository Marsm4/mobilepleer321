import 'package:flutter/material.dart';
import 'package:flutter_player/auth.dart';
import 'package:flutter_player/home.dart'; // Обновленный HomePage
import 'package:flutter_player/landing.dart';
import 'package:flutter_player/music/player.dart'; // Обновленный PlayerPage
import 'package:flutter_player/playlistpage.dart';
import 'package:flutter_player/profile.dart';
import 'package:flutter_player/recovery.dart';
import 'package:flutter_player/registration.dart';
import 'package:flutter_player/trackpage.dart';
import 'package:flutter_player/artistpage.dart'; // Обновленный ArtistPage
import 'package:flutter_player/musiccollectionpage.dart';
import 'package:flutter_player/player-provider.dart'; // Новый провайдер плеера
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mexcozzswlkrrmqyrfqy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1leGNvenpzd2xrcnJtcXlyZnF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA1ODk0MDksImV4cCI6MjA1NjE2NTQwOX0.huDqjGZwBgheqVCOCPEirpteDPM4dzxGHB_FEGkGBF0'
  );

  runApp(const AppTheme());
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PlayerProvider(),
      child: MaterialApp(
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
          '/main': (context) => HomePage(), // Теперь используем обновленный HomePage
          '/track': (context) => TrackPage(),
          '/playlists': (context) => PlaylistPage(),
          '/player': (context) => PlayerPage(), // Обновленный PlayerPage
          '/profile': (context) => ProfilePage(),
          '/artist': (context) {
            final artist = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return ArtistPage(artist: artist); // Обновленный ArtistPage
          },
          '/collection': (context) {
            final collection = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return MusicCollectionPage(collection: collection);
          },
        }
      ),
    );
  }
}