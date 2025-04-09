import 'package:flutter/material.dart';
import 'package:music_player/playerProvider';
import 'package:music_player/track.dart';
import 'package:provider/provider.dart';

class TrackList extends StatelessWidget {
  final List<Map<String, dynamic>> tracks;
  final bool canDelete;
  final Function(int)? onDelete;

  const TrackList({
    super.key,
    required this.tracks,
    this.canDelete = false,
    this.onDelete,
  }) : assert(
          !canDelete || (canDelete && onDelete != null),
          'Если canDelete=true, должен быть предоставлен onDelete callback',
        );

  int _getTrackIndex(Map<String, dynamic> track) {
    return tracks.indexWhere((item) => item['id'] == track['id']);
  }

  void _handleTrackTap(BuildContext context, Map<String, dynamic> track) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    player.setTracks(tracks, index: _getTrackIndex(track));
  }

  void _handleLongPress(BuildContext context, Map<String, dynamic> track) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    player.setTracks(tracks, index: _getTrackIndex(track));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackPage(
          trackList: tracks,
          currentTrackIndex: _getTrackIndex(track),
          startPlaying: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final authorName = track['Author']?['Name'] ?? 'Unknown Artist';
        
        return ListTile(
          title: Text(
            track['Name'] ?? 'Unknown Track',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            authorName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          trailing: canDelete
              ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDelete!(track['id']),
                )
              : null,
          onTap: () => _handleTrackTap(context, track),
          onLongPress: () => _handleLongPress(context, track),
        );
      },
    );
  }
}