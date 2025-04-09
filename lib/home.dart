// ignore_for_file: unused_field, unused_element, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player/author_page.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/medialibrary.dart';
import 'package:music_player/music/player.dart';
import 'package:music_player/profile.dart';
import 'package:music_player/playlist.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/favorite_service.dart';
import 'package:music_player/services/track_service.dart';
import 'package:music_player/widgets/side_menu.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Track? _currentTrack;
  final TrackService _trackService = TrackService();
  List<Track> _tracks = [];
  bool _isLoading = true;
  Widget? _currentPlaylistPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTracks();
  }

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final tracks = await _trackService.getAllTracks();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading tracks: $e');
    }
  }

  void _openPlaylist(Map<String, dynamic> playlist) {
    setState(() {
      _currentPlaylistPage = PlaylistPage(
        playlistId: playlist['id'].toString(),
        playlistName: playlist['name'] ?? 'Без названия',
        playlistImage: playlist['image'],
        onBack: () => _closePlaylist,
      );
    });
  }

  void _closePlaylist() {
    setState(() => _currentPlaylistPage = null);
  }

  static List<Widget> _widgetOptions(BuildContext context, List<Track> tracks) {
    return [
      HomeContent(tracks: tracks),
      const MediaLibraryPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    if (index == 0) {
      await _loadTracks();
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioPlayerService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SideMenu(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _widgetOptions(context, _tracks)[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioService.currentTrack != null)
            _buildNowPlayingBar(context, audioService),
          BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Моя медиатека',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person,
                ),
                label: 'Профиль',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            onTap: _onItemTapped,
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingBar(
      BuildContext context, AudioPlayerService audioService) {
    final track = audioService.currentTrack!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PlayerPage(
              trackList: audioService.trackList,
              initialTrackIndex: audioService.currentTrackIndex,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(100, 0, 0, 0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 44, 44, 44),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      track.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        track.authorName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      StreamBuilder<Duration>(
                        stream: audioService.audioPlayer.onPositionChanged,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = audioService.duration;
                          final progress = duration.inSeconds > 0
                              ? position.inSeconds / duration.inSeconds
                              : 0.0;

                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[800],
                            color: Colors.white,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: () async {
                    await audioService
                        .seek(Duration.zero); // Сбрасываем позицию
                    audioService.playPreviousTrack();
                  },
                ),
                IconButton(
                  icon: Icon(
                    audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: audioService.togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: () async {
                    await audioService
                        .seek(Duration.zero); // Сбрасываем позицию
                    audioService.playNextTrack();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class HomeContent extends StatefulWidget {
  final List<Track> tracks;
  final Function(Map<String, dynamic>)? onPlaylistTap;

  const HomeContent({
    super.key,
    required this.tracks,
    this.onPlaylistTap,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _popularAuthors = [];
  bool _isAuthorsLoading = true;

  Future<void> _loadPopularAuthors() async {
    try {
      final response = await Supabase.instance.client
          .from('author')
          .select('*, track:track(count)')
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _popularAuthors = List<Map<String, dynamic>>.from(response);
        _isAuthorsLoading = false;
      });
    } catch (e) {
      setState(() => _isAuthorsLoading = false);
      print('Error loading authors: $e');
    }
  }

  Future<void> _deleteTrack(Track track, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить трек?'),
        content: Text('Вы уверены, что хотите удалить "${track.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Вызов сервиса для удаления трека
        await TrackService().deleteTrack(track.id);

        // Обновляем состояние, удаляя трек из списка
        if (mounted) {
          setState(() {
            widget.tracks.removeWhere((t) => t.id == track.id);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "${track.name}" удален')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении: $e')),
        );
      }
    }
  }

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FavoriteService _favoriteService = FavoriteService();
  String _searchQuery = '';
  List<String> _favoriteIds = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFavorites();
    _loadPopularAuthors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getUserFavorites();
      setState(() {
        _favoriteIds = favorites;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(Track track) async {
    try {
      if (track.isFavorite) {
        await _favoriteService.removeFavorite(track.id);
      } else {
        await _favoriteService.addFavorite(track.id);
      }
      setState(() {
        track.isFavorite = !track.isFavorite;
        if (track.isFavorite) {
          _favoriteIds.add(track.id);
        } else {
          _favoriteIds.remove(track.id);
        }
      });
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Track> get _filteredTracks {
    if (_searchQuery.isEmpty) {
      return widget.tracks;
    }
    return widget.tracks.where((track) {
      return track.name.toLowerCase().contains(_searchQuery) ||
          track.authorName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _playTrack(Track track, BuildContext context) {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    audioService.loadTrack(track, trackList: widget.tracks);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                    style:
                        const TextStyle(color: Color.fromARGB(255, 45, 45, 45)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 8.0),
            child: const Text(
              'Популярные авторы',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _isAuthorsLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  itemCount: _popularAuthors.length,
                  itemBuilder: (context, index) {
                    final author = _popularAuthors[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuthorPage(
                              authorId: author['id'].toString(),
                              authorName:
                                  author['name'] ?? 'Неизвестный исполнитель',
                              authorImage: author['image'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    author['image'] ??
                                        'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//Default_pfp.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              author['name'] ?? 'Неизвестный',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
              const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _searchQuery.isEmpty ? 'Популярные треки' : 'Похожее',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: _filteredTracks.isEmpty && _searchQuery.isNotEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredTracks.length,
                    itemBuilder: (context, index) {
                      final track = _filteredTracks[index];
                      track.isFavorite = _favoriteIds.contains(track.id);
                      final isCurrentUserTrack =
                          track.authorId == currentUserId;

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
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        title: Text(track.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(track.authorName,
                            style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                track.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: track.isFavorite
                                    ? Colors.red
                                    : Colors.white,
                              ),
                              onPressed: () => _toggleFavorite(track),
                            ),
                            if (isCurrentUserTrack) // Показываем кнопку удаления только для своих треков
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                onPressed: () => _deleteTrack(track, context),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
