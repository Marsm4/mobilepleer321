import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/playerProvider';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackPage extends StatefulWidget {
  final List<Map<String, dynamic>> trackList;
  final int currentTrackIndex;
  final bool startPlaying;
  
  const TrackPage({
    super.key,
    required this.trackList,
    this.currentTrackIndex = 0,
    this.startPlaying = true
  });

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  late bool _isFavorite;
  bool _isFavoriteLoading = true;
  bool firstPlayTap = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final currentTrackId = widget.trackList[widget.currentTrackIndex]['id'];
    final status = await _isTrackInFavorites(currentTrackId);
    setState(() {
      _isFavorite = status;
      _isFavoriteLoading = false;
    });
  }

  Future<bool> _isTrackInFavorites(int trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return false;

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('Favourite_Tracks')
        .select()
        .eq('Id_user', userId)
        .eq('Id_track', trackId);

    return response.isNotEmpty;
  }

  Future<void> _toggleFavorite(BuildContext context, int trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходима авторизация')),
        );
        return;
      }

      final supabase = Supabase.instance.client;
      
      setState(() {
        _isFavoriteLoading = true;
      });

      if (_isFavorite) {
        await supabase
            .from('Favourite_Tracks')
            .delete()
            .eq('Id_user', userId)
            .eq('Id_track', trackId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удалено из моей музыки')),
        );
      } else {
        await supabase
            .from('Favourite_Tracks')
            .insert({
              'Id_user': userId,
              'Id_track': trackId,
            });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Добавлено в мою музыку')),
        );
      }

      final newStatus = await _isTrackInFavorites(trackId);
      setState(() {
        _isFavorite = newStatus;
        _isFavoriteLoading = false;
      });

    } catch (e) {
      setState(() {
        _isFavoriteLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context, int trackId) async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходима авторизация')),
      );
      return;
    }

    final playlists = await supabase
        .from('Playlist')
        .select('id, Name')
        .eq('Id_user', userId);

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет плейлистов')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить в плейлист'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist['Name']),
                onTap: () async {
                  Navigator.pop(context);
                  await _addTrackToPlaylist(context, trackId, playlist['id']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTrackToPlaylist(BuildContext context, int trackId, int playlistId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final existing = await supabase
          .from('Playlist_track')
          .select()
          .eq('Id_playlist', playlistId)
          .eq('Id_track', trackId);

      if (existing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек уже в этом плейлисте')),
        );
        return;
      }

      await supabase.from('Playlist_track').insert({
        'Id_playlist': playlistId,
        'Id_track': trackId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек добавлен в плейлист!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final currentTrack = widget.trackList[widget.currentTrackIndex];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(widget.startPlaying) {
        player.setTrackList(widget.trackList, index: widget.currentTrackIndex);
        if(!player.isPlaying) {
          player.playPause();
        }
      } else {
        player.setTrackList(widget.trackList, index: widget.currentTrackIndex);
      }
    });
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentTrack['Name'], style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Consumer<PlayerProvider>(
          builder: (context, player, _) {
            if (player.tracksList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final track = player.currentTrack;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    track['Image'],
                    height: 300,
                    width: 300,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  track['Name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthorPage(
                          authorId: track['Id_Author'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    track['Author']?['Name'] ?? 'Неизвестный исполнитель',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                Slider(
                  value: player.position.inSeconds.toDouble(),
                  min: 0,
                  max: player.duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    player.seek(Duration(seconds: value.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add, size: 30),
                      color: Colors.white,
                      onPressed: () => _showAddToPlaylistDialog(context, currentTrack['id']),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 40),
                      color: Colors.white,
                      onPressed: () {
                        if (player.currentTrackIndex > 0) {
                          player.setTracks(widget.trackList, index: player.currentTrackIndex - 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackPage(
                                trackList: widget.trackList,
                                currentTrackIndex: player.currentTrackIndex,
                                startPlaying: true,
                              ),
                            ),
                          );
                          
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 60,
                      ),
                      color: Colors.white,
                      onPressed: () => player.playPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 40),
                      color: Colors.white,
                      onPressed: () {
                        if (player.currentTrackIndex < widget.trackList.length - 1) {
                          player.setTracks(widget.trackList, index: player.currentTrackIndex + 1);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrackPage(
                                trackList: widget.trackList,
                                currentTrackIndex: player.currentTrackIndex,
                                startPlaying: true,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    _isFavoriteLoading
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 30,
                              color: _isFavorite ? Colors.red : Colors.white,
                            ),
                            onPressed: () => _toggleFavorite(context, currentTrack['id']),
                          ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}