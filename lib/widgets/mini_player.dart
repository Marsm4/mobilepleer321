import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:musik_player/music/player.dart';

class MiniPlayerWidgets extends StatefulWidget {
  final String? urlMusic;
  final String? urlPhoto;
  final String? nameSound;
  final String? author;

  const MiniPlayerWidgets({
    super.key,
    this.urlMusic,
    this.urlPhoto,
    this.nameSound,
    this.author,
  });

  @override
  State<MiniPlayerWidgets> createState() => _MiniPlayerWidgetsState();
}

class _MiniPlayerWidgetsState extends State<MiniPlayerWidgets> {
  bool isPlaying = false;
  AudioPlayer? audioPlayer;
  UrlSource? urlSource;
  Duration _duration = Duration();
  Duration _position = Duration();
  bool _isLoading = true;

  Future<void> initPlayer() async {
    if (widget.urlMusic == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    
    try {
      // Освобождаем предыдущий плеер
      await audioPlayer?.dispose();
      
      audioPlayer = AudioPlayer();
      urlSource = UrlSource(widget.urlMusic!);

      audioPlayer!.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });

      audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      });

      audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) setState(() {
          _position = _duration;
          isPlaying = false;
        });
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> playPause() async {
    if (_isLoading || urlSource == null) return;
    
    try {
      if (isPlaying) {
        await audioPlayer?.pause();
      } else {
        await audioPlayer?.play(urlSource!);
      }
      if (mounted) setState(() => isPlaying = !isPlaying);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка воспроизведения: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  @override
  void didUpdateWidget(covariant MiniPlayerWidgets oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlMusic != widget.urlMusic) {
      initPlayer();
    }
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.nameSound ?? "Нет названия",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.author ?? "Неизвестный исполнитель",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: _isLoading
          ? SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            )
          : widget.urlPhoto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.urlPhoto!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.music_note),
                  ),
                )
              : Icon(Icons.music_note),
      trailing: _isLoading
          ? CircularProgressIndicator()
          : IconButton(
              onPressed: playPause,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
      onTap: () {
        if (widget.urlMusic == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(
              urlMusic: widget.urlMusic,
              urlPhoto: widget.urlPhoto,
              nameSound: widget.nameSound,
              author: widget.author,
            ),
          ),
        );
      },
    );
  }
}