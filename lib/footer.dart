import 'package:flutter/material.dart';
import 'package:flutter_player/audioplayer.dart';
import 'package:flutter_player/track.dart';

class GlobalFooter extends StatelessWidget {
  final AudioPlayerService audioService;

  const GlobalFooter({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: audioService.currentTrack,
      builder: (context, track, _) {
        if (track == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            if (audioService.currentTrack.value != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackPage(
                    track: track,
                    playlistTracks: audioService.playlist,
                    initialPosition: audioService.position.value,
                  ),
                ),
              );
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF010345).withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ValueListenableBuilder<double>(
                    valueListenable: audioService.progress,
                    builder: (context, progress, _) {
                      return Slider(
                        value: progress,
                        min: 0,
                        max: 1,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds: (value * audioService.duration.value.inMilliseconds).toInt(),
                          );
                          audioService.seek(newPosition);
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: track['image'] != null
                                ? DecorationImage(
                                    image: NetworkImage(track['image']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: track['image'] == null
                              ? const Icon(Icons.music_note, color: Colors.white)
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track['name']?.toString() ?? 'Без названия',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track['author']?['name']?.toString() ?? 'Неизвестный исполнитель',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: audioService.isFavorite,
                              builder: (context, isFavorite, _) {
                                return IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: audioService.toggleFavorite,
                                );
                              },
                            ),
                            ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable: audioService.playlistsNotifier,
                              builder: (context, playlists, _) {
                                return IconButton(
                                  icon: const Icon(Icons.playlist_add, color: Colors.white),
                                  onPressed: () => _showAddToPlaylistDialog(context, track, playlists),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 24),
                              onPressed: audioService.canSkipPrevious
                                  ? audioService.previousTrack
                                  : null,
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: audioService.isPlaying,
                              builder: (context, isPlaying, _) {
                                return IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: audioService.playPause,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next, color: Colors.white, size: 24),
                              onPressed: audioService.canSkipNext
                                  ? audioService.nextTrack
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context, 
    Map<String, dynamic> track,
    List<Map<String, dynamic>> playlists,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить в плейлист'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: playlists.isEmpty
                ? const Center(child: Text('У вас нет плейлистов'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      return ListTile(
                        leading: playlist['image'] != null
                            ? Image.network(playlist['image']!, width: 40, height: 40)
                            : const Icon(Icons.queue_music),
                        title: Text(playlist['list_name']?.toString() ?? 'Без названия'),
                        subtitle: Text('${playlist['tracks_count'] ?? 0} треков'),
                        onTap: () async {
                          try {
                            await audioService.safeAddToPlaylist(
                              playlist['id'].toString(),
                              track['id'].toString(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Добавлено в плейлист')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: ${e.toString()}')),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, track);
              },
              child: const Text('Создать новый'),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, Map<String, dynamic> track) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать плейлист'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название плейлиста',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                try {
                  await audioService.createPlaylist(
                    name: nameController.text,
                    trackId: track['id'].toString(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Плейлист создан')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }
}