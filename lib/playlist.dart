import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/favorite_service.dart';
import 'package:music_player/services/playlist_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class PlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  final VoidCallback? onBack;
  final VoidCallback? onPlaylistDeleted;

  const PlaylistPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.playlistImage,
    this.onBack,
    this.onPlaylistDeleted,
  });

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final PlaylistService _playlistService = PlaylistService();
  final FavoriteService _favoriteService = FavoriteService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Track> _tracks = [];
  bool _isLoading = true;
  List<String> _favoriteIds = [];
  bool _showSettings = false;
  String? _newPlaylistName;
  String? _newPlaylistImage;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _newPlaylistName = widget.playlistName;
    _newPlaylistImage = widget.playlistImage;
    _nameController.text = widget.playlistName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadPlaylistTracks(),
      _loadFavorites(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlaylistTracks() async {
    try {
      final tracksData =
          await _playlistService.getPlaylistTracks(widget.playlistId);
      if (mounted) {
        setState(() {
          _tracks =
              tracksData.map((track) => Track.fromSupabase(track)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки треков: $e')),
        );
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getUserFavorites();
      if (mounted) {
        setState(() {
          _favoriteIds = favorites;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки избранного: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Track track) async {
    try {
      if (track.isFavorite) {
        await _favoriteService.removeFavorite(track.id);
      } else {
        await _favoriteService.addFavorite(track.id);
      }
      if (mounted) {
        setState(() {
          track.isFavorite = !track.isFavorite;
          if (track.isFavorite) {
            _favoriteIds.add(track.id);
          } else {
            _favoriteIds.remove(track.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deletePlaylist() async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', widget.playlistId);

      await _supabase.from('list').delete().eq('id', widget.playlistId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Плейлист удален')),
        );

        // Вызываем callback если он есть
        widget.onPlaylistDeleted?.call();

        // Или закрываем страницу если нет callback
        if (widget.onPlaylistDeleted == null) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления плейлиста: $e')),
        );
      }
    }
  }

  Future<void> _updatePlaylist() async {
    try {
      await _supabase.from('list').update({
        'name': _newPlaylistName,
        if (_newPlaylistImage != widget.playlistImage)
          'image': _newPlaylistImage,
      }).eq('id', widget.playlistId);

      if (mounted) {
        setState(() {
          _showSettings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Плейлист обновлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName =
            'playlist_${widget.playlistId}_${DateTime.now().millisecondsSinceEpoch}${file.path.split('.').last}';

        await _supabase.storage
            .from('storages')
            .upload('images/$fileName', file);

        final imageUrl =
            _supabase.storage.from('storages').getPublicUrl('images/$fileName');

        if (mounted) {
          setState(() {
            _newPlaylistImage = imageUrl;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки изображения: $e')),
        );
      }
    }
  }

  Future<void> _removeTrack(String trackId) async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', widget.playlistId)
          .eq('track_id', trackId);

      if (mounted) {
        await _loadPlaylistTracks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек удален из плейлиста')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления трека: $e')),
        );
      }
    }
  }

  void _playTrack(Track track, BuildContext context) {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    audioService.loadTrack(
      track,
      trackList: _tracks,
      autoPlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_showSettings) {
              setState(() => _showSettings = false);
            } else {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            }
          },
        ),
        actions: [
          if (!_showSettings)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => setState(() => _showSettings = true),
            ),
        ],
      ),
      body: Container(
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _showSettings
                ? _buildPlaylistSettings()
                : _buildPlaylistContent(),
      ),
    );
  }

  Widget _buildPlaylistSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 80),
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                _newPlaylistImage ?? widget.playlistImage,
              ),
              backgroundColor: Colors.grey[800],
              child: _newPlaylistImage == null
                  ? const Icon(Icons.add_photo_alternate,
                      size: 40, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название плейлиста',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => _newPlaylistName = value,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              _newPlaylistName = _nameController.text;
              _updatePlaylist();
            },
            child: const Text('Сохранить изменения',
            style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удалить плейлист?', style: TextStyle(color: Colors.white)),
                  content: Text(
                      'Вы уверены, что хотите удалить "${widget.playlistName}"?',
                      style: const TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Отмена',
                      style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Удалить',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await _deletePlaylist();
              }
            },
            child: const Text('Удалить плейлист', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _showSettings = false),
            child: const Text('Отмена', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 80),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.playlistImage,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[800],
                      child:
                          Icon(Icons.music_note, color: Colors.white, size: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.playlistName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_tracks.length} ${_tracks.length == 1 ? 'трек' : _tracks.length < 5 ? 'трека' : 'треков'}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_tracks.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'В плейлисте нет треков',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = _tracks[index];
                track.isFavorite = _favoriteIds.contains(track.id);
                return ListTile(
                  onTap: () => _playTrack(track, context),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    track.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track.authorName,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          track.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: track.isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(track),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _removeTrack(track.id),
                      ),
                    ],
                  ),
                );
              },
              childCount: _tracks.length,
            ),
          ),
      ],
    );
  }
}
