import 'package:flutter/material.dart';
import 'package:flutter_player/audioplayer.dart';
import 'package:flutter_player/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayerService _audioService = AudioPlayerService();

  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _audioService.isFavorite.addListener(_refreshFavorites);
  }

  Future<void> _refreshFavorites() async {
    if (mounted) {
      setState(() => _isLoading = true);
      await _loadFavorites();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('favorites')
          .select('track:track_id(*, author:author_id(*))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _favorites = (response as List)
              .where((item) => item['track'] != null)
              .map((item) => Map<String, dynamic>.from(item['track']))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Ошибка загрузки избранного: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0008FF), Color(0xFF010345)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Избранное',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _favorites.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border,
                                  size: 80, color: Colors.white70),
                              const SizedBox(height: 16),
                              const Text(
                                'Нет избранных треков',
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            final track = _favorites[index];
                            return _buildTrackCard(track);
                          },
                        ),
            ),
            GlobalFooter(audioService: _audioService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track['image'] != null
              ? Image.network(
                  track['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.blueGrey[800],
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
        ),
        title: Text(
          track['name'] ?? 'Без названия',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          track['author']?['name'] ?? 'Неизвестный исполнитель',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () => _playTrack(track),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFavorite(track['id'].toString()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(String trackId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('track_id', trackId);

      await _refreshFavorites();
    } catch (e) {
      _showError('Ошибка удаления: $e');
    }
  }

  void _playTrack(Map<String, dynamic> track) {
    _audioService.playTrack(track, tracks: _favorites, context: context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}