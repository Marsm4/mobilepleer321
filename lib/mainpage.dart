import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/tracks_page.dart';
import 'package:music_player/player_state.dart';
import 'package:music_player/player_page.dart';
import 'package:music_player/artist_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _artists = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _defaultPlaylists = [
    {'name': 'Избранное', 'image': null},
    {'name': 'Плейлист 1', 'image': null},
    {'name': 'Плейлист 2', 'image': null},
    {'name': 'Плейлист 3', 'image': null},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не аутентифицирован');
      }

      final playlistsResponse = await _supabase
          .from('list')
          .select()
          .eq('user_id', userId);

      final albumsResponse = await _supabase
          .from('album')
          .select();

      final artistsResponse = await _supabase
          .from('author')
          .select();

      setState(() {
        _playlists = playlistsResponse;
        _albums = albumsResponse;
        _artists = artistsResponse;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerState>(context);
    final displayPlaylists = _playlists.isNotEmpty ? _playlists : _defaultPlaylists;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Главная',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: Icon(Icons.person, color: Colors.white, size: 30),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[300]))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Ваши плейлисты',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: displayPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = displayPlaylists[index];
                        return Container(
                          width: 150,
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blueGrey[800],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: playlist['image'] != null
                                      ? Image.network(
                                          playlist['image'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.blueGrey[600],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.music_note, size: 50, color: Colors.blueGrey[300]),
                                                SizedBox(height: 8),
                                                
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  playlist['name'] ?? 'Без названия',
                                  style: TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Популярные исполнители',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _artists.length,
                      itemBuilder: (context, index) {
                        final artist = _artists[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/artist',
                              arguments: {
                                'artistId': artist['id'],
                                'artistName': artist['name'],
                                'artistImage': artist['image'],
                              },
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blueGrey[800],
                                  backgroundImage: artist['image'] != null
                                      ? NetworkImage(artist['image'])
                                      : null,
                                  child: artist['image'] == null
                                      ? Icon(Icons.person, size: 30, color: Colors.blueGrey[300])
                                      : null,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  artist['name'],
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'Альбомы',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        final album = _albums[index];
                        return Container(
                          width: 150,
                          margin: EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.blueGrey[800],
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: album['image'] != null
                                      ? Image.network(
                                          album['image'],
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.blueGrey[600],
                                          child: Center(
                                            child: Icon(Icons.album, size: 50, color: Colors.blueGrey[300]),
                                          ),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      album['name'] ?? 'Без названия',
                                      style: TextStyle(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (album['game'] != null && album['game']['name'] != null)
                                      Text(
                                        album['game']['name'],
                                        style: TextStyle(color: Colors.blueGrey[300], fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TracksPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Все треки',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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