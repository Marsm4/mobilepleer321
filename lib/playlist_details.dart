import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistDetailsPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailsPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tracks = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPlaylistTracks();
  }

  Future<void> _fetchPlaylistTracks() async {
    try {
      final response = await supabase.from('play_list').select('''
            track:track_id (
              id, 
              name, 
              image, 
              url_music, 
              author:author_id (name)
            )
          ''').eq('list_id', int.parse(widget.playlistId));

      setState(() {
        tracks = List<Map<String, dynamic>>.from(response.map((item) {
          final track = item['track'];
          return {
            'id': track['id'],
            'title': track['name'],
            'image': track['image'],
            'author': track['author']?['name'] ?? 'Неизвестный исполнитель',
            'urlMusic': track['url_music'],
          };
        }));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки треков';
        isLoading = false;
      });
    }
  }

  Future<void> _showAddTracksDialog() async {
    try {
      final allTracksResponse = await supabase
          .from('track')
          .select('id, name, image, author:author_id(name)')
          .order('created_at', ascending: false);

      final allTracks =
          List<Map<String, dynamic>>.from(allTracksResponse.map((track) {
        return {
          'id': track['id'],
          'title': track['name'],
          'image': track['image'],
          'author': track['author']?['name'] ?? 'Неизвестный исполнитель',
        };
      }));

      final existingTrackIds = tracks.map((t) => t['id']).toList();
      final availableTracks = allTracks
          .where((track) => !existingTrackIds.contains(track['id']))
          .toList();

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Color(0xFF282828),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Добавить треки в "${widget.playlistName}"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              Flexible(
                child: availableTracks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Все треки уже добавлены',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableTracks.length,
                        itemBuilder: (context, index) {
                          final track = availableTracks[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: track['image'] == null ||
                                    track['image'].isEmpty
                                ? Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      track['image'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                            title: Text(
                              track['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              track['author'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            trailing: IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF1DB954),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () async {
                                await _addTrackToPlaylist(track['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Трек "${track['title']}" добавлен'),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: Color(0xFF1DB954),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Готово'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки треков: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTrackToPlaylist(int trackId) async {
    try {
      await supabase.from('play_list').insert({
        'track_id': trackId,
        'list_id': int.parse(widget.playlistId),
      });
      await _fetchPlaylistTracks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления трека: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeTrackFromPlaylist(int trackId) async {
    try {
      await supabase
          .from('play_list')
          .delete()
          .eq('track_id', trackId)
          .eq('list_id', int.parse(widget.playlistId));
      await _fetchPlaylistTracks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления трека: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.playlistName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _showAddTracksDialog,
            tooltip: 'Добавить треки',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchPlaylistTracks,
          ),
        ],
      ),
      body: _buildTrackList(),
    );
  }

  Widget _buildTrackList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Плейлист пуст',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddTracksDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Добавить треки'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFF282828),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: track['image'] == null || track['image'].isEmpty
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track['image'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
            title: Text(
              track['title'] ?? 'Без названия',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              track['author'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            trailing: IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.remove,
                  size: 20,
                  color: Colors.red,
                ),
              ),
              onPressed: () => _removeTrackFromPlaylist(track['id']),
            ),
          ),
        );
      },
    );
  }
}
