import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_scaffold.dart';
import 'package:flutter_application_1/database/storage/playlist_service.dart';
import 'package:flutter_application_1/database/storage/track.dart';
import 'package:flutter_application_1/database/storage/track_list_item.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/music/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_1/database/storage/favorite_service.dart';

class PlaylistTracksPage extends StatefulWidget {
  final int playlistId;
  final String playlistName;


  const PlaylistTracksPage({super.key, required this.playlistId, required this.playlistName,});

  @override
  State<PlaylistTracksPage> createState() => _PlaylistTracksPageState();
}

class _PlaylistTracksPageState extends State<PlaylistTracksPage> {
  final PlaylistService _playlistService = PlaylistService();
  final FavoriteService _favoriteService = FavoriteService();
  List<Track> tracks = [];
  bool isLoading = true;
  final Map<int, String> _authorNames = {};
  String? _currentUserId; 

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadTracks();
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _toggleFavorite(int trackId, bool isCurrentlyFavorite) async {
    if (_currentUserId == null) return;
    
    try {
      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(_currentUserId!, trackId);
      } else {
        await _favoriteService.addFavorite(_currentUserId!, trackId);
      }
      setState(() {});
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> _loadTracks() async {
    try {
      final loadedTracks = await _playlistService.getPlaylistTracks(widget.playlistId);
      await _preloadAuthorNames(loadedTracks);

      setState(() {
        tracks = loadedTracks;
      });
    } catch (e) {
      print('Error loading playlist tracks: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _preloadAuthorNames(List<Track> tracks) async {
    final uniqueAuthorIds = tracks.map((t) => t.authorId).toSet();
    
    for (final authorId in uniqueAuthorIds) {
      if (!_authorNames.containsKey(authorId)) {
        final name = await _getAuthorName(authorId);
        _authorNames[authorId] = name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
    title: "Треки плейлиста" + " " + widget.playlistName,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : tracks.isEmpty
                ? const Center(child: Text('Нет треков в плейлисте'))
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final authorName = _authorNames[track.authorId] ?? 'Unknown Artist';

                      return FutureBuilder(
                        future: _currentUserId != null 
                            ? _favoriteService.isFavorite(_currentUserId!, track.id)
                            : Future.value(false),
                        builder: (ctx, snapshot) {
                          final isFavorite = snapshot.data ?? false;
                          
                          return TrackListItem(
                          track: track,
                          authorName: authorName,
                          isFavorite: isFavorite,
                          onToggleFavorite: _currentUserId != null
                              ? () => _toggleFavorite(track.id, isFavorite)
                              : null,
                          onAddToPlaylist: _currentUserId != null ? () {} : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => PlayerPage(
                                  nameSound: track.name,
                                  author: authorName,
                                  urlMusic: track.musicUrl,
                                  urlPhoto: track.imageUrl,
                                  onBack: () {},
                                ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
  );
}

  Future<String> _getAuthorName(int authorId) async {
    final response = await Supabase.instance.client
        .from('author')
        .select('name')
        .eq('id', authorId)
        .single();
    return response['name'] as String;
  }
}