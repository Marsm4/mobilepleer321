import 'package:flutter/material.dart';
import 'package:flutter_player/audioplayer.dart';

class TrackPage extends StatefulWidget {
  final Map<String, dynamic> track;
  final List<Map<String, dynamic>> playlistTracks;
  final Duration? initialPosition;

  const TrackPage({
    Key? key,
    required this.track,
    this.playlistTracks = const [],
    this.initialPosition,
  }) : super(key: key);

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final AudioPlayerService _audioService = AudioPlayerService();
  late Map<String, dynamic> _currentTrack;
  bool _isLoading = true;
  double _sliderValue = 0.0;

@override
void initState() {
  super.initState();
  _currentTrack = Map<String, dynamic>.from(widget.track);
  _audioService.currentTrack.addListener(_updateTrack);
  _initPlayer();
}

void _updateTrack() {
  if (_audioService.currentTrack.value != null && mounted) {
    setState(() {
      _currentTrack = _audioService.currentTrack.value!;
    });
  }
}

@override
void dispose() {
  _audioService.currentTrack.removeListener(_updateTrack);
  super.dispose();
}

  Future<void> _initPlayer() async {
    try {
      await _audioService.playTrack(
        _currentTrack,
        tracks: widget.playlistTracks,
        initialPosition: widget.initialPosition,
      );
      _audioService.position.addListener(_updatePosition);
      _audioService.duration.addListener(_updatePosition);
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения: ${e.toString()}')),
        );
      }
    }
  }

  void _updatePosition() {
    if (_audioService.duration.value.inMilliseconds > 0 && mounted) {
      setState(() {
        _sliderValue = _audioService.position.value.inMilliseconds / 
                      _audioService.duration.value.inMilliseconds;
      });
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
            'Сейчас играет',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: _showAddToPlaylistDialog,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _audioService.isFavorite,
              builder: (context, isFavorite, _) {
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _audioService.toggleFavorite,
                );
              },
            ),
          ],
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
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: _currentTrack['image'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(_currentTrack['image']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _currentTrack['image'] == null
                                ? const Icon(Icons.music_note,
                                    size: 60, color: Colors.white)
                                : null,
                          ),
                          Text(
                            _currentTrack['name'] ?? 'Без названия',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentTrack['author']?['name'] ?? 'Неизвестный исполнитель',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Slider(
                              value: _sliderValue,
                              onChanged: (value) {
                                setState(() => _sliderValue = value);
                                final newPosition = Duration(
                                  milliseconds: (value *
                                          _audioService.duration.value.inMilliseconds)
                                      .toInt(),
                                );
                                _audioService.seek(newPosition);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_audioService.position.value),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  _formatDuration(_audioService.duration.value),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous, size: 40),
                                onPressed: _audioService.canSkipPrevious
                                    ? _audioService.previousTrack
                                    : null,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 20),
                              ValueListenableBuilder<bool>(
                                valueListenable: _audioService.isPlaying,
                                builder: (context, isPlaying, _) {
                                  return IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: 40,
                                    ),
                                    onPressed: _audioService.playPause,
                                    color: Colors.white,
                                  );
                                },
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: const Icon(Icons.skip_next, size: 40),
                                onPressed: _audioService.canSkipNext
                                    ? _audioService.nextTrack
                                    : null,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToPlaylistDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить в плейлист'),
          content: SizedBox(
            width: double.maxFinite,
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _audioService.playlistsNotifier,
              builder: (context, playlists, _) {
                if (playlists.isEmpty) {
                  return const Text('У вас нет плейлистов');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: playlist['image'] != null
                          ? Image.network(playlist['image'], width: 40, height: 40)
                          : const Icon(Icons.queue_music),
                      title: Text(playlist['list_name'] ?? 'Без названия'),
                      subtitle: Text('${playlist['tracks_count'] ?? 0} треков'),
                      onTap: () async {
                        try {
                          await _audioService.addToPlaylist(
                            playlist['id'].toString(),
                            _currentTrack['id'].toString(),
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Добавлено в плейлист')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ошибка: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    );
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog();
              },
              child: const Text('Создать новый'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreatePlaylistDialog() async {
    final nameController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Создать плейлист'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название плейлиста',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                try {
                  await _audioService.createPlaylist(
                    name: nameController.text,
                    trackId: _currentTrack['id'].toString(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Плейлист создан')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}