import 'package:flutter/material.dart';
import 'package:music_player/database/auth.dart';
import 'package:music_player/drawer.dart';
import 'package:music_player/widgets/mini_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _favoriteTracks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Map<String, String> _authorsCache = {};

  // Состояние плеера
  int? _currentTrackIndex;
  bool _isPlaying = false;
  String? _currentTrackUrl;
  String? _currentTrackImage;
  String? _currentTrackName;
  String? _currentTrackAuthor;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteTracks();
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

      final authorName =
          response['name'] as String? ?? 'Неизвестный исполнитель';
      _authorsCache[authorId] = authorName;
      return authorName;
    } catch (e) {
      return 'Неизвестный исполнитель';
    }
  }

  Future<void> _fetchFavoriteTracks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('favorites_tracks')
          .select('track(id, name, image, url_music, author_id, created_at)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final tracksData = response.map((item) => item['track']).toList();

      // Получаем имена авторов
      final authorIds =
          tracksData.map((t) => t['author_id'].toString()).toSet().toList();
      await Future.wait(authorIds.map((id) => _getAuthorName(id)));

      setState(() {
        _favoriteTracks = tracksData.map((track) {
          return {
            'id': track['id'],
            'title': track['name'] ?? 'Без названия',
            'author':
                _authorsCache[track['author_id'].toString()] ?? 'Исполнитель',
            'urlMusic': track['url_music'] ?? '',
            'urlPhoto': track['image'] ?? '',
            'author_id': track['author_id'].toString(),
            'created_at': track['created_at'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки избранных треков: $e';
        _isLoading = false;
      });
    }
  }

  void _playTrack(int index) {
    final track = _favoriteTracks[index];
    setState(() {
      _currentTrackIndex = index;
      _currentTrackUrl = track['urlMusic'];
      _currentTrackImage = track['urlPhoto'];
      _currentTrackName = track['title'];
      _currentTrackAuthor = track['author'];
      _isPlaying = true;
    });
  }

  Future<void> _removeFromFavorites(int trackId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('favorites_tracks')
          .delete()
          .eq('user_id', userId)
          .eq('track_id', trackId);

      setState(() {
        _favoriteTracks.removeWhere((track) => track['id'] == trackId);
        if (_currentTrackIndex != null && _favoriteTracks.isEmpty) {
          _currentTrackIndex = null;
          _currentTrackUrl = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Трек удалён из избранного'),
          backgroundColor: Color(0xFF1DB954),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF121212),
            Color(0xFF1E1E1E),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Избранные треки',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.person_outline),
              color: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/userprofile'),
            ),
            IconButton(
              icon: Icon(Icons.logout_outlined),
              color: Colors.white,
              onPressed: () async {
                await _authService.LogOut();
                Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
          ],
        ),
        body: _buildContent(),
        bottomNavigationBar: _currentTrackUrl != null
            ? MiniPlayerWidgets(
                urlMusic: _currentTrackUrl,
                urlPhoto: _currentTrackImage,
                nameSound: _currentTrackName,
                author: _currentTrackAuthor,
                isPlaying: _isPlaying,
                onPlayPause: (playing) {
                  setState(() => _isPlaying = playing);
                },
              )
            : null,
        drawer: DrawerPage(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_favoriteTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Нет избранных треков',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Добавляйте треки в избранное, чтобы они появились здесь',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding:
          EdgeInsets.only(top: 16, bottom: _currentTrackUrl != null ? 80 : 16),
      itemCount: _favoriteTracks.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.white.withOpacity(0.1),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final track = _favoriteTracks[index];
        final isCurrent = _currentTrackIndex == index;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: track['urlPhoto']?.isNotEmpty == true
                ? Image.network(
                    track['urlPhoto'],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
                  )
                : _buildPlaceholderIcon(),
          ),
          title: Text(
            track['title'],
            style: TextStyle(
              color: isCurrent ? Color(0xFF1DB954) : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            track['author'],
            style: TextStyle(
              color: isCurrent
                  ? Color(0xFF1DB954).withOpacity(0.8)
                  : Colors.white.withOpacity(0.7),
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
            ),
            onPressed: () => _removeFromFavorites(track['id']),
          ),
          onTap: () => _playTrack(index),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note, color: Colors.white.withOpacity(0.5)),
    );
  }
}
