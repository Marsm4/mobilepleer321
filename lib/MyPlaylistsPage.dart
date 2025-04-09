import 'package:flutter/material.dart';
import 'package:music_player/main.dart';
import 'package:music_player/PlaylistPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPlaylistsPage extends StatefulWidget {
  const MyPlaylistsPage({super.key});

  @override
  State<MyPlaylistsPage> createState() => _MyPlaylistsPageState();
}

class _MyPlaylistsPageState extends State<MyPlaylistsPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _playlistsFuture;
  int? _userId;
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) => _loadData());
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('userId');
    });
  }

  void _loadData() {
    if (_userId != null) {
      setState(() {
        _playlistsFuture = _fetchPlaylistsWithTrackCount();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylistsWithTrackCount() async {
    final playlistsResponse = await supabase
        .from('Playlist')
        .select('*')
        .eq('Id_user', _userId!);

    final playlistsWithCount = await Future.wait(
      playlistsResponse.map((playlist) async {
        final countResponse = await supabase
            .from('Playlist_track')
            .select()
            .eq('Id_playlist', playlist['id']);

        return {
          ...playlist,
          'track_count': countResponse.length,
        };
      }),
    );

    return playlistsWithCount;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Мои плейлисты',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePlaylistDialog(context),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: _userId == null
              ? const Center(
                  child: Text(
                    'Пользователь не авторизован',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : FutureBuilder(
                  future: _playlistsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Ошибка загрузки: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Нет плейлистов',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final playlists = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(_loadData);
                        },
                        child: ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return Card(
                              color: Colors.white.withOpacity(0.1),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.playlist_play,
                                    color: Colors.white),
                                title: Text(
                                  playlist['Name'] ?? 'Без названия',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Треков: ${playlist['track_count'] ?? '0'}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(
                                          context, playlist['id']),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistPage(
                                        playlistId: playlist['id'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    _playlistNameController.clear();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый плейлист'),
        content: TextField(
          controller: _playlistNameController,
          decoration: const InputDecoration(
            hintText: 'Введите название',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              final playlistName = _playlistNameController.text.trim();
              if (playlistName.isNotEmpty) {
                await _createPlaylist(playlistName);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlaylist(String name) async {
    try {
      await supabase.from('Playlist').insert({
        'Name': name,
        'Id_user': _userId,
      });
      setState(_loadData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Плейлист создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int playlistId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить плейлист?'),
        content: const Text('Это действие нельзя отменить', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _deletePlaylist(playlistId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist(int playlistId) async {
    try {
      await supabase
          .from('Playlist_track')
          .delete()
          .eq('Id_playlist', playlistId);

      await supabase.from('Playlist').delete().eq('id', playlistId);

      setState(_loadData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Плейлист удалён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }
}