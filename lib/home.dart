import 'package:flutter/material.dart';
import 'package:flutter_player/artist.dart';
import 'package:flutter_player/audioplayer.dart';
import 'package:flutter_player/auth.dart';
import 'package:flutter_player/favorites.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/genre.dart';
import 'package:flutter_player/playlist.dart';
import 'package:flutter_player/profile.dart';
import 'package:flutter_player/track.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayerService _audioService = AudioPlayerService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<ScrollController> _scrollControllers;
  late List<bool> _showArrows;

  List<Map<String, dynamic>> _filteredTracks = [];
  List<Map<String, dynamic>> _filteredArtists = [];
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _tracks = [];

  User? _user;
  bool _isLoading = true;
  bool _isSearching = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    _audioService.playlistsNotifier.addListener(_refreshPlaylists);
  }

  Future<void> _initialize() async {
    _scrollControllers = List.generate(4, (_) => ScrollController());
    _showArrows = List.filled(4, false);

    try {
      _user = _supabase.auth.currentUser;
      if (_user != null) {
        await _fetchData();
      } else {
        await _checkAuthState();
      }
      _setupListeners();
    } catch (e) {
      _handleError('Ошибка инициализации: $e');
    }
  }

  void _updateCurrentTrack() {
    if (mounted) setState(() {});
  }

  void _updateFavorites() {
    if (mounted) setState(() {});
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _setupListeners() {
    _audioService.playlistsNotifier.addListener(_refreshPlaylists);
    _audioService.currentTrack.addListener(_updateCurrentTrack);
    _audioService.isFavorite.addListener(_updateFavorites);

    for (var controller in _scrollControllers) {
      controller.addListener(_checkScrollVisibility);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioService.playlistsNotifier.removeListener(_refreshPlaylists);
    _audioService.currentTrack.removeListener(_updateCurrentTrack);
    _audioService.isFavorite.removeListener(_updateFavorites);

    for (var controller in _scrollControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _refreshPlaylists() async {
    if (mounted) {
      setState(() => _isLoading = true);
      await _loadUserPlaylists();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final session = await _supabase.auth.currentSession;
      if (session != null && mounted) {
        setState(() => _user = session.user);
        await _fetchData();
      } else if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка проверки авторизации: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Пользователь не авторизован');

      await _loadUserPlaylists();

      final responses = await Future.wait([
        _supabase.from('track').select('*, author:author_id(name, image)'),
        _supabase.from('author').select('*'),
        _supabase.from('genre').select('*'),
      ]);

      setState(() {
        _tracks =
            (responses[0] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        _artists =
            (responses[1] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        _genres =
            (responses[2] as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      _handleError(
        'Ошибка загрузки данных: ${e is PostgrestException ? e.message : e}',
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserPlaylists() async {
    try {
      setState(() => _isLoading = true);
      await _audioService.loadUserPlaylists();
      if (mounted) {
        setState(() {
          _playlists = _audioService.playlistsNotifier.value;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки плейлистов: ${e.toString()}';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки плейлистов: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _checkScrollVisibility() {
    if (mounted) {
      setState(() {
        for (int i = 0; i < _scrollControllers.length; i++) {
          if (_scrollControllers[i].hasClients) {
            final pos = _scrollControllers[i].position;
            _showArrows[i] =
                pos.hasContentDimensions &&
                pos.maxScrollExtent > 0 &&
                pos.pixels < pos.maxScrollExtent;
          }
        }
      });
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredTracks = [];
        _filteredArtists = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final lowerQuery = query.toLowerCase();

    setState(() {
      _filteredTracks =
          _tracks.where((track) {
            final trackName = track['name']?.toString().toLowerCase() ?? '';
            final artistName =
                track['author']?['name']?.toString().toLowerCase() ?? '';
            return trackName.contains(lowerQuery) ||
                artistName.contains(lowerQuery);
          }).toList();

      _filteredArtists =
          _artists.where((artist) {
            final artistName = artist['name']?.toString().toLowerCase() ?? '';
            return artistName.contains(lowerQuery);
          }).toList();

      _isSearching = false;
    });
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_filteredTracks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Text(
              'Треки:',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 240, // Увеличенная высота
            child: ListView.separated(
              // Добавлен разделитель
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filteredTracks.length,
              separatorBuilder:
                  (context, index) =>
                      const SizedBox(width: 16), // Отступ между элементами
              itemBuilder: (context, index) {
                final track = _filteredTracks[index];
                return SizedBox(
                  width: 200, // Ширина карточки
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              track['image'] != null
                                  ? Image.network(
                                    track['image']!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.music_note,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12), // Увеличенный отступ
                      Text(
                        track['name']?.toString() ?? 'Без названия',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(
                        height: 4,
                      ), // Отступ между названием и исполнителем
                      Text(
                        track['author']?['name']?.toString() ??
                            'Неизвестный исполнитель',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30), // Больший отступ между секциями
        ],
        if (_filteredArtists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Text(
              'Исполнители:',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 240, // Увеличенная высота
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _filteredArtists.length,
              separatorBuilder:
                  (context, index) =>
                      const SizedBox(width: 16), // Отступ между элементами
              itemBuilder: (context, index) {
                final artist = _filteredArtists[index];
                return SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Круглые изображения для артистов
                          child:
                              artist['image'] != null
                                  ? Image.network(
                                    artist['image']!,
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                  : Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16), // Увеличенный отступ
                      Text(
                        artist['name']?.toString() ?? 'Неизвестный исполнитель',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        if (!_isSearching &&
            _searchController.text.isNotEmpty &&
            _filteredTracks.isEmpty &&
            _filteredArtists.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Ничего не найдено',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> data,
    required Widget Function() seeAllBuilder,
    int index = 0,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    if (data.isEmpty) return const SizedBox();
    final showArrow = index != -1 && _showArrows[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => seeAllBuilder()),
                    ),
                child: const Text(
                  'Все',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollControllers[index],
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.length,
                itemBuilder:
                    (context, i) => Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      child: itemBuilder(data[i]),
                    ),
              ),
              if (showArrow)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color.fromARGB(150, 3, 0, 58),
                          ],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed:
                            () => _scrollControllers[index].animateTo(
                              _scrollControllers[index].offset + 200,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCard({
    String? imageUrl,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    double width = 180, // Default width with new parameter
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, // Use the width parameter
        margin: const EdgeInsets.only(right: 18), // Increased margin
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Increased radius
                  color: Colors.blueGrey[800],
                  image:
                      imageUrl != null
                          ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    imageUrl == null
                        ? Center(
                          child: Icon(
                            icon,
                            size: 52,
                            color: Colors.white,
                          ), // Increased icon size
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 15), // Increased spacing
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18, // Increased font size
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6), // Increased spacing
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14, // Increased font size
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF010345),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0008FF), Color(0xFF010345)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child:
                      _user?.email != null
                          ? Text(
                            _user!.email!.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.blue,
                            ),
                          )
                          : const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  _user?.email ?? 'Гость',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Главная', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Профиль', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.white),
            title: const Text(
              'Избранное',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              );
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.playlist_play, color: Colors.white),
          //   title: const Text(
          //     'Мои плейлисты',
          //     style: TextStyle(color: Colors.white),
          //   ),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => PlaylistPage(playlist: {})),
          //     );
          //   },
          // ),
          const Divider(color: Colors.white54),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Выйти', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_error)));
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0008FF), Color(0xFF010345)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Главная",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          24,
                        ), // Increased padding
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0x19FFFFFF),
                            hintText: 'Поиск треков, исполнителей...',
                            hintStyle: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16, // Increased font size
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 24,
                            ), // Increased icon size
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                        size: 24,
                                      ), // Increased icon size
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch('');
                                      },
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                12,
                              ), // Increased radius
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, // Increased padding
                              horizontal: 16,
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16, // Increased font size
                          ),
                          onChanged: _performSearch,
                        ),
                      ),
                      _buildSearchResults(),
                      if (_searchController.text.isEmpty) ...[
                        _buildSection(
                          title: "Плейлисты",
                          data: _playlists,
                          seeAllBuilder: _buildAllPlaylistsPage,
                          index: 0,
                          itemBuilder:
                              (p) => _buildCard(
                                imageUrl: p['image'],
                                icon: Icons.queue_music,
                                title: p['list_name'] ?? 'Без названия',
                                subtitle: '${p['tracks_count'] ?? 0} треков',
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => PlaylistPage(playlist: p),
                                      ),
                                    ),
                              ),
                        ),
                        _buildSection(
                          title: "Жанры",
                          data: _genres,
                          seeAllBuilder: _buildAllGenresPage,
                          index: 1,
                          itemBuilder:
                              (g) => _buildCard(
                                imageUrl: g['image'],
                                icon: Icons.category,
                                title: g['name'] ?? 'Без названия',
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GenrePage(genre: g),
                                      ),
                                    ),
                              ),
                        ),
                        _buildSection(
                          title: "Исполнители",
                          data: _artists,
                          seeAllBuilder: _buildAllArtistsPage,
                          index: 2,
                          itemBuilder:
                              (a) => _buildCard(
                                imageUrl: a['image'],
                                icon: Icons.person,
                                title: a['name'] ?? 'Неизвестный исполнитель',
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ArtistPage(artist: a),
                                      ),
                                    ),
                              ),
                        ),
                        _buildSection(
                          title: "Треки",
                          data: _tracks,
                          seeAllBuilder: _buildAllTracksPage,
                          index: 3,
                          itemBuilder:
                              (t) => _buildCard(
                                imageUrl: t['image'],
                                icon: Icons.music_note,
                                title: t['name'] ?? 'Без названия',
                                subtitle:
                                    t['author']?['name'] ??
                                    'Неизвестный исполнитель',
                                onTap: () {
                                  _audioService.playTrack(
                                    t,
                                    tracks: _tracks,
                                    context: context,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TrackPage(
                                            track: t,
                                            playlistTracks: _tracks,
                                          ),
                                    ),
                                  );
                                },
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              GlobalFooter(audioService: _audioService),
            ],
          ),
        ),
      ),
    );
  }

  // В классе _HomePageState добавим обновленные методы для страниц "Все"

  Widget _buildAllPlaylistsPage() {
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
          title: const Text(
            'Все плейлисты',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            _playlists.isEmpty
                ? const Center(
                  child: Text(
                    'Нет плейлистов',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return _buildCard(
                      imageUrl: playlist['image'],
                      icon: Icons.queue_music,
                      title: playlist['list_name'] ?? 'Без названия',
                      subtitle: '${playlist['tracks_count'] ?? 0} треков',
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaylistPage(playlist: playlist),
                            ),
                          ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildAllGenresPage() {
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
          title: const Text('Все жанры', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            _genres.isEmpty
                ? const Center(
                  child: Text(
                    'Нет жанров',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    return _buildCard(
                      imageUrl: genre['image'],
                      icon: Icons.category,
                      title: genre['name'] ?? 'Без названия',
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GenrePage(genre: genre),
                            ),
                          ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildAllArtistsPage() {
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
          title: const Text(
            'Все исполнители',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            _artists.isEmpty
                ? const Center(
                  child: Text(
                    'Нет исполнителей',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _artists.length,
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    return _buildCard(
                      imageUrl: artist['image'],
                      icon: Icons.person,
                      title: artist['name'] ?? 'Неизвестный исполнитель',
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtistPage(artist: artist),
                            ),
                          ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildAllTracksPage() {
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
          title: const Text('Все треки', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            _tracks.isEmpty
                ? const Center(
                  child: Text(
                    'Нет треков',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.white.withOpacity(0.1),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image:
                                track['image'] != null
                                    ? DecorationImage(
                                      image: NetworkImage(track['image']),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              track['image'] == null
                                  ? const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        title: Text(
                          track['name'] ?? 'Без названия',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          track['author']?['name'] ?? 'Неизвестный исполнитель',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _audioService.playTrack(
                              track,
                              tracks: _tracks,
                              context: context,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TrackPage(
                                      track: track,
                                      playlistTracks: _tracks,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
