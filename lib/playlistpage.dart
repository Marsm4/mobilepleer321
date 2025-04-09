import 'package:flutter/material.dart';
import 'package:flutter_player/like_service.dart' as like_service;
import 'package:flutter_player/search_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/playlist_tracks_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:flutter_player/player_state.dart' as player_state;

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final LikeService _likeService = LikeService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _myPlaylists = [];
  
  @override
  void initState() {
    super.initState();
    _fetchMyPlaylists();
  }

  Future<void> _fetchMyPlaylists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('list')
          .select('''
            *, 
            play_list(count)
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myPlaylists = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке плейлистов: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddToPlaylistDialog(String trackUrl) async {
    if (_myPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет плейлистов')),
      );
      return;
    }

    final selectedPlaylist = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[800],
        title: const Text('Добавить в плейлист', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _myPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = _myPlaylists[index];
              final imageUrl = playlist['image'] ?? 
                  'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';
              final trackCount = playlist['play_list']?[0]['count'] ?? 0;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(imageUrl),
                  radius: 25,
                ),
                title: Text(
                  playlist['list_name'] ?? 'Без названия',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '$trackCount треков',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () => Navigator.pop(context, playlist['id']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (selectedPlaylist != null) {
      await _addTrackToPlaylist(selectedPlaylist, trackUrl);
    }
  }

  Future<void> _addTrackToPlaylist(int playlistId, String trackUrl) async {
    try {
      setState(() => _isLoading = true);
      
      final trackResponse = await _supabase
          .from('tracks')
          .select('id')
          .eq('url', trackUrl)
          .single();

      final trackId = trackResponse['id'] as int;

      final existingResponse = await _supabase
          .from('play_list')
          .select()
          .eq('list_id', playlistId)
          .eq('track_id', trackId);

      if (existingResponse.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот трек уже есть в плейлисте')),
        );
        return;
      }

      await _supabase
          .from('play_list')
          .insert({
            'list_id': playlistId,
            'track_id': trackId,
          });

      await _fetchMyPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек добавлен в плейлист!')),
      );
    } catch (e) {
      print('Ошибка при добавлении трека: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPlaylist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    final textController = TextEditingController();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    Uint8List? imageBytes;

    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать плейлист'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Название плейлиста',
                border: OutlineInputBorder(),
              ),
            ),
            if (imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(imageBytes),
                      fit: BoxFit.cover,
                    ),
                  ),
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
            onPressed: () {
              if (textController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название плейлиста')),
                );
                return;
              }
              Navigator.pop(context, textController.text.trim());
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      setState(() => _isLoading = true);
      
      String? imageUrl;
      if (imageBytes != null) {
        final filePath = 'playlist_covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('storage').uploadBinary(filePath, imageBytes);
        imageUrl = _supabase.storage.from('storage').getPublicUrl(filePath);
      } else {
        imageUrl = 'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';
      }

      await _supabase.from('list').insert({
        'list_name': result,
        'id_user': userId,
        'image': imageUrl,
      });

      await _fetchMyPlaylists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Плейлист "$result" создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final trackCount = playlist['play_list']?[0]['count'] ?? 0;
    final imageUrl = playlist['image'] ?? 
        'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistTracksPage(
  playlistId: playlist['id'],
  playlistName: playlist['list_name'],
  onTrackSelected: (url, title, author, image) {
    final playerState = Provider.of<player_state.AppPlayerState>(context, listen: false);
    playerState.playTrack(url, title, author, image);
  },
),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
          image: imageUrl != null 
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            if (imageUrl == null)
              const Center(
                child: Icon(Icons.music_note, size: 50, color: Colors.white70),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['list_name'] ?? 'Без названия',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$trackCount треков',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои плейлисты', style: TextStyle(color: Colors.white)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton(
                  onPressed: _createPlaylist,
                  mini: true,
                  child: const Icon(Icons.add, color: Colors.white),
                  backgroundColor: const Color.fromARGB(255, 0, 38, 255),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _myPlaylists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'У вас пока нет плейлистов',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _createPlaylist,
                                child: const Text('Создать плейлист'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 0, 38, 255),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            childAspectRatio: 1.0,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _myPlaylists.length,
                          itemBuilder: (context, index) {
                            return _buildPlaylistCard(_myPlaylists[index]);
                          },
                        ),
            ),
            const Footer(), // Используем футер как в HomePage
          ],
        ),
      ),
    );
  }
}