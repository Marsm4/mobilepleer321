import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistPage({
    Key? key,
    required this.playlistId,
    required this.playlistName,
  }) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _allTracks = [];
  bool _isLoading = true;
  bool _showAddTrackDialog = false;
  String _errorMessage = '';
  final TextEditingController _renameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _renameController.text = widget.playlistName;
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPlaylistTracks(),
      _loadAllTracks(),
    ]);
  }

  Future<void> _loadPlaylistTracks() async {
    try {
      final response = await _supabase
          .from('play_list')
          .select('''
            track:track_id(
              id, 
              name, 
              image, 
              url_music,
              author:author_id(name)
            )
          ''')
          .eq('list_id', widget.playlistId);

      if (response == null) throw Exception('Пустой ответ от сервера');

      setState(() {
        _tracks = (response as List<dynamic>).map((item) {
          final track = item['track'] as Map<String, dynamic>? ?? {};
          return {
            'id': track['id']?.toString() ?? '',
            'title': track['name']?.toString() ?? 'Без названия',
            'author': track['author']?['name']?.toString() ?? 'Исполнитель',
            'urlMusic': track['url_music']?.toString() ?? '',
            'urlPhoto': track['image']?.toString() ?? '',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки треков: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllTracks() async {
    try {
      final response = await _supabase
          .from('track')
          .select('''
            id, 
            name, 
            image, 
            url_music,
            author:author_id(name)
          ''');

      if (response == null) throw Exception('Пустой ответ от сервера');

      setState(() {
        _allTracks = (response as List<dynamic>).map((track) {
          return {
            'id': track['id']?.toString() ?? '',
            'title': track['name']?.toString() ?? 'Без названия',
            'author': track['author']?['name']?.toString() ?? 'Исполнитель',
            'urlMusic': track['url_music']?.toString() ?? '',
            'urlPhoto': track['image']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Ошибка загрузки всех треков: $e');
    }
  }

  Future<void> _addTrackToPlaylist(String trackId) async {
    try {
      final existing = await _supabase
          .from('play_list')
          .select()
          .eq('list_id', widget.playlistId)
          .eq('track_id', trackId);

      if (existing != null && existing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот трек уже есть в плейлисте')),
        );
        return;
      }

      await _supabase
          .from('play_list')
          .insert({
            'list_id': widget.playlistId,
            'track_id': trackId,
          });

      await _loadPlaylistTracks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек добавлен в плейлист')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeTrack(String trackId) async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .match({
            'list_id': widget.playlistId,
            'track_id': trackId,
          });

      await _loadPlaylistTracks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек удалён из плейлиста')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50),  // Темный серо-голубой
            Color(0xFF4CA1AF),  // Голубовато-серый
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.playlistName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => setState(() => _showAddTrackDialog = true),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _showRenameDialog,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showDeleteDialog,
            ),
          ],
        ),
        body: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_showAddTrackDialog) {
      return _buildAddTrackDialog();
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Плейлист пуст',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2C3E50),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              onPressed: () => setState(() => _showAddTrackDialog = true),
              child: const Text('Добавить треки'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Треки',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _tracks.length,
            itemBuilder: (context, index) {
              final track = _tracks[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: _buildTrackImage(track['urlPhoto']),
                  title: Text(
                    track['title'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track['author'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => _removeTrack(track['id']),
                  ),
                  onTap: () {
                    // TODO: Реализовать воспроизведение трека
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddTrackDialog() {
    final filteredTracks = _searchController.text.isEmpty
        ? _allTracks
        : _allTracks.where((track) =>
            track['title'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            track['author'].toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск треков',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredTracks.length,
            itemBuilder: (context, index) {
              final track = filteredTracks[index];
              final alreadyInPlaylist = _tracks.any((t) => t['id'] == track['id']);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: _buildTrackImage(track['urlPhoto']),
                  title: Text(
                    track['title'],
                    style: TextStyle(
                      color: alreadyInPlaylist ? Colors.white54 : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    track['author'],
                    style: TextStyle(
                      color: alreadyInPlaylist ? Colors.white30 : Colors.white70,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      alreadyInPlaylist ? Icons.check : Icons.add,
                      color: alreadyInPlaylist ? Colors.grey : Colors.white,
                    ),
                    onPressed: alreadyInPlaylist 
                        ? null 
                        : () => _addTrackToPlaylist(track['id']),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2C3E50),
            ),
            onPressed: () => setState(() => _showAddTrackDialog = false),
            child: const Text('Готово'),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _showRenameDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Переименовать плейлист',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _renameController,
          decoration: const InputDecoration(
            hintText: 'Новое название',
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              if (_renameController.text.isNotEmpty) {
                await _renamePlaylist();
                Navigator.pop(context);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _renamePlaylist() async {
    try {
      await _supabase
          .from('list')
          .update({'list_name': _renameController.text})
          .eq('id', widget.playlistId);

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Плейлист переименован')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Удалить плейлист?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Все треки из этого плейлиста будут удалены. Вы уверены?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlaylist();
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlaylist() async {
    try {
      await _supabase
          .from('play_list')
          .delete()
          .eq('list_id', widget.playlistId);

      await _supabase
          .from('list')
          .delete()
          .eq('id', widget.playlistId);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Плейлист удалён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: ${e.toString()}')),
      );
    }
  }
}