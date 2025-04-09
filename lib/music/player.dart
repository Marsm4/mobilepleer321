import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
  String? _urlPhoto;
  String? _nameSound;
  String? _author;
  bool isPlaying = false;
  late final AudioPlayer audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _sliderValue = 0;
  bool _isDragging = false;

  Future initPlayer() async {
    audioPlayer = AudioPlayer();

    // Слушатель длительности трека
    audioPlayer.onDurationChanged.listen((duration) {
      print("Duration: $duration");
      setState(() {
        _duration = duration;
      });
    });

    // Слушатель текущей позиции (согласно вашей версии пакета)
    audioPlayer.onPositionChanged.listen((position) {
      print("Position: $position");
      setState(() {
        _position = position;
        if (!_isDragging) {
          _sliderValue = position.inSeconds.toDouble();
        }
      });
    });

    // Слушатель завершения трека
    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _position = _duration;
        isPlaying = false;
      });
    });
  }

  void playPause() async {
    if (isPlaying) {
      await audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await audioPlayer.play(UrlSource(widget.urlMusic!));
      setState(() {
        isPlaying = true;
      });
    }
  }

  @override
  void initState() {
    _urlPhoto = widget.urlPhoto;
    _author = widget.author;
    _nameSound = widget.nameSound;
    initPlayer();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_urlPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _urlPhoto!,
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ),
            ListTile(
              textColor: Colors.white,
              title: Text(
                _nameSound ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _author ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            // Слайдер
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
              ),
              child: Slider(
                min: 0,
                max: _duration.inSeconds.toDouble(),
                value: _sliderValue.clamp(0, _duration.inSeconds.toDouble()),
                activeColor: Colors.blue,
                inactiveColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _sliderValue = value;
                    _isDragging = true;
                  });
                },
                onChangeEnd: (value) async {
                  await audioPlayer.seek(Duration(seconds: value.toInt()));
                  setState(() {
                    _isDragging = false;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(" / ", style: TextStyle(color: Colors.white)),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
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
                  onPressed: () {
                    int newPos = (_position.inSeconds - 10).clamp(0, _duration.inSeconds);
                    audioPlayer.seek(Duration(seconds: newPos));
                  },
                  icon: const Icon(Icons.fast_rewind, size: 60),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: playPause,
                  icon: isPlaying
                      ? const Icon(Icons.pause_circle, size: 60)
                      : const Icon(Icons.play_circle, size: 60),
                ),
                IconButton(
                  color: Colors.white,
                  onPressed: () {
                    int newPos = (_position.inSeconds + 10).clamp(0, _duration.inSeconds);
                    audioPlayer.seek(Duration(seconds: newPos));
                  },
                  icon: const Icon(Icons.fast_forward, size: 60),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  audioPlayer.stop();
                  setState(() {
                    isPlaying = false;
                    _position = Duration.zero;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
