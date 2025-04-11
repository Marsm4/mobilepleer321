import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/audioplayer.dart';

class PlaylistPage extends StatefulWidget {
  final Map<String, dynamic> playlist;

  const PlaylistPage({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final AudioPlayerService _audioService;
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  String? _error;
  int? _currentTrackIndex;

  @override
  void initState() {
    super.initState();
    _audioService = AudioPlayerService(); // Инициализация
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tracks.isEmpty) {
      _validateAndLoadTracks();
    }
    _audioService.currentTrack.addListener(_updateCurrentTrack);
  }

  @override
  void dispose() {
    _audioService.currentTrack.removeListener(_updateCurrentTrack);
    super.dispose();
  }

  void _updateCurrentTrack() {
    if (_audioService.currentTrack.value != null && mounted) {
      setState(() {
        _currentTrackIndex = _tracks.indexWhere(
          (t) => t['id'] == _audioService.currentTrack.value!['id'],
        );
      });
    }
  }

  void _validateAndLoadTracks() {
    if (widget.playlist.isEmpty || widget.playlist['id'] == null) {
      setState(() {
        _isLoading = false;
        _error = 'Плейлист не найден или неверные данные';
      });
      return;
    }

    final playlistId = widget.playlist['id'].toString();
    if (playlistId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Неверный ID плейлиста';
      });
      return;
    }

    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await _audioService.getPlaylistTracks(
        widget.playlist['id']?.toString() ?? '',
      );
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка загрузки треков: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _playTrack(int index) async {
    try {
      await _audioService.playTrack(_tracks[index], tracks: _tracks);
      if (mounted) {
        setState(() {
          _currentTrackIndex = index;
        });
        _showSuccessMessage(
          'Трек "${_tracks[index]['name'] ?? 'Без названия'}" начал воспроизводиться',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Ошибка воспроизведения: ${e.toString()}');
      }
    }
  }

  Future<void> _removeTrackFromPlaylist(int index) async {
    try {
      final trackId = _tracks[index]['id'].toString();
      final playlistId = widget.playlist['id'].toString();
      final trackName = _tracks[index]['name']?.toString() ?? 'Без названия';

      await _audioService.removeFromPlaylist(playlistId, trackId);

      if (mounted) {
        setState(() {
          _tracks.removeAt(index);
          if (_currentTrackIndex == index) {
            _currentTrackIndex = null;
          }
        });
        _showSuccessMessage('Трек "$trackName" удалён из плейлиста');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Ошибка удаления трека: ${e.toString()}');
      }
    }
  }

  Future<void> _deletePlaylist() async {
    try {
      final playlistId = widget.playlist['id'].toString();
      final playlistName =
          widget.playlist['list_name']?.toString() ?? 'Без названия';

      await _audioService.deletePlaylist(playlistId);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessMessage('Плейлист "$playlistName" удалён');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Ошибка удаления плейлиста: ${e.toString()}');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить плейлист?'),
            content: const Text(
              'Вы уверены, что хотите удалить этот плейлист? Это действие нельзя отменить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePlaylist();
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

  void _showAddToPlaylistDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить трек в плейлист'),
          content: const Text(
            'Выберите плейлист для добавления текущего трека',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );

    if (result == true && _audioService.currentTrack.value != null) {
      try {
        final trackId = _audioService.currentTrack.value!['id'].toString();
        final playlistId = widget.playlist['id'].toString();
        await _audioService.addToPlaylist(playlistId, trackId);
        await _loadTracks(); // Refresh the playlist
        _showSuccessMessage('Трек добавлен в плейлист');
      } catch (e) {
        _showErrorMessage('Ошибка добавления трека: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 1, 105),
      appBar: AppBar(
        title: Text(
          widget.playlist['list_name']?.toString() ?? 'Плейлист',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 25, 1, 105),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddToPlaylistDialog(context),
            tooltip: 'Добавить трек',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: 'Удалить плейлист',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPlaylistContent()),
          GlobalFooter(audioService: _audioService),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.playlist['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.playlist['image']!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Этот плейлист пуст',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showAddToPlaylistDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:  Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Добавить трек'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _showDeleteConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Удалить плейлист'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                _currentTrackIndex == index
                    ?  Color.fromARGB(255, 25, 1, 105)
                    : Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  track['image'] != null
                      ? Image.network(
                        track['image']!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
            ),
            title: Text(
              track['name']?.toString() ?? 'Без названия',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              track['author']?['name']?.toString() ?? 'Неизвестный исполнитель',
              style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  onPressed: () => _playTrack(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTrackFromPlaylist(index),
                ),
              ],
            ),
            onTap: () => _playTrack(index),
          ),
        );
      },
    );
  }
}
