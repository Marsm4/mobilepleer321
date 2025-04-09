import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_scaffold.dart';
import 'package:flutter_application_1/database/storage/playlist.dart';
import 'package:flutter_application_1/database/storage/playlist_service.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/playlist_tracks.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> playlists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final loadedPlaylists = await _playlistService.getPlaylists();
      setState(() {
        playlists = loadedPlaylists;
      });
    } catch (e) {
      print('Error loading playlists: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
    title: 'Плейлисты',
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : playlists.isEmpty
                ? const Center(child: Text('Нет плейлистов'))
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: playlist.coverUrl != null
                            ? Image.network(playlist.coverUrl!, width: 50, height: 50)
                            : const Icon(Icons.playlist_play, size: 50),
                        title: Text(playlist.listName),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistTracksPage(
                                playlistId: playlist.id,
                                playlistName: playlist.listName
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
  );
}}