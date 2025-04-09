import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/music/player.dart';
import 'package:provider/provider.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  late final AudioPlayer audioPlayer;
  bool isPlaying = false;
  Duration _duration = Duration();
  Duration _position = Duration();
  UrlSource? urlSource;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();

    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _position = _duration;
        isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void playPause() async {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    
    if (isPlaying) {
      await audioPlayer.pause();
      isPlaying = false;
    } else {
      if (urlSource == null && playerService.currentMusicUrl != null) {
        urlSource = UrlSource(playerService.currentMusicUrl!);
      }
      if (urlSource != null) {
        await audioPlayer.play(urlSource!);
        isPlaying = true;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);

    if (playerService.currentTrackName == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade700,
      ),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => PlayerPage(
                  nameSound: playerService.currentTrackName!,
                  author: playerService.currentArtist!,
                  urlMusic: playerService.currentMusicUrl!,
                  urlPhoto: playerService.currentImageUrl!,
                ),
              ),
            );
          },
          leading: Image.network(
            playerService.currentImageUrl!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
            child: Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              activeColor: Colors.blue,
              inactiveColor: Colors.white,
              value: _position.inSeconds.toDouble(),
              onChanged: (value) async {
                await audioPlayer.seek(Duration(seconds: value.toInt()));
                setState(() {});
              },
            ),
          ),
          subtitle: Text(
            playerService.currentTrackName!,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            color: Colors.white,
            onPressed: playPause,
            icon: isPlaying
                ? Icon(
                    Icons.pause_circle,
                    size: MediaQuery.of(context).size.height * 0.04,
                  )
                : Icon(
                    Icons.play_circle,
                    size: MediaQuery.of(context).size.height * 0.04,
                  ),
          ),
        ),
      ),
    );
  }
}

class PlayerService extends ChangeNotifier {
  AudioPlayer? _audioPlayer;
  String? currentTrackName;
  String? currentArtist;
  String? currentMusicUrl;
  String? currentImageUrl;
  bool isPlaying = false;
  Duration position = Duration.zero;

  bool get hasActivePlayer => _audioPlayer != null;

  void initPlayer(
    String name,
    String artist,
    String musicUrl,
    String imageUrl, {
    bool isPlaying = false,
    Duration position = Duration.zero,
  }) {
    currentTrackName = name;
    currentArtist = artist;
    currentMusicUrl = musicUrl;
    currentImageUrl = imageUrl;
    isPlaying = isPlaying;
    position = position;
    
    _audioPlayer ??= AudioPlayer();
    notifyListeners();
  }
}