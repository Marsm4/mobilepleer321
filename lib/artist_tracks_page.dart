import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class ArtistTracksPage extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String? artistImageUrl;
  final Function(String, String, String, String?) onTrackSelected;

  const ArtistTracksPage({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImageUrl,
    required this.onTrackSelected,
  });

  @override
  State<ArtistTracksPage> createState() => _ArtistTracksPageState();
}

class _ArtistTracksPageState extends State<ArtistTracksPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  List<Map<String, dynamic>> _tracks = [];

  @override
  void initState() {
    super.initState();
    _fetchArtistTracks();
  }

  Future<void> _fetchArtistTracks() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('''
            *,
            author:author_id (name)
          ''')
          .eq('author_id', widget.artistId);

      setState(() {
        _tracks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке треков исполнителя: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artistName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      'Нет треков этого исполнителя',
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
                      final artistName = widget.artistName;
                      final audioUrl = track['url'] as String?;
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
                                artistName,
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
                                      if (audioUrl != null) {
                                        widget.onTrackSelected(
                                          audioUrl,
                                          trackName,
                                          artistName,
                                          trackImage,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Не удалось загрузить трек'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (audioUrl != null) {
                                  widget.onTrackSelected(
                                    audioUrl,
                                    trackName,
                                    artistName,
                                    trackImage,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Не удалось загрузить трек'),
                                    ),
                                  );
                                }
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}