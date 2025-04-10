// home_page.dart
import 'package:flutter/material.dart';
import 'package:musik_player/database/auth.dart';
import 'package:musik_player/drawer.dart';
import 'package:musik_player/myfavorites.dart';
import 'package:musik_player/play_list.dart';
import 'package:musik_player/widgets/mini_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _authors = [];
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, String> _authorsCache = {};
  String? _selectedAuthor;
  String _searchQuery = '';
  int _currentTrackIndex = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchTracks(),
        _fetchAuthors(),
        _fetchPlaylists(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка загрузки данных: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTracks() async {
    final response = await _supabase
        .from('track')
        .select('''
          id, 
          name,
          image,
          url_music,
          author_id,
          genre_id,
          created_at,
          is_favorite
        ''')
        .order('created_at', ascending: false);

    final authorIds = response.map((t) => t['author_id'].toString()).toSet().toList();
    await Future.wait(authorIds.map((id) => _getAuthorName(id)));

    setState(() {
      _tracks = response.map((track) {
        return {
          'id': track['id'],
          'title': track['name'] ?? 'Без названия',
          'author': _authorsCache[track['author_id'].toString()] ?? 'Исполнитель',
          'urlMusic': track['url_music'] ?? '',
          'urlPhoto': track['image'] ?? '',
          'is_favorite': track['is_favorite'] ?? false,
        };
      }).toList();
    });
  }

  Future<void> _toggleFavorite(String trackId, bool isCurrentlyFavorite) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходима авторизация')),
        );
        return;
      }

      // Обновляем поле is_favorite в таблице track
      final updateResponse = await _supabase
          .from('track')
          .update({'is_favorite': !isCurrentlyFavorite})
          .eq('id', trackId)
          .select();

      debugPrint('Update response: $updateResponse');

      // Обновляем таблицу play_list если нужно (по вашей структуре)
      // Здесь может быть дополнительная логика для работы с плейлистами

      setState(() {
        final index = _tracks.indexWhere((t) => t['id'].toString() == trackId);
        if (index != -1) {
          _tracks[index]['is_favorite'] = !isCurrentlyFavorite;
        }
      });

    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  Future<String> _getAuthorName(String authorId) async {
    if (_authorsCache.containsKey(authorId)) {
      return _authorsCache[authorId]!;
    }
    try {
      final response = await _supabase
          .from('author')
          .select('name')
          .eq('id', authorId)
          .single();
      final authorName = response['name'] as String? ?? 'Неизвестный исполнитель';
      _authorsCache[authorId] = authorName;
      return authorName;
    } catch (e) {
      return 'Неизвестный исполнитель';
    }
  }

  Future<void> _fetchAuthors() async {
    final response = await _supabase
        .from('author')
        .select('''
          id,
          name,
          url_image,
          created_at
        ''')
        .order('created_at', ascending: false);
    setState(() {
      _authors = response.map((author) {
        return {
          'id': author['id'],
          'name': author['name'] ?? 'Неизвестный исполнитель',
          'url_image': author['url_image'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> _fetchPlaylists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _supabase
          .from('list')
          .select('''
            id,
            list_name,
            created_at,
            user_id
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _playlists = response.map((playlist) {
          return {
            'id': playlist['id'].toString(),
            'title': playlist['list_name'] ?? 'Без названия',
            'created_at': playlist['created_at']?.toString(),
            'user_id': playlist['user_id']?.toString(),
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки плейлистов: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTracks {
    List<Map<String, dynamic>> result = _tracks;
    if (_searchQuery.isNotEmpty) {
      result = result.where((track) =>
              track['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
              track['author'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedAuthor != null) {
      result = result.where((track) => track['author'] == _selectedAuthor).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          ),
        ),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          ),
        ),
        child: Center(
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentTrack = _tracks.isNotEmpty
        ? _tracks[_currentTrackIndex]
        : {
            'title': 'Нет треков',
            'author': '',
            'urlMusic': '',
            'urlPhoto': '',
          };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Главная', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () async {
                await _authService.LogOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('IsLoggedIn', false);
                Navigator.popAndPushNamed(context, '/auth');
              },
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Поиск',
                            hintStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.search, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: Colors.white54),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            const Text(
                              'Ваши плейлисты',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: _showCreatePlaylistDialog,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: _playlists.map((playlist) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaylistPage(
                                      playlistId: playlist['id'],
                                      playlistName: playlist['title'],
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: (MediaQuery.of(context).size.width - 50) / 2,
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.queue_music, color: Colors.white, size: 40),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      playlist['title'],
                                      style: const TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Исполнители',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _authors.length,
                          itemBuilder: (context, index) {
                            final author = _authors[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAuthor =
                                      _selectedAuthor == author['name'] ? null : author['name'];
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: _selectedAuthor == author['name']
                                            ? Colors.white.withOpacity(0.4)
                                            : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: author['url_image']!.isEmpty
                                          ? const Icon(Icons.person, color: Colors.white, size: 40)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(50),
                                              child: Image.network(
                                                author['url_image']!,
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.person, color: Colors.white, size: 40);
                                                },
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        author['name']!,
                                        style: TextStyle(
                                          color: _selectedAuthor == author['name']
                                              ? Colors.white
                                              : Colors.white70,
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
                      const SizedBox(height: 30),
                      if (_selectedAuthor != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: [
                              Text(
                                'Фильтр: $_selectedAuthor',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAuthor = null;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'Треки',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredTracks.length,
                        itemBuilder: (context, index) {
                          final track = _filteredTracks[index];
                          return ListTile(
                            leading: track['urlPhoto']!.isEmpty
                                ? Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      track['urlPhoto']!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.music_note, color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                            title: Text(
                              track['title']!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              track['author']!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                track['is_favorite'] ? Icons.favorite : Icons.favorite_border,
                                color: track['is_favorite'] ? Colors.red : Colors.white70,
                              ),
                              onPressed: () {
                                _toggleFavorite(track['id'].toString(), track['is_favorite']);
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _currentTrackIndex = _tracks.indexWhere((t) =>
                                    t['title'] == track['title'] && t['author'] == track['author']);
                                _isPlaying = true;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        bottomNavigationBar: MiniPlayerWidgets(
          urlMusic: currentTrack['urlMusic'],
          urlPhoto: currentTrack['urlPhoto'],
          nameSound: currentTrack['title'],
          author: currentTrack['author'],
        ),
        drawer: const DrawerPage(),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3E50),
          title: const Text('Создать плейлист', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Название плейлиста',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final user = _supabase.auth.currentUser;
                  if (user != null) {
                    try {
                      await _supabase.from('list').insert({
                        'list_name': controller.text,
                        'user_id': user.id,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                      await _fetchPlaylists();
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Создать', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}