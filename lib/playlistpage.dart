// Обновлённый PlaylistPage с улучшенным UI и мини-плеером

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drawer.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> playlists = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  Map<String, dynamic>? currentTrack;
  List<Map<String, dynamic>> currentPlaylistTracks = [];
  int currentTrackIndex = 0;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchPlaylists();

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
    audioPlayer.onDurationChanged.listen((d) {
      setState(() => duration = d);
    });
    audioPlayer.onPositionChanged.listen((p) {
      setState(() => position = p);
    });
  }

  Future<void> fetchPlaylists() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final result = await supabase.from('list').select().eq('user_id', userId);
      setState(() {
        playlists = List<Map<String, dynamic>>.from(result);
      });
    } catch (e) {
      debugPrint('❌ Ошибка загрузки плейлистов: $e');
    }
  }

  Future<void> createPlaylistDialog() async {
    String name = '';
    String imageUrl = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать плейлист'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'Название плейлиста'),
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(hintText: 'Ссылка на картинку'),
              onChanged: (value) => imageUrl = value,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final userId = supabase.auth.currentUser?.id;
              if (userId != null && name.isNotEmpty && imageUrl.isNotEmpty) {
                await supabase.from('list').insert({
                  'list_name': name,
                  'image': imageUrl,
                  'user_id': userId,
                });
                if (context.mounted) Navigator.pop(context);
                await fetchPlaylists();
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void playTrackAt(int index) async {
    if (index >= 0 && index < currentPlaylistTracks.length) {
      currentTrackIndex = index;
      currentTrack = currentPlaylistTracks[index];
      await audioPlayer.play(UrlSource(currentTrack!['musicurl']));
      setState(() {});
    }
  }

  void openAddMusic(Map<String, dynamic> playlist) async {
    final tracks = await supabase.from('track').select();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              title: Text(track['name'] ?? ''),
              subtitle: Text(track['musicurl'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  await supabase.from('playlist').insert({
                    'track_id': track['id'],
                    'list_id': playlist['id'],
                  });
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void openPlaylistTracks(Map<String, dynamic> playlist) async {
    final result = await supabase
        .from('playlist')
        .select('track_id, track(id, name, musicurl)')
        .eq('list_id', playlist['id']);

    final tracks = (result as List)
        .map((e) => e['track'] as Map<String, dynamic>)
        .toList();

    currentPlaylistTracks = tracks;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return ListTile(
              title: Text(track['name'] ?? ''),
              subtitle: Text(track['musicurl'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await supabase.from('playlist')
                      .delete()
                      .eq('track_id', track['id'])
                      .eq('list_id', playlist['id']);
                  Navigator.pop(context);
                  openPlaylistTracks(playlist);
                },
              ),
              onTap: () async {
                currentPlaylistTracks = tracks;
                currentTrackIndex = index;
                currentTrack = track;
                await audioPlayer.play(UrlSource(track['musicurl']));
                setState(() {});
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> deletePlaylist(int playlistId) async {
    await supabase.from('playlist').delete().eq('list_id', playlistId);
    await supabase.from('list').delete().eq('id', playlistId);
    await fetchPlaylists();
  }

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const DrawerPage(),
        appBar: AppBar(
          title: const Text('Мои плейлисты'),
          titleTextStyle: TextStyle(color: Colors.white),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: createPlaylistDialog,
              icon: const Icon(Icons.playlist_add),
            ),
          ],
        ),
        body: playlists.isEmpty
            ? const Center(
                child: Text(
                  'Плейлисты не найдены. Нажмите +, чтобы создать первый.',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: playlists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return GestureDetector(
                    onTap: () => openPlaylistTracks(playlist),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(playlist['image'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                playlist['list_name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                            onPressed: () => deletePlaylist(playlist['id']),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.library_music, color: Colors.white, size: 24),
                            onPressed: () => openAddMusic(playlist),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        bottomNavigationBar: currentTrack != null
            ? Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blueGrey[700],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTrack?['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => playTrackAt(currentTrackIndex - 1),
                          icon: const Icon(Icons.skip_previous, color: Colors.white),
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            size: 36,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (isPlaying) {
                              await audioPlayer.pause();
                            } else {
                              await audioPlayer.resume();
                            }
                          },
                        ),
                        IconButton(
                          onPressed: () => playTrackAt(currentTrackIndex + 1),
                          icon: const Icon(Icons.skip_next, color: Colors.white),
                        ),
                      ],
                    ),
                    Slider(
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
                      onChanged: (value) async {
                        await audioPlayer.seek(Duration(seconds: value.toInt()));
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white38,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
