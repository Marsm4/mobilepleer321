import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_player/footer.dart';
import 'package:provider/provider.dart';
import 'package:flutter_player/player_state.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _likedTracks = [];
  bool _isLoading = true;
  int? _currentTrackIndex;

  @override
  void initState() {
    super.initState();
    _fetchLikedTracks();
  }

  Future<void> _fetchLikedTracks() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('user_liked_tracks')
          .select('''
            track_id (
              id, 
              name, 
              url, 
              image,
              author:author_id (id, name)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response == null) return;

      setState(() {
        _likedTracks = response
            .map((item) => item['track_id'] as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки треков: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _playTrack(String trackId, String url, int index) async {
    if (!mounted) return;
    
    setState(() {
      _currentTrackIndex = index;
    });
    
    final playerState = Provider.of<AppPlayerState>(context, listen: false);
    final track = _likedTracks[index];
    
    await playerState.playTrack(
      url,
      track['name'] ?? 'Без названия',
      track['author']?['name'] ?? 'Неизвестный исполнитель',
      track['image'],
    );
  }

  Future<void> _playNextTrack() async {
    if (_likedTracks.isEmpty || _currentTrackIndex == null) return;
    
    final nextIndex = (_currentTrackIndex! + 1) % _likedTracks.length;
    final nextTrack = _likedTracks[nextIndex];
    
    await _playTrack(
      nextTrack['id'].toString(),
      nextTrack['url'],
      nextIndex,
    );
  }

  Future<void> _playPreviousTrack() async {
    if (_likedTracks.isEmpty || _currentTrackIndex == null) return;
    
    final prevIndex = (_currentTrackIndex! - 1) % _likedTracks.length;
    final prevTrack = _likedTracks[prevIndex];
    
    await _playTrack(
      prevTrack['id'].toString(),
      prevTrack['url'],
      prevIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя музыка', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: _buildContent(),
      ),
      bottomNavigationBar: const Footer(), // Используем футер с Provider
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    if (_likedTracks.isEmpty) {
      return Center(
        child: Text(
          'У вас пока нет понравившихся треков',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedTracks.length,
      itemBuilder: (context, index) {
        final track = _likedTracks[index];
        final playerState = Provider.of<AppPlayerState>(context);
        final isCurrent = playerState.currentTrackUrl == track['url'];
        final authorName = track['author']?['name'] ?? 'Неизвестный исполнитель';
        final imageUrl = track['image'] ?? 'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';

        return _buildTrackItem(track, index, isCurrent, authorName, imageUrl);
      },
    );
  }

  Widget _buildTrackItem(
    Map<String, dynamic> track, 
    int index, 
    bool isCurrent, 
    String authorName,
    String imageUrl,
  ) {
    final playerState = Provider.of<AppPlayerState>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 50,
              color: Colors.blueGrey[700],
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
        ),
        title: Text(
          track['name'] ?? 'Без названия',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          authorName,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
              onPressed: () => _toggleLike(track['id'].toString()),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isCurrent && playerState.isPlaying 
                    ? Icons.pause 
                    : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                if (isCurrent) {
                  playerState.togglePlayPause();
                } else {
                  _playTrack(
                    track['id'].toString(),
                    track['url'],
                    index,
                  );
                }
              },
            ),
          ],
        ),
        onTap: () {
          if (isCurrent) {
            playerState.togglePlayPause();
          } else {
            _playTrack(
              track['id'].toString(),
              track['url'],
              index,
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleLike(String trackId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Необходима авторизация')),
          );
        }
        return;
      }

      final existingLike = await supabase
          .from('user_liked_tracks')
          .select()
          .eq('user_id', userId)
          .eq('track_id', trackId)
          .maybeSingle();

      if (existingLike != null) {
        await supabase
            .from('user_liked_tracks')
            .delete()
            .eq('user_id', userId)
            .eq('track_id', trackId);
      } else {
        await supabase
            .from('user_liked_tracks')
            .insert({
              'user_id': userId,
              'track_id': trackId,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      await _fetchLikedTracks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existingLike != null 
              ? 'Трек удален из избранного' 
              : 'Трек добавлен в избранное')),
        );
      }
    } catch (e) {
      print('Ошибка при обновлении лайка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}