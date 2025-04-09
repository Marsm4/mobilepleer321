import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef TrackSelectedCallback = void Function(
    String url, String title, String author, String? image);

class PlaylistTracksPage extends StatefulWidget {
  final int playlistId;
  final String playlistName;
  final TrackSelectedCallback onTrackSelected;
  final String? currentTrackUrl;
  final VoidCallback? onPlaylistDeleted;

  const PlaylistTracksPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.onTrackSelected,
    this.currentTrackUrl,
    this.onPlaylistDeleted,
  });

  @override
  State<PlaylistTracksPage> createState() => _PlaylistTracksPageState();
}

class _PlaylistTracksPageState extends State<PlaylistTracksPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isAddingTrack = false;
  bool _isDeletingPlaylist = false;
  List<Map<String, dynamic>> _tracks = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaylistTracks();
  }

  Future<void> _fetchPlaylistTracks() async {
    try {
      final response = await _supabase
          .from('play_list')
          .select('''
            tracks:track_id (
              *,
              author:author_id (name)
            )
          ''')
          .eq('list_id', widget.playlistId);

      setState(() {
        _tracks = List<Map<String, dynamic>>.from(
            response.map((item) => item['tracks']));
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке треков плейлиста: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _isTrackLiked(int trackId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final response = await _supabase
          .from('user_liked_tracks')
          .select()
          .eq('user_id', userId)
          .eq('track_id', trackId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Ошибка проверки лайка: $e');
      return false;
    }
  }

  Future<void> _toggleLikeTrack(Map<String, dynamic> track) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо авторизоваться')),
        );
        return;
      }
      
      final trackId = track['id'] as int;
      final isLiked = await _isTrackLiked(trackId);
      
      if (isLiked) {
        await _supabase
            .from('user_liked_tracks')
            .delete()
            .eq('user_id', userId)
            .eq('track_id', trackId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "${track['name']}" удален из избранного')),
        );
      } else {
        await _supabase
            .from('user_liked_tracks')
            .insert({
              'user_id': userId,
              'track_id': trackId,
            });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "${track['name']}" добавлен в избранное')),
        );
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка при обновлении лайка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  Future<void> _addCurrentTrackToPlaylist() async {
  if (widget.currentTrackUrl == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Нет текущего трека для добавления')),
    );
    return;
  }

  setState(() => _isAddingTrack = true);

  try {
    // 1. Получаем ID трека из базы данных по URL
    final trackResponse = await _supabase
        .from('tracks')
        .select('id')
        .eq('url', widget.currentTrackUrl!)
        .maybeSingle();

    if (trackResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек не найден в базе данных')),
      );
      return;
    }

    final trackId = trackResponse['id'] as int;

    // 2. Проверяем, есть ли уже этот трек в плейлисте
    final existingResponse = await _supabase
        .from('play_list')
        .select()
        .eq('list_id', widget.playlistId)
        .eq('track_id', trackId);

    if (existingResponse.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот трек уже есть в плейлисте')),
      );
      return;
    }

    // 3. Добавляем трек в плейлист
    await _supabase
        .from('play_list')
        .insert({
          'list_id': widget.playlistId,
          'track_id': trackId,
          'created_at': DateTime.now().toIso8601String(),
        });

    // 4. Обновляем список треков
    await _fetchPlaylistTracks();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Трек добавлен в плейлист!')),
    );
  } catch (e) {
    print('Ошибка при добавлении трека: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка: ${e.toString()}')),
    );
  } finally {
    setState(() => _isAddingTrack = false);
  }
}

  Future<void> _deletePlaylist() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить плейлист'),
        content: Text('Вы уверены, что хотите удалить плейлист "${widget.playlistName}"?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingPlaylist = true);

    try {
      // Удаляем все связи треков с плейлистом
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', widget.playlistId);

      // Удаляем сам плейлист
      await _supabase
          .from('list')
          .delete()
          .eq('id', widget.playlistId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Плейлист "${widget.playlistName}" удален')),
      );

      if (widget.onPlaylistDeleted != null) {
        widget.onPlaylistDeleted!();
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingPlaylist = false);
      }
    }
  }

  String _getAuthorName(Map<String, dynamic> track) {
    if (track['author'] != null && track['author']['name'] != null) {
      return track['author']['name'] as String;
    }
    return 'Неизвестный исполнитель';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.playlistName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isDeletingPlaylist)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deletePlaylist,
              tooltip: 'Удалить плейлист',
            ),
          if (widget.currentTrackUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                icon: _isAddingTrack
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, size: 28, color: Colors.white),
                onPressed: _isAddingTrack ? null : _addCurrentTrackToPlaylist,
                tooltip: 'Добавить текущий трек в плейлист',
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _tracks.isEmpty
                ? Center(
                    child: Text(
                      'Нет треков в этом плейлисте',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      final trackImage = track['image'] as String?;
                      final trackName = track['name'] ?? 'Без названия';
                      final authorName = _getAuthorName(track);
                      final trackId = track['id'] as int;

                      return FutureBuilder<bool>(
                        future: _isTrackLiked(trackId),
                        builder: (context, snapshot) {
                          final isLiked = snapshot.data ?? false;
                          
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
                                child: trackImage != null
                                    ? Image.network(
                                        trackImage,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.blueGrey[700],
                                            child: const Icon(
                                              Icons.music_note,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey[700],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                              ),
                              title: Text(
                                trackName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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
                                    icon: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () => _toggleLikeTrack(track),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.play_arrow, 
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      widget.onTrackSelected(
                                        track['url'],
                                        trackName,
                                        authorName,
                                        trackImage,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                widget.onTrackSelected(
                                  track['url'],
                                  trackName,
                                  authorName,
                                  trackImage,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}