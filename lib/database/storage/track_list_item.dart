import 'package:flutter/material.dart';
import 'package:flutter_application_1/database/storage/playlist.dart';
import 'package:flutter_application_1/database/storage/playlist_service.dart';
import 'package:flutter_application_1/database/storage/track.dart';

class TrackListItem extends StatelessWidget {
  final Track track;
  final String authorName;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback onTap;
  final VoidCallback? onAddToPlaylist;

  const TrackListItem({
    super.key,
    required this.track,
    required this.authorName,
    required this.isFavorite,
    this.onToggleFavorite,
    required this.onTap,
    this.onAddToPlaylist,
  });

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final playlistService = PlaylistService();
    final playlists = await playlistService.getPlaylists();

    final playlistsWithTrack = await Future.wait(
      playlists.map((playlist) async {
        final tracks = await playlistService.getPlaylistTracks(playlist.id);
        return {
          'playlist': playlist,
          'contains': tracks.any((t) => t.id == track.id),
        };
      }),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Добавить в плейлист',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playlistsWithTrack.length,
                itemBuilder: (context, index) {
                  final item = playlistsWithTrack[index];
                  final playlist = item['playlist'] as Playlist;
                  final containsTrack = item['contains'] as bool;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return ListTile(
                        title: Text(
                          playlist.listName,
                          style: const TextStyle(color: Colors.blue),
                        ),
                        trailing: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () async {
                              if (containsTrack) {
                                await playlistService.removeTrackFromPlaylist(
                                  playlist.id,
                                  track.id,
                                );
                              } else {
                                await playlistService.addTrackToPlaylist(
                                  playlist.id,
                                  track.id,
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    containsTrack
                                        ? 'Удалено из ${playlist.listName}'
                                        : 'Добавлено в ${playlist.listName}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                containsTrack ? Icons.check : Icons.add,
                                color:
                                    containsTrack ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Закрыть'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          track.imageUrl.isNotEmpty
              ? Image.network(track.imageUrl, width: 50, height: 50)
              : const Icon(Icons.music_note),
      title: Text(track.name),
      subtitle: Text(authorName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onAddToPlaylist != null)
            IconButton(
              icon: const Icon(Icons.playlist_add),
              color: Colors.white,
              onPressed: () => _showAddToPlaylistDialog(context),
              highlightColor: Colors.grey.withOpacity(0.2),
            ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: onToggleFavorite,
            highlightColor: Colors.grey.withOpacity(0.2),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
