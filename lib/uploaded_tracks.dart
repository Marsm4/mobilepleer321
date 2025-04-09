import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/playlist_service.dart';
import 'package:music_player/services/track_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UploadedTracksPage extends StatefulWidget {
  const UploadedTracksPage({super.key});

  @override
  State<UploadedTracksPage> createState() => _UploadedTracksPageState();
}

class _UploadedTracksPageState extends State<UploadedTracksPage> {
  final TrackService _trackService = TrackService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final PlaylistService _playlistService = PlaylistService();

  List<Track> _tracks = [];
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _authors = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _isDisposed = false; // Добавляем флаг для отслеживания состояния

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadData();
  }

  @override
  void dispose() {
    _isDisposed = true; // Устанавливаем флаг при dispose
    super.dispose();
  }

  // Обертка для проверки mounted и isDisposed перед обновлением состояния
  void _safeSetState(VoidCallback fn) {
    if (!mounted || _isDisposed) return;
    setState(fn);
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        _trackService.getAllTracks(),
        _supabase.from('genre').select().order('name'),
        _supabase.from('album').select().order('name'),
        _supabase.from('author').select().order('name'),
      ]);

      _safeSetState(() {
        _tracks = (results[0] as List<Track>)
            .where((track) => track.userId == _currentUserId)
            .toList();
        _genres = List<Map<String, dynamic>>.from(results[1] as List);
        _albums = List<Map<String, dynamic>>.from(results[2] as List);
        _authors = List<Map<String, dynamic>>.from(results[3] as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTrack(String trackId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить трек?'),
        content: const Text(
          'Вы уверены, что хотите удалить этот трек? Он будет удален из всех плейлистов.',
          style: TextStyle(color: Colors.black),
        ),
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

    if (confirmed == true) {
      try {
        // Сначала удаляем трек из всех плейлистов
        await _supabase.from('play_list').delete().eq('track_id', trackId);

        // Затем удаляем трек из избранного
        await _supabase.from('favorites').delete().eq('track_id', trackId);

        // И только потом удаляем сам трек
        await _trackService.deleteTrack(trackId);

        if (!mounted || _isDisposed) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Трек удален')),
        );
        await _loadData();
        Provider.of<AudioPlayerService>(context, listen: false).refreshTracks();
      } catch (e) {
        if (!mounted || _isDisposed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  Future<void> _editTrack(Track track) async {
    final nameController = TextEditingController(text: track.name);
    String? newImagePath;
    PlatformFile? imageFile;
    String? selectedAuthor = track.authorId;
    String? selectedAlbum = track.albumId;
    String? selectedGenre = track.genreId;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Редактировать трек'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Название трека'),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedAuthor,
                    decoration: const InputDecoration(labelText: 'Исполнитель'),
                    items: _authors.map((author) {
                      return DropdownMenuItem<String>(
                        value: author['id'].toString(),
                        child:
                            Text(author['name'] ?? 'Неизвестный исполнитель'),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedAuthor = value),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedAlbum,
                    decoration: const InputDecoration(labelText: 'Альбом'),
                    items: _albums.map((album) {
                      return DropdownMenuItem<String>(
                        value: album['id'].toString(),
                        child: Text(album['name'] ?? 'Без альбома'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedAlbum = value),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedGenre,
                    decoration: const InputDecoration(labelText: 'Жанр'),
                    items: _genres.map((genre) {
                      return DropdownMenuItem<String>(
                        value: genre['id'].toString(),
                        child: Text(genre['name'] ?? 'Без жанра'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedGenre = value),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: OutlinedButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        if (result != null) {
                          setState(() {
                            imageFile = result.files.first;
                            newImagePath = imageFile?.path;
                          });
                        }
                      },
                      child: Text(
                        imageFile?.name ?? 'Изменить обложку',
                        style: const TextStyle(
                            color: Color.fromARGB(255, 31, 31, 31)),
                      ),
                    ),
                  ),
                  if (imageFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Размер: ${(imageFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      try {
        String? imageUrl;
        if (newImagePath != null) {
          final file = File(newImagePath!);
          final fileName =
              'track_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
          await _supabase.storage
              .from('storages')
              .upload('images/$fileName', file);
          imageUrl = _supabase.storage
              .from('storages')
              .getPublicUrl('images/$fileName');
        }

        await _supabase.from('track').update({
          'name': nameController.text,
          'author_id': selectedAuthor,
          'album_id': selectedAlbum,
          'genre_id': selectedGenre,
          if (imageUrl != null) 'image': imageUrl,
        }).eq('id', track.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Трек обновлен')),
          );
          await _loadData();
          Provider.of<AudioPlayerService>(context, listen: false)
              .refreshTracks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка обновления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои треки'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(child: Text('Вы еще не загрузили ни одного трека'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      return ListTile(
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
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        title: Text(track.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(track.authorName,
                            style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _editTrack(track),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _deleteTrack(track.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
