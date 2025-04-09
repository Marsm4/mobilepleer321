import 'package:flutter/material.dart';
import 'package:music_player/profile_settings.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/upload_track_page.dart';
import 'package:music_player/uploaded_tracks.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SideMenu extends StatelessWidget {
  final VoidCallback? onClose;

  const SideMenu({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Drawer(
      backgroundColor: const Color.fromARGB(220, 26, 26, 26),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(200, 21, 101, 192),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    user?.userMetadata?['avatar'] as String? ??
                        'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages/images/9473db65-1d42-4ef5-9d4f-2020a5efc9c6_1743986704465.jpg',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'Гость',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.white),
            title: const Text(
              'Загрузить трек',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadTrackPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.white),
            title: const Text(
              'Загруженные треки',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              // Сохраняем контекст перед навигацией
              final audioService = Provider.of<AudioPlayerService>(context, listen: false);
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadedTracksPage(),
                ),
              );
              // Используем сохраненную ссылку
              audioService.notifyListeners();
            },
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Настройки',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              // Сохраняем контекст перед навигацией
              final audioService = Provider.of<AudioPlayerService>(context, listen: false);
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsPage(),
                ),
              );
              if (result == true) {
                // Используем сохраненную ссылку
                audioService.notifyListeners();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.white),
            title: const Text(
              'Выйти',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
    );
  }
}