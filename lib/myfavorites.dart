import 'package:flutter/material.dart';
import 'package:musik_player/drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyFavoritesPage extends StatefulWidget {
  const MyFavoritesPage({super.key});

  @override
  _MyFavoritesPageState createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favoriteTracks = [];
  bool _isLoading = true;
  Map<String, String> _authorsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoriteTracks();
  }

  Future<void> _fetchFavoriteTracks() async {
    setState(() => _isLoading = true);
    try {
      // Получаем треки с is_favorite = true
      final response = await _supabase
          .from('track')
          .select('''
            id, 
            name,
            image,
            url_music,
            author_id,
            is_favorite
          ''')
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        setState(() {
          _isLoading = false;
          _favoriteTracks = [];
        });
        return;
      }

      // Кэшируем имена авторов
      final authorIds = response
          .map((track) => track['author_id'].toString())
          .toSet()
          .toList();
      
      await Future.wait(authorIds.map((id) => _getAuthorName(id)));

      setState(() {
        _favoriteTracks = response.map((track) {
          return {
            'id': track['id'],
            'title': track['name'] ?? 'Без названия',
            'author': _authorsCache[track['author_id'].toString()] ?? 'Исполнитель',
            'urlMusic': track['url_music'] ?? '',
            'urlPhoto': track['image'] ?? '',
            'is_favorite': true, // Все треки здесь уже избранные
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки избранных треков: $e')),
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

  Future<void> _removeFromFavorites(String trackId) async {
    try {
      // Обновляем поле is_favorite в таблице track
      await _supabase
          .from('track')
          .update({'is_favorite': false})
          .eq('id', trackId);

      // Обновляем локальное состояние
      setState(() {
        _favoriteTracks.removeWhere((track) => track['id'].toString() == trackId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек удален из избранного')),
      );
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Мои избранные треки', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _favoriteTracks.isEmpty
                ? const Center(
                    child: Text(
                      'У вас пока нет избранных треков',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _favoriteTracks.length,
                    itemBuilder: (context, index) {
                      final track = _favoriteTracks[index];
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
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromFavorites(track['id'].toString()),
                        ),
                      );
                    },
                  ),
        drawer: const DrawerPage(),
      ),
    );
  }
}