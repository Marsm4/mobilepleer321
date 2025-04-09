import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/music/player.dart';
import 'package:flutter_player/player-provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MusicCollectionPage extends StatefulWidget {
  final Map<String, dynamic> collection;

  const MusicCollectionPage({Key? key, required this.collection}) : super(key: key);

  @override
  State<MusicCollectionPage> createState() => _MusicCollectionPageState();
}

class _MusicCollectionPageState extends State<MusicCollectionPage> {
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
      // Получаем треки плейлиста с информацией об исполнителях
      final response = await _supabase
          .from('playlist')
          .select('track:track_id(*, artists:author_id(*))')
          .eq('list_id', widget.collection['id'])
          .order('created_at', ascending: false);

      setState(() {
        _tracks = (response as List)
            .map((item) => item['track'] as Map<String, dynamic>)
            .toList();
        _filteredTracks = List.from(_tracks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching collection tracks: $e');
    }
  }

  void _filterTracks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTracks = _tracks.where((track) {
        final name = track['name']?.toString().toLowerCase() ?? '';
        final artist = track['artists']['name']?.toString().toLowerCase() ?? '';
        return name.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  Future<void> _removeTrackFromPlaylist(int trackId) async {
    try {
      await _supabase
          .from('playlist')
          .delete()
          .eq('list_id', widget.collection['id'])
          .eq('track_id', trackId);

      setState(() {
        _tracks.removeWhere((track) => track['id'] == trackId);
        _filteredTracks = List.from(_tracks);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Трек удалён из плейлиста')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении трека: $e')),
      );
    }
  }

  Future<void> _addTrackToPlaylist() async {
    try {
      final response = await _supabase
          .from('track')
          .select('*, artists:author_id(*)')
          .not('id', 'in', _tracks.map((t) => t['id']).toList());

      final availableTracks = (response as List).cast<Map<String, dynamic>>();

      if (availableTracks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Нет доступных треков для добавления')),
        );
        return;
      }

      final selectedTrack = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog( 
          backgroundColor: Colors.blue,
          title: Text('Добавить трек в плейлист',
          style: TextStyle(color: Colors.white),),
          content:Container(
              color: Colors.blue,
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableTracks.length,
                itemBuilder: (context, index) {
                  final track = availableTracks[index];
                  return ListTile(
                   title: Text(track['name'] ?? 'Без названия'),
                    subtitle: Text(track['artists']['name'] ?? 'Неизвестный исполнитель'),
                   onTap: () => Navigator.pop(context, track),
                  );
                },
            ), ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
          ],
        ),
      );

      if (selectedTrack != null) {
        await _supabase.from('playlist').insert({
          'track_id': selectedTrack['id'],
          'list_id': widget.collection['id'],
        });
        _fetchTracks(); // Обновляем список треков
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек добавлен в плейлист!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении трека: $e')),
      );
    }
  }

  void _playTrack(BuildContext context, Map<String, dynamic> track) {
    context.read<PlayerProvider>().playTrack(
      name: track['name'] ?? 'Без названия',
      artist: track['artists']['name'] ?? 'Неизвестный исполнитель',
      url: track['musicurl'] ?? '',
      coverUrl: track['cover_url'] ?? track['artists']['image_url'],
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
                  track['cover_url'] ?? track['artists']['image_url'] ?? '',
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
                track['artists']['name'] ?? 'Неизвестный исполнитель',
                style: TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () => _playTrack(context, track),
              ),
              onTap: () => _playTrack(context, track),
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
              widget.collection['list_name'] ?? 'Плейлист',
              style: TextStyle(color: Colors.white),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _addTrackToPlaylist,
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchTracks,
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    // Collection Header
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[800],
                              child: Icon(Icons.queue_music, size: 50, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.collection['list_name'] ?? 'Плейлист',
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

                    // Search Bar
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
                                hintText: 'Поиск в плейлисте...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tracks List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 70),
                        itemCount: _filteredTracks.length,
                        itemBuilder: (context, index) {
                          final track = _filteredTracks[index];
                          return Dismissible(
                            key: Key(track['id'].toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Удалить трек"),
                                  content: Text("Удалить этот трек из плейлиста?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text("Отмена"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text("Удалить", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) => _removeTrackFromPlaylist(track['id']),
                            child: _buildTrackItem(context, track),
                          );
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