import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/player_state.dart';
import 'package:music_player/player_page.dart';

class TracksPage extends StatefulWidget {
  const TracksPage({super.key});

  @override
  State<TracksPage> createState() => _TracksPageState();
}

class _TracksPageState extends State<TracksPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _filteredTracks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTracks();
    _searchController.addListener(_filterTracks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTracks() async {
    try {
      final response = await _supabase
          .from('track')
          .select('*, author:author_id(name)')
          .order('name', ascending: true);

      setState(() {
        _tracks = response;
        _filteredTracks = List.from(_tracks);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки треков: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTracks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTracks = _tracks.where((track) {
        final name = track['name']?.toString().toLowerCase() ?? '';
        final author = track['author']?['name']?.toString().toLowerCase() ?? '';
        return name.contains(query) || author.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerState>(context);

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text('Все треки', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[800],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Поиск',
                labelStyle: TextStyle(color: Colors.blueGrey[300]),
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey[300]),
                filled: true,
                fillColor: Colors.blueGrey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[300]))
                : _filteredTracks.isEmpty
                    ? Center(
                        child: Text(
                          'Треки не найдены',
                          style: TextStyle(color: Colors.blueGrey[300]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTracks.length,
                        itemBuilder: (context, index) {
                          final track = _filteredTracks[index];
                          final isCurrentTrack = playerState.currentTrackUrl == track['url_music'];
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrentTrack 
                                  ? Colors.blueGrey[700] 
                                  : Colors.blueGrey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: track['image'] != null
                                    ? Image.network(
                                        track['image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.blueGrey[600],
                                        child: Center(
                                          child: Icon(
                                            Icons.music_note,
                                            color: Colors.blueGrey[300],
                                          ),
                                        ),
                                      ),
                              ),
                              title: Text(
                                track['name'] ?? 'Без названия',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                track['author']?['name'] ?? 'Неизвестный исполнитель',
                                style: TextStyle(color: Colors.blueGrey[300]),
                              ),
                              trailing: Icon(
                                isCurrentTrack && playerState.isPlaying 
                                    ? Icons.pause 
                                    : Icons.play_arrow,
                                color: Colors.blueGrey[300],
                              ),
                              onTap: () {
                                if (track['url_music'] != null) {
                                  playerState.playTrack(
                                    track['url_music'],
                                    track['name'] ?? 'Без названия',
                                    track['author']?['name'] ?? 'Неизвестный исполнитель',
                                    track['image'],
                                    playlist: _filteredTracks,
                                    index: index,
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: InkWell(
        onTap: () {
          if (playerState.currentTrackUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerPage()),
            );
          }
        },
        child: _buildPlayerBar(playerState),
      ),
    );
  }

  Widget _buildPlayerBar(PlayerState playerState) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blueGrey[800]!,
        border: Border(top: BorderSide(
          color: Colors.blueGrey[600]!,
          width: 1,
        )),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: playerState.currentTrackImage != null
                  ? Image.network(
                      playerState.currentTrackImage!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.blueGrey[600],
                      child: Icon(Icons.music_note, color: Colors.white),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerState.currentTrackName ?? 'Название трека',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  playerState.currentTrackAuthor ?? 'Исполнитель',
                  style: TextStyle(color: Colors.blueGrey[300], fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (playerState.currentTrackUrl != null) {
                if (playerState.isPlaying) {
                  playerState.pause();
                } else {
                  playerState.resume();
                }
              }
            },
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}