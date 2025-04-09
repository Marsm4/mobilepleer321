import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_scaffold.dart';
import 'package:flutter_application_1/database/storage/favorite_service.dart';
import 'package:flutter_application_1/database/storage/track.dart';
import 'package:flutter_application_1/database/storage/track_list_item.dart';
import 'package:flutter_application_1/database/storage/track_service.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/music/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteTracksPage extends StatefulWidget {
  const FavoriteTracksPage({super.key});

  @override
  State<FavoriteTracksPage> createState() => _FavoriteTracksPageState();
}

class _FavoriteTracksPageState extends State<FavoriteTracksPage> {
  final FavoriteService _favoriteService = FavoriteService();
  final TrackService _trackService = TrackService();
  final Map<int, String> _authorNames = {};
  List<Track> tracks = [];
  bool isLoading = true;
  String? userId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.id;
      });
      _loadTracks();
    }
  }

  Future<void> _loadTracks() async {
    try {
      final loadedTracks = await _favoriteService.getFavoriteTracks(userId!);
      await _preloadAuthorNames(loadedTracks);
      setState(() {
        tracks = loadedTracks;
      });
    } catch (e) {
      print('Error loading favorite tracks: $e');
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
        final name = await _trackService.getAuthorName(authorId);
        _authorNames[authorId] = name;
      }
    }
  }

  Future<void> _removeFavorite(int trackId) async {
    try {
      await _favoriteService.removeFavorite(userId!, trackId);
      setState(() {
        tracks.removeWhere((track) => track.id == trackId);
      });
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
    title: 'Избранное',
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : tracks.isEmpty
                ? const Center(child: Text('Нет избранных треков'))
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final authorName = _authorNames[track.authorId] ?? 'Unknown Artist';

                      return TrackListItem(
                      track: track,
                      authorName: authorName,
                      isFavorite: true,
                      onToggleFavorite: () => _removeFavorite(track.id),
                      onAddToPlaylist: _currentUserId != null ? () {} : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
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
              ),
  );
}}