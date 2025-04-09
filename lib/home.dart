import 'package:flutter/material.dart';
import 'package:flutter_player/artistpage.dart';
import 'package:flutter_player/drawer.dart';
import 'package:flutter_player/musiccollectionpage.dart';
import 'package:flutter_player/music/player.dart';
import 'dart:ui';
import 'package:flutter_player/player-provider.dart';
import 'package:flutter_player/drawer.dart';
import 'package:flutter_player/footer.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _tracks = [];
  List<Map<String, dynamic>> _filteredPlaylists = [];
  List<Map<String, dynamic>> _filteredArtists = [];
  List<Map<String, dynamic>> _filteredTracks = [];
  bool _showAllArtists = false;
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final playlistsResponse = await _supabase
          .from('list')
          .select('*')
          .eq('user_id', currentUser.id);

      final artistsResponse = await _supabase.from('artists').select('*');
      final tracksResponse = await _supabase
          .from('track')
          .select('*, artists!inner(*)');

      setState(() {
        _playlists = playlistsResponse.cast<Map<String, dynamic>>();
        _artists = artistsResponse.cast<Map<String, dynamic>>();
        _tracks = tracksResponse.cast<Map<String, dynamic>>();
        _filteredPlaylists = List.from(_playlists);
        _filteredArtists = List.from(_artists);
        _filteredTracks = List.from(_tracks);
        _isLoading = false;
      });
    } catch (e, st) {
      print('Exception: $e\n$st');
      setState(() {
        _error = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewPlaylist() async {
    final TextEditingController nameController = TextEditingController();
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать плейлист'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Название плейлиста',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Создать'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        await _supabase.from('list').insert({
          'list_name': nameController.text,
          'user_id': currentUser.id,
        });
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Плейлист "${nameController.text}" создан!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при создании плейлиста: $e')),
        );
      }
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredPlaylists = _playlists.where((playlist) {
        final name = playlist['list_name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();

      _filteredArtists = _artists.where((artist) {
        final name = artist['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();

      _filteredTracks = _tracks.where((track) {
        final name = track['name']?.toString().toLowerCase() ?? '';
        final artist = track['artists']['name']?.toString().toLowerCase() ?? '';
        return name.contains(query) || artist.contains(query);
      }).toList();
    });
  }

  void _toggleShowAllArtists() {
    setState(() {
      _showAllArtists = !_showAllArtists;
    });
  }

  void _navigateToArtistPage(Map<String, dynamic> artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistPage(artist: artist),
      ),
    );
  }

  void _navigateToCollectionPage(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicCollectionPage(collection: playlist),
      ),
    );
  }

  void _playTrack(BuildContext context, Map<String, dynamic> track) {
    final artist = track['artists'] as Map<String, dynamic>? ?? {};
    context.read<PlayerProvider>().playTrack(
      name: track['name'] ?? 'Без названия',
      artist: artist['name'] ?? 'Неизвестный исполнитель',
      url: track['musicurl'] ?? '',
      coverUrl: track['cover_url'] ?? artist['image_url'],
      index: _tracks.indexOf(track),
      trackList: _tracks,
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    return GestureDetector(
      onTap: () => _navigateToCollectionPage(playlist),
      child: Container(
        width: 100,
        margin: EdgeInsets.symmetric(horizontal: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 30, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    playlist['list_name'] ?? 'Плейлист',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    return GestureDetector(
      onTap: () => _navigateToArtistPage(artist),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                artist['image_url'] != null
                    ? Image.network(
                        artist['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.person, size: 30, color: Colors.white),
                      )
                    : Center(child: Icon(Icons.person, size: 30, color: Colors.white)),
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 5,
                  child: Text(
                    artist['name'] ?? 'Исполнитель',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, Map<String, dynamic> track) {
    final artist = track['artists'] as Map<String, dynamic>? ?? {};
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
                  track['cover_url'] ?? artist['image_url'] ?? '',
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
                artist['name'] ?? 'Неизвестный исполнитель',
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

  Widget _buildPlaylistsSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Плейлисты",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              if (_filteredPlaylists.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: _createNewPlaylist,
                  tooltip: 'Создать плейлист',
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        _filteredPlaylists.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'У вас пока нет плейлистов',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredPlaylists.length,
                  itemBuilder: (context, index) {
                    return _buildPlaylistCard(_filteredPlaylists[index]);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildArtistsSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Исполнители",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              if (_filteredArtists.length > 6)
                TextButton(
                  onPressed: _toggleShowAllArtists,
                  child: Text(
                    _showAllArtists ? "Свернуть" : "Ещё",
                    style: TextStyle(
                      color: Colors.blue.shade200,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _showAllArtists ? 6 : 6,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: _showAllArtists 
              ? _filteredArtists.length 
              : (_filteredArtists.length > 6 ? 6 : _filteredArtists.length),
          itemBuilder: (context, index) {
            return _buildArtistCard(_filteredArtists[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTracksSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Все треки",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _filteredTracks.length,
          itemBuilder: (context, index) {
            return _buildTrackItem(context, _filteredTracks[index]);
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
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
                      labelText: 'Поиск плейлистов, исполнителей и треков',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          if (_filteredPlaylists.isNotEmpty || _searchController.text.isEmpty) ...[
            _buildPlaylistsSection(),
            SizedBox(height: 30),
          ],
          if (_filteredArtists.isNotEmpty || _searchController.text.isEmpty) ...[
            _buildArtistsSection(),
            SizedBox(height: 30),
          ],
          if (_filteredTracks.isNotEmpty || _searchController.text.isEmpty) ...[
            _buildTracksSection(context),
            SizedBox(height: 30),
          ],
          if (_searchController.text.isNotEmpty && 
              _filteredPlaylists.isEmpty && 
              _filteredArtists.isEmpty &&
              _filteredTracks.isEmpty)
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerPage(),
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
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              "Главная",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _createNewPlaylist,
                tooltip: 'Создать плейлист',
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchData,
              ),
            ],
          ),
          body: _buildContent(context),
          bottomNavigationBar: Footer(),
        ),
      ),
    );
  }
}