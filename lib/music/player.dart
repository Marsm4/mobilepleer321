import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_player/player-provider.dart';
import 'package:provider/provider.dart';

class PlayerPage extends StatefulWidget {
  final String? nameSound;
  final String? author;
  final String? urlMusic;
  final String? urlPhoto;

  const PlayerPage({
    super.key,
    this.nameSound,
    this.author,
    this.urlMusic,
    this.urlPhoto,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final isPlaying = playerProvider.isPlaying;
    final duration = playerProvider.duration;
    final position = playerProvider.position;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 2,
            colors: [
              Color(0xFF151515),
              Colors.blue,
              Colors.cyan,
            ],
            stops: [0.5, 0.6, 0.8],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                widget.urlPhoto ?? '',
                                height: 250,
                                width: 250,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 250,
                                  width: 250,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.music_note, 
                                      size: 60, color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              widget.nameSound ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              widget.author ?? '',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Slider(
                              min: 0,
                              max: duration.inSeconds.toDouble(),
                              activeColor: Colors.cyan,
                              inactiveColor: Colors.white70,
                              value: position.inSeconds
                                  .clamp(0, duration.inSeconds)
                                  .toDouble(),
                              onChanged: (value) async {
                                await playerProvider.seek(
                                    Duration(seconds: value.toInt()));
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  position.format(),
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  duration.format(),
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {}, // TODO: реализовать перемотку назад
                        style: OutlinedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.fast_rewind, 
                            size: 30, color: Colors.white),
                      ),
                      SizedBox(width: 20),
                      OutlinedButton(
                        onPressed: () => playerProvider.togglePlayPause(),
                        style: OutlinedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(20),
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 20),
                      OutlinedButton(
                        onPressed: () {}, // TODO: реализовать перемотку вперед
                        style: OutlinedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                          side: BorderSide(color: Colors.white, width: 2),
                        ),
                        child: Icon(Icons.fast_forward, 
                            size: 30, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension FormatDuration on Duration {
  String format() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}