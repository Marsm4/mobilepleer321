import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/player_state.dart';
import 'package:music_player/player_page.dart';

class ArtistPage extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String? artistImage;

  const ArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistImage,
  });

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArtistData();
  }

  Future<void> _fetchArtistData() async {
    try {
      final albumsResponse = await _supabase
          .from('album')
          .select()
          .eq('author_id', widget.artistId);

      final tracksResponse = await _supabase
          .from('track')
          .select()
          .eq('author_id', widget.artistId);

      setState(() {
        _albums = albumsResponse;
        _tracks = tracksResponse;
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
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[300]))
              : SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 80), // Отступ для плеера
                  child: Column(
                    children: [
                      // Аватарка исполнителя
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blueGrey[800],
                              backgroundImage: widget.artistImage != null
                                  ? NetworkImage(widget.artistImage!)
                                  : null,
                              child: widget.artistImage == null
                                  ? Icon(Icons.person, size: 60, color: Colors.blueGrey[300])
                                  : null,
                            ),
                            SizedBox(height: 16),
                            Text(
                              widget.artistName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Альбомы исполнителя
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Альбомы',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                                    child: Text(
                                      album['name'] ?? 'Без названия',
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
                      SizedBox(height: 24),
                      // Треки исполнителя
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Треки',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _tracks.length,
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          return ListTile(
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
                                      color: Colors.blueGrey[800],
                                      child: Icon(Icons.music_note, color: Colors.blueGrey[300]),
                                    ),
                            ),
                            title: Text(
                              track['name'] ?? 'Без названия',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              track['author'] ?? 'Неизвестный исполнитель',
                              style: TextStyle(color: Colors.blueGrey[300]),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.play_arrow, color: Colors.white),
                              onPressed: () {
                                final playerState = Provider.of<PlayerState>(context, listen: false);
                                playerState.playTrack(
                                  track['url'],
                                  track['name'],
                                  track['author'],
                                  track['image'],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          // Плеер внизу экрана
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<PlayerState>(
              builder: (context, playerState, child) {
                if (playerState.currentTrackUrl == null) return SizedBox.shrink();
                return _buildPlayerBar(playerState);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar(PlayerState playerState) {
    return InkWell(
      onTap: () {
        if (playerState.currentTrackUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlayerPage()),
          );
        }
      },
      child: Container(
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
      ),
    );
  }
}