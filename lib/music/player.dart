import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_player/footer.dart';

class PlayerPage extends StatefulWidget {
  final String? urlMusic;
  final String? urlPhoto;
  final String? nameSound;
  final String? author;
  
  const PlayerPage({
    super.key,
    this.urlMusic,
    this.urlPhoto,
    this.nameSound,
    this.author,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final AudioPlayer audioPlayer;
  bool isPlaying = false;
  late final UrlSource urlSource;
  Duration _duration = Duration();
  Duration _position = Duration();
  bool _isDisposed = false; // Флаг для отслеживания состояния dispose

  Future initPlayer() async {
    audioPlayer = AudioPlayer();
    urlSource = UrlSource(widget.urlMusic!);

    audioPlayer.onDurationChanged.listen((duration) {
      if (!_isDisposed) {
        setState(() {
          _duration = duration;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((position) {
      if (!_isDisposed) {
        setState(() {
          _position = position;
        });
      }
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (!_isDisposed) {
        setState(() {
          _position = _duration;
          isPlaying = false;
        });
      }
    });
  }

  void playPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
      if (!_isDisposed) {
        setState(() {
          isPlaying = false;
        });
      }
    } else {
      await audioPlayer.play(urlSource);
      if (!_isDisposed) {
        setState(() {
          isPlaying = true;
        });
      }
    }
  }

  Future<void> _transferToMiniPlayer() async {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    playerService.initPlayer(
      widget.nameSound!,
      widget.author!,
      widget.urlMusic!,
      widget.urlPhoto!,
    );
    
    // Сохраняем состояние воспроизведения перед выходом
    final wasPlaying = isPlaying;
    
    if (wasPlaying) {
      await audioPlayer.pause();
    }
    
    if (!_isDisposed) {
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    initPlayer().then((_) {
      if (!_isDisposed) {
        playPause();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _transferToMiniPlayer,
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.urlPhoto!,
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
            ListTile(
              textColor: Colors.white,
              title: Text(
                widget.nameSound!,
                textAlign: TextAlign.center,
                style:  TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                widget.author!,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Slider(
              min: 0,
              max: _duration.inSeconds.toDouble(),
              activeColor: Colors.blue,
              inactiveColor: Colors.white,
              value: _position.inSeconds.toDouble(),
              onChanged: (value) async {
                await audioPlayer.seek(Duration(seconds: value.toInt()));
                if (!_isDisposed) {
                  setState(() {});
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _position.format(_position),
                  style:  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                 Text(" / ", style: TextStyle(color: Colors.white)),
                Text(
                  _duration.format(_duration),
                  style:  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  color: Colors.white,
                  onPressed: () async {
                    await audioPlayer.seek(
                      Duration(seconds: _position.inSeconds - 10),
                    );
                    if (!_isDisposed) {
                      setState(() {});
                    }
                  },
                  icon:  SizedBox(child: Icon(Icons.fast_rewind, size: 60)),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: playPause,
                  icon: isPlaying
                      ?  Icon(Icons.pause_circle, size: 60)
                      :  Icon(Icons.play_circle, size: 60),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: () async {
                    await audioPlayer.seek(
                      Duration(seconds: _position.inSeconds + 10),
                    );
                    if (!_isDisposed) {
                      setState(() {});
                    }
                  },
                  icon:  Icon(Icons.fast_forward, size: 60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on Duration {
  String format(Duration duration) {
    String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}