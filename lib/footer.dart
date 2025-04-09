import 'package:flutter/material.dart';
import 'package:flutter_player/music/player.dart';
import 'package:flutter_player/player-provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final currentTrack = playerProvider.currentTrackName;
    final currentArtist = playerProvider.currentArtist;
    final currentCoverUrl = playerProvider.currentCoverUrl;
    final isPlaying = playerProvider.isPlaying;
    final duration = playerProvider.duration;
    final position = playerProvider.position;
    final trackList = playerProvider.trackList;
    final currentIndex = playerProvider.currentTrackIndex;
    final isFavorite = playerProvider.isCurrentTrackFavorite;
    final isFavoriteLoading = playerProvider.isFavoriteLoading;

    return GestureDetector(
      onTap: () {
        if (currentTrack != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerPage(
                nameSound: currentTrack,
                author: currentArtist,
                urlMusic: playerProvider.currentTrackUrl,
                urlPhoto: currentCoverUrl,
              ),
            ),
          );
        }
      },
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border(
                top: BorderSide(
                  color: Colors.blue.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: duration.inSeconds > 0 
                        ? position.inSeconds / duration.inSeconds 
                        : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    if (currentCoverUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentCoverUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: Icon(Icons.music_note, color: Colors.white),
                      ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrack ?? 'Не играет',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentArtist ?? '',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildFavoriteButton(context, isFavorite, isFavoriteLoading),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: Colors.white),
                          onPressed: () {
                            if (trackList.isNotEmpty && currentIndex != null && currentIndex! > 0) {
                              playerProvider.playPrevious();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => playerProvider.togglePlayPause(),
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: Colors.white),
                          onPressed: () {
                            if (trackList.isNotEmpty && currentIndex != null && currentIndex! < trackList.length - 1) {
                              playerProvider.playNext();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, bool isFavorite, bool isLoading) {
    return isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () => context.read<PlayerProvider>().toggleFavorite(),
          );
  }
}