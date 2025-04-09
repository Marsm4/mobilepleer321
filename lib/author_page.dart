// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/track_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthorPage extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String? authorImage;

  const AuthorPage({
    super.key,
    required this.authorId,
    required this.authorName,
    this.authorImage,
  });

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  final TrackService _trackService = TrackService();
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthorTracks();
  }

  Future<void> _loadAuthorTracks() async {
    try {
      final response = await Supabase.instance.client
          .from('track')
          .select('*, author:author_id(*)')
          .eq('author_id', widget.authorId);

      setState(() {
        _tracks =
            response.map<Track>((track) => Track.fromSupabase(track)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки треков: $e')),
      );
    }
  }

  void _playTrack(Track track, BuildContext context) {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    audioService.loadTrack(track, trackList: _tracks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 21, 101, 192),
              Color.fromARGB(255, 58, 76, 85),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            widget.authorImage ??
                                'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//Default_pfp.jpg',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_tracks.length} ${_tracks.length == 1 ? 'трек' : _tracks.length < 5 ? 'трека' : 'треков'}',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  if (_tracks.isEmpty)
                    SliverToBoxAdapter(
                      child: const Center(
                        child: Text(
                          'Нет треков этого автора',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = _tracks[index];
                          return ListTile(
                            onTap: () => _playTrack(track, context),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                track.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              track.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              track.authorName,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                        childCount: _tracks.length,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
