import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app_scaffold.dart';
import 'package:flutter_application_1/database/auth.dart';
import 'package:flutter_application_1/database/storage/favorite_service.dart';
import 'package:flutter_application_1/database/storage/track.dart';
import 'package:flutter_application_1/database/storage/track_list_item.dart';
import 'package:flutter_application_1/database/storage/track_service.dart';
import 'package:flutter_application_1/drawer.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/music/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthService authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;
  final TrackService trackService = TrackService();
  final FavoriteService _favoriteService = FavoriteService();
  List<Track> tracks = [];
  List<Track> filteredTracks = [];
  Track? selectedTrack;
  Track? currentTrack;
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  List<Map<String, dynamic>> authors = [];
  int? selectedAuthorId;
  String? _currentUserId;

  Future<void> _fetchTracks() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final loadedTracks = await trackService.getTracks();

      setState(() {
        tracks = loadedTracks;
        filteredTracks = List.from(loadedTracks);
        if (tracks.isNotEmpty) {
          currentTrack = tracks[0];
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = "Ошибка загрузки треков: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTracks();
    _fetchAuthors();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _fetchAuthors() async {
    try {
      final response = await supabase
          .from('author')
          .select('id, name, image_url');

      setState(() {
        authors = response;
      });
    } catch (e) {
      print('Ошибка загрузки исполнителей: $e');
    }
  }

  void _filterByAuthor(int? authorId) {
    setState(() {
      selectedAuthorId = authorId;
      if (authorId == null) {
        filteredTracks = List.from(tracks);
      } else {
        filteredTracks =
            tracks.where((track) => track.authorId == authorId).toList();
      }
    });
  }

  Widget _buildAuthorsList() {
    if (authors.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Исполнители',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (selectedAuthorId != null)
              TextButton(
                onPressed: () => _filterByAuthor(null),
                child: Text(
                  'Сбросить',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: authors.length,
            itemBuilder: (ctx, index) {
              final author = authors[index];
              return GestureDetector(
                onTap: () => _filterByAuthor(author['id']),
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              selectedAuthorId == author['id']
                                  ? Colors.blue
                                  : Colors.grey[300],
                          image:
                              author['image_url'] != null
                                  ? DecorationImage(
                                    image: NetworkImage(author['image_url']),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            author['image_url'] == null
                                ? Icon(Icons.person, size: 40)
                                : null,
                      ),
                      SizedBox(height: 5),
                      Text(
                        author['name'],
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              selectedAuthorId == author['id']
                                  ? Colors.white
                                  : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  void _filterTracks(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredTracks =
            selectedAuthorId == null
                ? List.from(tracks)
                : tracks.where((t) => t.authorId == selectedAuthorId).toList();
      } else {
        filteredTracks =
            tracks.where((track) {
              final matchesSearch = track.name.toLowerCase().contains(
                query.toLowerCase(),
              );
              final matchesAuthor =
                  selectedAuthorId == null ||
                  track.authorId == selectedAuthorId;
              return matchesSearch && matchesAuthor;
            }).toList();
      }
    });
  }

  void resetSelectedTrack() {
    setState(() {
      selectedTrack = null;
    });
  }

  Future<void> _playTrack(Track track) async {
    final authorName = await _getAuthorName(track.authorId);

    if (mounted) {
      setState(() {
        currentTrack = track;
      });

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder:
              (_) => PlayerPage(
                nameSound: track.name,
                author: authorName,
                urlMusic: track.musicUrl,
                urlPhoto: track.imageUrl,
                onBack: resetSelectedTrack,
                playlist: filteredTracks,
                currentTrackIndex: filteredTracks.indexWhere(
                  (t) => t.id == track.id,
                ),
              ),
        ),
      );
    }
  }

  Future<String> _getAuthorName(int authorId) async {
    final response =
        await supabase
            .from('author')
            .select('name')
            .eq('id', authorId)
            .single();

    return response['name'] as String;
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Home",
      isHomePage: true,
      drawer: DrawerPage(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: _filterTracks,
                ),
              ),
              _buildAuthorsList(),
              Text(
                'Треки',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildTracksList(),
            ],
          ),
        ),
      ),
      floatingPlayer:
          selectedTrack != null
              ? GestureDetector(
                onTap: () => _playTrack(selectedTrack!),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading:
                        selectedTrack!.imageUrl.isNotEmpty
                            ? Image.network(
                              selectedTrack!.imageUrl,
                              width: 40,
                              height: 40,
                            )
                            : Icon(Icons.music_note, color: Colors.white),
                    title: Text(
                      selectedTrack!.name,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: FutureBuilder(
                      future: _getAuthorName(selectedTrack!.authorId),
                      builder:
                          (ctx, snapshot) => Text(
                            snapshot.data ?? 'Unknown Artist',
                            style: TextStyle(color: Colors.white70),
                          ),
                    ),
                    trailing: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildTracksList() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage != null) return Center(child: Text(errorMessage!));

    if (searchQuery.isNotEmpty && filteredTracks.isEmpty) {
      return Center(
        child: Text(
          'Ничего не найдено по запросу "$searchQuery"',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTracks.length,
      itemBuilder: (ctx, index) {
        final track = filteredTracks[index];
        return FutureBuilder<String>(
          future: _getAuthorName(track.authorId),
          builder: (ctx, authorSnapshot) {
            if (authorSnapshot.connectionState != ConnectionState.done) {
              return ListTile(
                title: Text(track.name),
                subtitle: Text("Загрузка..."),
              );
            }
            final authorName = authorSnapshot.data ?? 'Unknown Artist';
            return FutureBuilder<bool>(
              future:
                  _currentUserId != null
                      ? _favoriteService.isFavorite(_currentUserId!, track.id)
                      : Future.value(false),
              builder: (ctx, favoriteSnapshot) {
                final isFavorite = favoriteSnapshot.data ?? false;
                return TrackListItem(
                  track: track,
                  authorName: authorName,
                  isFavorite: isFavorite,
                  onToggleFavorite:
                      _currentUserId != null
                          ? () => _toggleFavorite(track.id, isFavorite)
                          : null,
                  onAddToPlaylist: _currentUserId != null ? () {} : null,
                  onTap: () => setState(() => selectedTrack = track),
                );
              },
            );
          },
        );
      },
    );
  }
}
