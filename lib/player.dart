import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  final String? urlMusic;
  final String? urlPhoto;
  final String? nameSound;
  final String? author;
  final bool initialPlaying;

  const PlayerPage({
    super.key,
    required this.urlMusic,
    this.urlPhoto,
    this.nameSound,
    this.author,
    this.initialPlaying = false,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.initialPlaying;
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });

      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });

      if (_isPlaying && widget.urlMusic != null) {
        await _audioPlayer.play(UrlSource(widget.urlMusic!));
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else if (widget.urlMusic != null) {
        await _audioPlayer.play(UrlSource(widget.urlMusic!));
      }
      if (mounted) setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
        "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Кнопка назад
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Основное содержимое
            Center(
              child: _hasError
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Color(0xFFE53935),
                          size: 50,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Ошибка загрузки",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    )
                  : _isLoading
                      ? CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Обложка трека
                            Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.width * 0.7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: widget.urlPhoto != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        widget.urlPhoto!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(
                                            Icons.music_note,
                                            size: 80,
                                            color:
                                                Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.music_note,
                                        size: 80,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                            ),
                            SizedBox(height: 32),

                            // Название и исполнитель
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  Text(
                                    widget.nameSound ?? "Без названия",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.author ?? "Неизвестный исполнитель",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 32),

                            // Прогресс бар
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Color(0xFF1DB954),
                                      inactiveTrackColor:
                                          Colors.white.withOpacity(0.2),
                                      thumbColor: Colors.white,
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 16,
                                      ),
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: _duration.inSeconds.toDouble(),
                                      value: _position.inSeconds
                                          .clamp(
                                              0, _duration.inSeconds.toDouble())
                                          .toDouble(),
                                      onChanged: (v) =>
                                          _seek(Duration(seconds: v.toInt())),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Элементы управления
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.skip_previous, size: 32),
                                  color: Colors.white,
                                  onPressed: () {},
                                ),
                                SizedBox(width: 24),
                                IconButton(
                                  icon: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1DB954),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(16),
                                    child: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: _playPause,
                                ),
                                SizedBox(width: 24),
                                IconButton(
                                  icon: Icon(Icons.skip_next, size: 32),
                                  color: Colors.white,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
