// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/favorite_service.dart';
import 'package:music_player/services/playlist_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerPage extends StatefulWidget {
  final List<Track>? trackList;
  final int? initialTrackIndex;

  const PlayerPage({
    super.key,
    this.trackList,
    this.initialTrackIndex,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  PlatformFile? _playlistImageFile;
  String? _playlistImagePath;
  final FavoriteService _favoriteService = FavoriteService();
  final PlaylistService _playlistService = PlaylistService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isFavorite = false;
  bool _showPlaylistSheet = false;
  List<Map<String, dynamic>> _playlists = [];
  final Map<String, bool> _trackInPlaylistStatus = {};

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _playlistService
          .getUserPlaylists(_supabase.auth.currentUser!.id);

      final audioService =
          Provider.of<AudioPlayerService>(context, listen: false);
      if (audioService.currentTrack != null) {
        for (var playlist in playlists) {
          final isInPlaylist = await _playlistService.isTrackInPlaylist(
              playlist['id'].toString(), audioService.currentTrack!.id);
          _trackInPlaylistStatus[playlist['id'].toString()] = isInPlaylist;
        }
      }

      if (mounted) {
        setState(() => _playlists = playlists);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ошибка загрузки плейлистов: ${e.toString()}')));
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    if (audioService.currentTrack != null) {
      final isFav =
          await _favoriteService.isFavorite(audioService.currentTrack!.id);
      setState(() => _isFavorite = isFav);
    }
  }

  void _toggleFavorite() async {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    if (audioService.currentTrack == null) return;

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await _favoriteService.addFavorite(audioService.currentTrack!.id);
    } else {
      await _favoriteService.removeFavorite(audioService.currentTrack!.id);
    }
  }

  void _togglePlaylistSheet() {
    setState(() => _showPlaylistSheet = !_showPlaylistSheet);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          if (_showPlaylistSheet) {
            setState(() => _showPlaylistSheet = false);
          }
        },
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 21, 101, 192),
                    Color.fromARGB(255, 58, 76, 85),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (audioService.currentTrack != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        audioService.currentTrack!.imageUrl,
                        height: MediaQuery.of(context).size.height * 0.3,
                        width: MediaQuery.of(context).size.width * 0.6,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: MediaQuery.of(context).size.width * 0.6,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      audioService.currentTrack!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      audioService.currentTrack!.authorName,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 18,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  StreamBuilder<Duration>(
                    stream: audioService.audioPlayer.onPositionChanged,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? audioService.position;
                      return Column(
                        children: [
                          Slider(
                            min: 0,
                            max: audioService.duration.inSeconds.toDouble(),
                            value: position.inSeconds.toDouble(),
                            onChanged: (value) {
                              audioService
                                  .seek(Duration(seconds: value.toInt()));
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(audioService.duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white, size: 30),
                        onPressed: _togglePlaylistSheet,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 40),
                            color: Colors.white,
                            onPressed: audioService.playPreviousTrack,
                          ),
                          const SizedBox(width: 20),
                          StreamBuilder<PlayerState>(
                            stream:
                                audioService.audioPlayer.onPlayerStateChanged,
                            initialData: audioService.playerState,
                            builder: (context, snapshot) {
                              final state =
                                  snapshot.data ?? audioService.playerState;
                              return IconButton(
                                icon: Icon(
                                  state == PlayerState.playing
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 60,
                                ),
                                color: Colors.white,
                                onPressed: audioService.togglePlayPause,
                              );
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 40),
                            color: Colors.white,
                            onPressed: () async {
                              await audioService.seek(Duration.zero);
                              audioService.playNextTrack();
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 30,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_showPlaylistSheet) _buildPlaylistSheet(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSheet(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Добавить в плейлист',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _createNewPlaylist(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Создать новый плейлист',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // Уменьшенный отступ здесь
                Expanded(
                  child: _buildPlaylistList(scrollController),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistList(ScrollController scrollController) {
    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _buildPlaylistItem(playlist);
      },
    );
  }

  Widget _buildPlaylistItem(Map<String, dynamic> playlist) {
    final isCurrentTrackInPlaylist =
        _trackInPlaylistStatus[playlist['id'].toString()] ?? false;

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          playlist['image'] ??
              'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//defaultPlaylistImage.png',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        playlist['name'] ?? 'Без названия',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '${playlist['tracks_count'] ?? 0} треков',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: IconButton(
        icon: Icon(
          isCurrentTrackInPlaylist ? Icons.check : Icons.add,
          color: isCurrentTrackInPlaylist ? Colors.green : Colors.white,
        ),
        onPressed: () {
          if (isCurrentTrackInPlaylist) {
            _removeFromPlaylist(playlist['id']);
          } else {
            _addToPlaylist(playlist['id']);
          }
        },
      ),
    );
  }

  Future<void> _pickPlaylistImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _playlistImageFile = result.files.first;
          _playlistImagePath = _playlistImageFile?.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  Future<void> _removeFromPlaylist(dynamic playlistId) async {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    if (audioService.currentTrack == null) return;

    try {
      final String playlistIdStr = playlistId.toString();
      await _playlistService.removeTrackFromPlaylist(
          playlistIdStr, audioService.currentTrack!.id);

      // Обновляем список плейлистов и счетчики
      await _loadPlaylists();

      setState(() {
        _trackInPlaylistStatus[playlistIdStr] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Трек удален из плейлист')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    }
  }

  Future<void> _addToPlaylist(dynamic playlistId) async {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    if (audioService.currentTrack == null) return;

    try {
      final String playlistIdStr = playlistId.toString();
      await _playlistService.addTrackToPlaylist(
          playlistIdStr, audioService.currentTrack!.id);

      // Обновляем список плейлистов и счетчики
      await _loadPlaylists();

      setState(() {
        _trackInPlaylistStatus[playlistIdStr] = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Трек добавлен в плейлист')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    }
  }

  Future<void> _createNewPlaylist(BuildContext context) async {
    final nameController = TextEditingController();
    String? imageUrl;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Новый плейлист'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Название плейлиста',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _pickPlaylistImage,
                    child: Text(
                      _playlistImageFile?.name ?? 'Выбрать изображение',
                    ),
                  ),
                  if (_playlistImageFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Размер: ${(_playlistImageFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _playlistImageFile = null;
                  _playlistImagePath = null;
                  Navigator.pop(context);
                },
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    try {
                      // Загружаем изображение если оно выбрано
                      if (_playlistImagePath != null) {
                        final file = File(_playlistImagePath!);
                        final fileName =
                            'playlist_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
                        await _supabase.storage
                            .from('storages')
                            .upload('images/$fileName', file);
                        imageUrl = _supabase.storage
                            .from('storages')
                            .getPublicUrl('images/$fileName');
                      }

                      await _playlistService.createPlaylist(
                        nameController.text,
                        _supabase.auth.currentUser!.id,
                        imageUrl: imageUrl,
                      );

                      // Сбрасываем состояние изображения
                      _playlistImageFile = null;
                      _playlistImagePath = null;

                      // Обновляем список плейлистов
                      await _loadPlaylists();

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Плейлист создан')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
