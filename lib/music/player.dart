// ignore_for_file: must_be_immutable

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  String? urlMusic;
  String? urlPhoto;
  String? nameSound;
  String? author;
  PlayerPage({
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
  String? _urlMusic;
  String? _urlPhoto;
  String? _nameSound;
  String? _author;
  bool isPlaying = false;
  late final AudioPlayer audioPlayer;
  late final UrlSource urlSource;
  Duration _duration = Duration();
  Duration _position = Duration();

  Future initPlayer() async {
    audioPlayer = AudioPlayer();

    /// Сюда с констуктора необходимо закинуть ссылку
    urlSource = UrlSource(_urlMusic!);

    // Чтобы следить за временем
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    /// Позиция песни
    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
    // Чтобы завершалась
    audioPlayer.onPlayerComplete.listen((comleted) {
      setState(() {
        _position = _duration;
        // isPlaying = !isPlaying;
      });
    });
  }

  // Для проигрывания и паузы
  void playPause() async {
    if (isPlaying) {
      audioPlayer.pause();
      isPlaying = false;
    } else {
      audioPlayer.play(urlSource);
      isPlaying = true;
    }
    setState(() {});
  }

  // Инициализация
  @override
  void initState() {
    _urlPhoto = widget.urlPhoto;
    _urlMusic = widget.urlMusic;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              /// Cюда с констуктора закинуть ссылку на картинку
              child: Image.network(
                _urlPhoto!,
                height: MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
            // Должно браться с бд
            ListTile(
              textColor: Colors.white,
              title: Text(
                _nameSound!,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _author!,
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
                setState(() {});
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _position.format(_position),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(" / ", style: TextStyle(color: Colors.white)),
                Text(
                  _duration.format(_duration),
                  style: TextStyle(
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
                // Назад
                IconButton(
                  color: Colors.white,
                  onPressed: () {
                    audioPlayer.seek(
                      Duration(seconds: _position.inSeconds - 10),
                    );
                    setState(() {});
                  },
                  icon: SizedBox(child: Icon(Icons.fast_rewind, size: 60)),
                ),
                // Проигрывать
                IconButton(
                  color: Colors.white,
                  onPressed: playPause,
                  icon:
                      isPlaying
                          ? Icon(Icons.pause_circle, size: 60)
                          : Icon(Icons.play_circle, size: 60),
                ),
                // Дальше
                IconButton(
                  color: Colors.white,
                  onPressed: () {
                    audioPlayer.seek(
                      Duration(seconds: _position.inSeconds + 10),
                    );
                    setState(() {});
                  },
                  icon: Icon(Icons.fast_forward, size: 60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Форматирование времени при воспроизведении плеера
extension on Duration {
  String format(Duration duration) {
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
