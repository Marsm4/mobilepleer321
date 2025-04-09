import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/HorizontalButtonList.dart';
import 'package:music_player/PlaylistPage.dart';
import 'package:music_player/SectionHeader.dart';
import 'package:music_player/TrackList.dart';
import 'package:music_player/playerProvider';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ProfilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _artists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final [tracks, playlists, artists] = await Future.wait([
        _fetchTracks(),
        _fetchPlaylists(),
        _fetchArtists(),
      ]);

      setState(() {
        _tracks = tracks;
        _playlists = playlists;
        _artists = artists;
      });

      if (tracks.isNotEmpty) {
        final player = Provider.of<PlayerProvider>(context, listen: false);
        player.setTrackList(tracks);
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    final response = await supabase.from('Track').select('*, Author (Name)');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return [];
    
    final response = await supabase
        .from('Playlist')
        .select('*')
        .eq('Id_user', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchArtists() async {
    final response = await supabase.from('Author').select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueGrey],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
        icon: const Icon(Icons.menu),
        color: Colors.white,
        onPressed: () => Scaffold.of(context).openDrawer(),),
          title: const Text('Music App', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            )
          ],
        ),
        body: _isLoading && _tracks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SectionHeader(title: 'Ваши плейлисты'),
                    HorizontalButtonList(
                      itemsFuture: Future.value(_playlists),
                      onPressed: (item) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistPage(playlistId: item['id']),
                        ),
                      ),
                    ),
                    const SectionHeader(title: 'Популярные исполнители'),
                    HorizontalButtonList(
                      itemsFuture: Future.value(_artists),
                      onPressed: (item) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorPage(authorId: item['id']),
                        ),
                      ),
                    ),
                    const SectionHeader(title: 'Треки'),
                    _tracks.isEmpty
                        ? const Center(child: Text('Нет треков'))
                        : TrackList(tracks: _tracks),
                  ],
                ),
              ),
      ),
    );
  }
}