import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/playerProvider';
import 'package:music_player/track.dart'; 
import 'package:provider/provider.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _openTrackPage(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    if (player.tracksList.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackPage(
          trackList: player.tracksList,
          currentTrackIndex: player.currentTrackIndex,
          startPlaying: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final currentTrack = player.currentTrack;

    return Visibility(
      visible: player.isPlayerVisible,
      child: GestureDetector(
        onTap: () => _openTrackPage(context),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: Theme.of(context).bottomAppBarTheme.color,
            border: Border(top: BorderSide(color: Colors.grey.shade800)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openTrackPage(context),
                          child: Text(
                            currentTrack['Name'] ?? 'Загрузка..',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (currentTrack['Id_Author'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuthorPage(
                                    authorId: currentTrack['Id_Author'],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            currentTrack['Author']?['Name'] ?? 'Загрузка..',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 28,
                        onPressed: player.previousTrack,
                      ),
                      IconButton(
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 32,
                        ),
                        onPressed: player.playPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 28,
                        onPressed: player.nextTrack,
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Slider( 
                    min: 0,
                    max: player.duration.inSeconds.toDouble(),
                    value: player.position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      await player.seek(Duration(seconds: value.toInt()));
                    },
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.white,
                    thumbColor: Colors.blue,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(player.position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          _formatDuration(player.duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}