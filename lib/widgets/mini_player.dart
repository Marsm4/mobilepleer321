import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_player/player.dart';

class MiniPlayerWidgets extends StatefulWidget {
  final String? urlMusic;
  final String? urlPhoto;
  final String? nameSound;
  final String? author;
  final bool? isPlaying;
  final Function(bool)? onPlayPause;

  const MiniPlayerWidgets({
    super.key,
    this.urlMusic,
    this.urlPhoto,
    this.nameSound,
    this.author,
    this.isPlaying,
    this.onPlayPause,
  });

  @override
  State<MiniPlayerWidgets> createState() => _MiniPlayerWidgetsState();
}

class _MiniPlayerWidgetsState extends State<MiniPlayerWidgets> {
  late bool _internalPlaying;
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _internalPlaying = widget.isPlaying ?? false;
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (widget.urlMusic == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setSource(UrlSource(widget.urlMusic!));
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playPause() async {
    if (_isLoading || widget.urlMusic == null) return;

    try {
      if (widget.onPlayPause != null) {
        widget.onPlayPause!(!(widget.isPlaying ?? _internalPlaying));
      } else {
        if ((widget.isPlaying ?? _internalPlaying)) {
          await _audioPlayer?.pause();
        } else {
          await _audioPlayer?.resume();
        }
        if (mounted) setState(() => _internalPlaying = !_internalPlaying);
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(covariant MiniPlayerWidgets oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urlMusic != widget.urlMusic) {
      _initAudioPlayer();
    }
    if (oldWidget.isPlaying != widget.isPlaying && widget.isPlaying != null) {
      _internalPlaying = widget.isPlaying!;
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.isPlaying ?? _internalPlaying;

    return ListTile(
      title: Text(
        widget.nameSound ?? "Без названия",
        style: const TextStyle(color: Colors.white),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        widget.author ?? "Неизвестный исполнитель",
        style: const TextStyle(color: Colors.white70),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      leading: _isLoading
          ? const SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            )
          : widget.urlPhoto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.urlPhoto!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Icon(Icons.music_note, color: Colors.white),
      trailing: _isLoading
          ? const CircularProgressIndicator()
          : IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: _playPause,
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
              initialPlaying: isPlaying,
            ),
          ),
        );
      },
    );
  }
}
