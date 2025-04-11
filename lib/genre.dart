import 'package:flutter/material.dart';
import 'package:flutter_player/audioplayer.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenrePage extends StatefulWidget {
  final Map<String, dynamic> genre;

  const GenrePage({Key? key, required this.genre}) : super(key: key);

  @override
  State<GenrePage> createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayerService _audioService = AudioPlayerService();
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final response = await _supabase
          .from('track')
          .select('*, author:author(name, image)')
          .eq('genre_id', widget.genre['id']);

      if (mounted) {
        setState(() {
          _tracks = (response as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tracks: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0008FF), Color(0xFF010345)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.genre['name'] ?? 'Жанр',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.genre['image'] != null)
                                  Container(
                                    height: 250,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(widget.genre['image']),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.5),
                                          BlendMode.darken,
                                        ),
                                      ),
                                    ),
                                ),
                            
                                const SizedBox(height: 16),

                                Text(
                                  'Треки жанра',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ]
                                  ),
                            ),
                          ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = _tracks[index];
                              return _buildTrackTile(track);
                            },
                            childCount: _tracks.length,
                          ),
                        ),
                      ],
                    ),
            ),
            GlobalFooter(audioService: _audioService),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(Map<String, dynamic> track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: track['image'] != null
                ? Image.network(
                    track['image'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.blueGrey[800],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
          ),
          title: Text(
            track['name'] ?? 'Без названия',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            track['author']?['name'] ?? 'Неизвестный исполнитель',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () {
              _audioService.playTrack(track, tracks: _tracks, context: context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackPage(
                    track: track,
                    playlistTracks: _tracks,
                    initialPosition: Duration.zero,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}