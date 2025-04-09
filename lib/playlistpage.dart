import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final List<Map<String, String>> tracks = [
    {'title': 'Трек 1', 'author': 'Автор 1'},
    {'title': 'Трек 2', 'author': 'Автор 2'},
    {'title': 'Трек 3', 'author': 'Автор 3'},
    {'title': 'Трек 4', 'author': 'Автор 4'},
    {'title': 'Трек 5', 'author': 'Автор 5'},
  ];

  final List<Map<String, String>> playlists = [
    {'title': 'Плейлист 1'},
    {'title': 'Плейлист 2'},
    {'title': 'Плейлист 3'},
    {'title': 'Плейлист 4'},
    {'title': 'Плейлист 5'},
    {'title': 'Плейлист 6'},
  ];

  final List<Map<String, String>> artists = [
    {'name': 'Исполнитель 1'},
    {'name': 'Исполнитель 2'},
    {'name': 'Исполнитель 3'},
    {'name': 'Исполнитель 4'},
    {'name': 'Исполнитель 5'},
  ];

  String searchQuery = '';
  int currentTrackIndex = 0;
  bool isPlaying = true;

  List<Map<String, String>> get filteredTracks => tracks
      .where((track) =>
          track['title']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          track['author']!.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Ваши плейлисты', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // Основной контент
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 80), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: playlists.map((playlist) {
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 50) / 2, // 2 колонки
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.image, color: Colors.white, size: 40),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    playlist['title']!,
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
         
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey[600],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.music_note, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tracks[currentTrackIndex]['title']!,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tracks[currentTrackIndex]['author']!,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () => setState(() => isPlaying = !isPlaying),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.3,
                    backgroundColor: Colors.white.withValues(alpha: .3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20), 
          ],
        ),
        bottomNavigationBar: Footer(),
      ),
    );
  }
}
