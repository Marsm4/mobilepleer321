import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:music_player/player_state.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerState>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Обложка трека
          Container(
            margin: EdgeInsets.symmetric(vertical: 20),
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: playerState.currentTrackImage != null
                  ? Image.network(
                      playerState.currentTrackImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.blueGrey[800],
                      child: Center(
                        child: Icon(
                          Icons.music_note,
                          color: Colors.blueGrey[300],
                          size: 80,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 40),
          // Название и исполнитель
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  playerState.currentTrackName ?? 'Название трека',
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
                  playerState.currentTrackAuthor ?? 'Исполнитель',
                  style: TextStyle(
                    color: Colors.blueGrey[300],
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          // Прогресс бар
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: StreamBuilder<Duration>(
              stream: playerState.audioPlayer.onPositionChanged,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: playerState.audioPlayer.onDurationChanged,
                  builder: (context, snapshot) {
                    final duration = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          value: position.inMilliseconds.toDouble(),
                          min: 0,
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            playerState.audioPlayer.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                          activeColor: Colors.blueGrey[300],
                          inactiveColor: Colors.blueGrey[600],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.blueGrey[300]),
                              ),
                              Text(
                                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.blueGrey[300]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 30),
          // Управление воспроизведением
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (playerState.playlist.isNotEmpty) {
                    playerState.playPrevious();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Нет предыдущего трека'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(width: 30),
              IconButton(
                onPressed: () {
                  if (playerState.currentTrackUrl != null) {
                    if (playerState.isPlaying) {
                      playerState.pause();
                    } else {
                      playerState.resume();
                    }
                  }
                },
                icon: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueGrey[700],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Icon(
                    playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              SizedBox(width: 30),
              IconButton(
                onPressed: () {
                  if (playerState.playlist.isNotEmpty) {
                    playerState.playNext();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Нет следующего трека'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          // Кнопка повтора
          SizedBox(height: 20),
          IconButton(
            icon: Icon(
              playerState.isLooping ? Icons.repeat_one : Icons.repeat,
              color: playerState.isLooping ? Colors.blueGrey[300] : Colors.blueGrey[500],
              size: 30,
            ),
            onPressed: () {
              playerState.toggleLoop();
            },
          ),
        ],
      ),
    );
  }
}