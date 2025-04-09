import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/music/player.dart';
import 'dart:ui';
import 'package:flutter_player/player-provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistPage extends StatefulWidget {
  final Map<String, dynamic> artist;

  const ArtistPage({Key? key, required this.artist}) : super(key: key);

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _filteredTracks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
    _searchController.addListener(_filterTracks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTracks() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('track')
          .select('*')
          .eq('author_id', widget.artist['id'])
          .order('created_at', ascending: false);

      setState(() {
        _tracks = response.cast<Map<String, dynamic>>();
        _filteredTracks = List.from(_tracks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching artist tracks: $e');
    }
  }

  void _filterTracks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTracks = _tracks.where((track) {
        final name = track['name']?.toString().toLowerCase() ?? '';
        final album = track['album']?.toString().toLowerCase() ?? '';
        return name.contains(query) || album.contains(query);
      }).toList();
    });
  }

  void _playTrack(BuildContext context, Map<String, dynamic> track) {
    context.read<PlayerProvider>().playTrack(
      name: track['name'] ?? 'Без названия',
      artist: widget.artist['name'] ?? 'Неизвестный исполнитель',
      url: track['musicurl'] ?? '',
      coverUrl: track['cover_url'] ?? widget.artist['image_url'],
      index: _tracks.indexOf(track),
      trackList: _tracks,
    );
  }

  Widget _buildTrackItem(BuildContext context, Map<String, dynamic> track) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  track['cover_url'] ?? widget.artist['image_url'] ?? '',
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
              ),
              title: Text(
                track['name'] ?? 'Без названия',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                track['album'] ?? 'Без альбома',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () => _playTrack(context, track),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text(
              widget.artist['name'] ?? 'Исполнитель',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              widget.artist['image_url'] ?? '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[800],
                                child: Icon(Icons.person, size: 50, color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.artist['name'] ?? 'Исполнитель',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${_tracks.length} треков',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: Colors.white),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, color: Colors.white70),
                                hintText: 'Поиск треков...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 70),
                        itemCount: _filteredTracks.length,
                        itemBuilder: (context, index) {
                          return _buildTrackItem(context, _filteredTracks[index]);
                        },
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: Footer(),
        ),
      ),
    );
  }
}