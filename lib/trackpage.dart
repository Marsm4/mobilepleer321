import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  _TrackPageState createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  List tracks = [];
  int currentTrackIndex = 0;
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration trackDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    fetchTracks();

    audioPlayer.onDurationChanged.listen((duration) {
      setState(() => trackDuration = duration);
    });

    audioPlayer.onPositionChanged.listen((position) {
      setState(() => currentPosition = position);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      nextTrack();
    });
  }

Future fetchTracks() async {
  final response = await Supabase.instance.client.from('track').select('*');
  setState(() {
    tracks = response;
  });

  if (tracks.isNotEmpty) {
    currentTrackIndex = 0;
    playTrack(tracks[currentTrackIndex]['musicurl']);
  }
}

  void playTrack(String url) async {
    await audioPlayer.play(UrlSource(url));
    setState(() => isPlaying = true);
  }

  void pauseTrack() async {
    await audioPlayer.pause();
    setState(() => isPlaying = false);
  }

  void nextTrack() {
    if (tracks.isEmpty) return;

    currentTrackIndex = (currentTrackIndex + 1) % tracks.length;
    playTrack(tracks[currentTrackIndex]['musicurl']);
  }

  void previousTrack() {
    if (tracks.isEmpty) return;

    currentTrackIndex = currentTrackIndex == 0 ? tracks.length - 1 : currentTrackIndex - 1;
    playTrack(tracks[currentTrackIndex]['musicurl']);
  }

  @override
  Widget build(BuildContext context) {
    final trackTitle = tracks.isNotEmpty
        ? tracks[currentTrackIndex]['name']
        : 'Загрузка...';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blueGrey, Colors.blue],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Мой плейлист', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blueGrey,
        ),
        body: Center(
          child: Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    trackTitle,
                    style: const TextStyle(fontSize: 22, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withOpacity(0.3),
                    min: 0,
                    max: trackDuration.inSeconds.toDouble(),
                    value: currentPosition.inSeconds.clamp(0, trackDuration.inSeconds).toDouble(),
                    onChanged: (value) async {
                      await audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: previousTrack,
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            pauseTrack();
                          } else {
                            playTrack(tracks[currentTrackIndex]['musicurl']);
                          }
                        },
                      ),
                      const SizedBox(width: 30),
                      IconButton(
                        onPressed: nextTrack,
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const Footer(),
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}