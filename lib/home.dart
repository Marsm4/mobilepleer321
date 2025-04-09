import 'package:flutter/material.dart';
import 'package:music_player/database/auth.dart';
import 'package:music_player/drawer.dart';
import 'package:music_player/widgets/mini_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackListPage extends StatefulWidget {
  const TrackListPage({super.key});

  @override
  _TrackListPageState createState() => _TrackListPageState();
}

class _TrackListPageState extends State<TrackListPage> {
  final AuthService authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> tracks = [];
  List<Map<String, dynamic>> authors = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, String> authorsCache = {};
  Map<String, String> authorIdMap = {};
  Set<int> favoriteTrackIds = {};

  String searchQuery = '';
  int currentTrackIndex = 0;
  bool isPlaying = true;
  String? selectedAuthorId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchTracks(),
      _fetchAuthors(),
      _fetchFavoriteTracks(),
    ]);
  }

  Future<void> _fetchFavoriteTracks() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await supabase
          .from('favorites_tracks')
          .select('track_id')
          .eq('user_id', userId);

      setState(() {
        favoriteTrackIds =
            response.map((item) => item['track_id'] as int).toSet();
      });
    } catch (e) {
      print('Ошибка загрузки избранных треков: $e');
    }
  }

  Future<String> _getAuthorName(String authorId) async {
    if (authorsCache.containsKey(authorId)) {
      return authorsCache[authorId]!;
    }

    try {
      final response = await supabase
          .from('author')
          .select('name')
          .eq('id', authorId)
          .single();

      final authorName =
          response['name'] as String? ?? 'Неизвестный исполнитель';
      authorsCache[authorId] = authorName;
      return authorName;
    } catch (e) {
      return 'Неизвестный исполнитель';
    }
  }

  Future<void> _fetchTracks() async {
    try {
      final response = await supabase.from('track').select('''
            id, name, image, url_music, author_id, created_at
          ''').order('created_at', ascending: false);

      final authorIds =
          response.map((t) => t['author_id'].toString()).toSet().toList();
      await Future.wait(authorIds.map((id) => _getAuthorName(id)));

      setState(() {
        tracks = response.map((track) {
          return {
            'id': track['id'],
            'title': track['name'] ?? 'Без названия',
            'author':
                authorsCache[track['author_id'].toString()] ?? 'Исполнитель',
            'urlMusic': track['url_music'] ?? '',
            'urlPhoto': track['image'] ?? '',
            'author_id': track['author_id'].toString(),
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки треков: $e';
      });
    }
  }

  Future<void> _fetchAuthors() async {
    try {
      final response = await supabase.from('author').select('''
            id, name, url_image, created_at
          ''').order('created_at', ascending: false);

      setState(() {
        authors = response.map((author) {
          authorIdMap[author['name'] ?? 'Неизвестный исполнитель'] =
              author['id'].toString();
          return {
            'id': author['id'].toString(),
            'name': author['name'] ?? 'Неизвестный исполнитель',
            'url_image': author['url_image'] ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки исполнителей: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(int trackId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      if (favoriteTrackIds.contains(trackId)) {
        await supabase
            .from('favorites_tracks')
            .delete()
            .eq('user_id', userId)
            .eq('track_id', trackId);

        setState(() {
          favoriteTrackIds.remove(trackId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек удален из избранного')),
        );
      } else {
        await supabase.from('favorites_tracks').insert({
          'user_id': userId,
          'track_id': trackId,
        });

        setState(() {
          favoriteTrackIds.add(trackId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек добавлен в избранное')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddToPlaylistDialog(int trackId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final playlistsResponse = await supabase
        .from('list')
        .select('id, list_name')
        .eq('user_id', userId);

    final playlists = List<Map<String, dynamic>>.from(playlistsResponse);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить в плейлист',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF1DB954)),
                ),
                title: const Text(
                  'Создать новый плейлист',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _showCreatePlaylistDialog(trackId);
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Ваши плейлисты',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.queue_music,
                            color: Colors.white, size: 20),
                      ),
                      title: Text(
                        playlist['list_name'] ?? 'Без названия',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _addTrackToPlaylist(trackId, playlist['id']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(int trackId) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1E1E1E),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Создать плейлист',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  hintText: 'Название плейлиста',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        final playlistId =
                            await _createPlaylist(controller.text.trim());
                        if (playlistId != null) {
                          await _addTrackToPlaylist(trackId, playlistId);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Создать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int?> _createPlaylist(String name) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase.from('list').insert({
        'list_name': name,
        'user_id': userId,
      }).select('id');

      return response[0]['id'] as int?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания плейлиста')),
        );
      }
      return null;
    }
  }

  Future<void> _addTrackToPlaylist(int trackId, int playlistId) async {
    try {
      await supabase.from('play_list').insert({
        'track_id': trackId,
        'list_id': playlistId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек добавлен в плейлист')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка добавления трека')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredTracks {
    var filtered = tracks
        .where((track) =>
            track['title']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            track['author']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    if (selectedAuthorId != null) {
      filtered = filtered
          .where((track) => track['author_id'] == selectedAuthorId)
          .toList();
    }

    return filtered;
  }

  void _filterByAuthor(String? authorId) {
    setState(() {
      selectedAuthorId = selectedAuthorId == authorId ? null : authorId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white.withOpacity(0.8),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
          ),
        ),
      );
    }

    final currentTrack = tracks.isNotEmpty
        ? tracks[currentTrackIndex]
        : {
            'title': 'Нет треков',
            'author': '',
            'urlMusic': '',
            'urlPhoto': '',
          };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121212), // Темный фон
            Color(0xFF1E1E1E), // Еще темнее низ
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Список треков',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.white.withOpacity(0.8),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, size: 26),
              color: Colors.white.withOpacity(0.8),
              onPressed: () {
                // Поиск
              },
            ),
            IconButton(
              icon: Icon(Icons.person_outline, size: 26),
              color: Colors.white.withOpacity(0.8),
              onPressed: () {
                Navigator.popAndPushNamed(context, '/profile');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          hintText: 'Поиск треков, исполнителей...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        'Популярные исполнители',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: authors.length,
                        itemBuilder: (context, index) {
                          final author = authors[index];
                          final isSelected = selectedAuthorId == author['id'];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: GestureDetector(
                              onTap: () => _filterByAuthor(author['id']),
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Color(0xFF1DB954).withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(36),
                                      border: isSelected
                                          ? Border.all(
                                              color: Color(0xFF1DB954),
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: author['url_image']!.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 36,
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(36),
                                            child: Image.network(
                                              author['url_image']!,
                                              width: 72,
                                              height: 72,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  size: 36,
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      author['name']!,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Color(0xFF1DB954)
                                            : Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        selectedAuthorId != null
                            ? 'Треки исполнителя'
                            : 'Все треки',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = filteredTracks[index];
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: track['urlPhoto']!.isEmpty
                                ? Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      track['urlPhoto']!,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.music_note,
                                            color:
                                                Colors.white.withOpacity(0.6),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            title: Text(
                              track['title']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              track['author']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    favoriteTrackIds.contains(track['id'])
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        favoriteTrackIds.contains(track['id'])
                                            ? Color(0xFF1DB954)
                                            : Colors.white.withOpacity(0.6),
                                    size: 24,
                                  ),
                                  onPressed: () => _toggleFavorite(track['id']),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      _showAddToPlaylistDialog(track['id']),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                currentTrackIndex = tracks.indexWhere((t) =>
                                    t['title'] == track['title'] &&
                                    t['author'] == track['author']);
                                isPlaying = true;
                              });
                            },
                          ),
                        );
                      },
                      childCount: filteredTracks.length,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: MiniPlayerWidgets(
          urlMusic: currentTrack['urlMusic'],
          urlPhoto: currentTrack['urlPhoto'],
          nameSound: currentTrack['title'],
          author: currentTrack['author'],
        ),
        drawer: DrawerPage(),
      ),
    );
  }
}
