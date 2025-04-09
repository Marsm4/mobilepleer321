import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedAuthor = "Все";
  Set<int> _favoriteTracks = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedTrackIndex;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchTracks();
    _fetchFavorites();
    _initAudioPlayer();
  }

  Future<void> _fetchTracks() async {
    try {
      final response = await Supabase.instance.client
          .from('track')
          .select('*, artist:author_id(name)');
      if (response is List) {
        setState(() {
          _tracks = response.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки треков: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final response = await Supabase.instance.client
        .from('favorites')
        .select('track_id')
        .eq('user_id', userId);
    final trackIds = response.map<int>((e) => e['track_id'] as int).toSet();
    setState(() => _favoriteTracks = trackIds);
  }

  Future<void> _toggleFavorite(int trackId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final isFav = _favoriteTracks.contains(trackId);
    if (isFav) {
      await Supabase.instance.client
          .from('favorites')
          .delete()
          .match({'user_id': userId, 'track_id': trackId});
    } else {
      await Supabase.instance.client.from('favorites').insert({
        'user_id': userId,
        'track_id': trackId,
      });
    }
    _fetchFavorites();
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _totalDuration = duration);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _currentPosition = position);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _playTrack(int index) async {
    final track = _filteredTracks()[index];
    _selectedTrackIndex = index;
    try {
      await _audioPlayer.play(UrlSource(track['musicurl']));
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка воспроизведения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseTrack() async {
    await _audioPlayer.pause();
    setState(() => _isPlaying = false);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pauseTrack();
    } else if (_selectedTrackIndex != null) {
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);
    }
  }

  void _closePlayer() {
    _audioPlayer.stop();
    setState(() {
      _selectedTrackIndex = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  List<Map<String, dynamic>> _filteredTracks() {
    final lowerQuery = _searchQuery.toLowerCase();
    return _tracks.where((track) {
      final name = track['name']?.toString().toLowerCase() ?? "";
      final author = track['artist']?['name']?.toString().toLowerCase() ?? "";
      final matchesSearch = name.contains(lowerQuery);
      final matchesAuthor = _selectedAuthor == "Все" ||
          author == _selectedAuthor.toLowerCase();
      return matchesSearch && matchesAuthor;
    }).toList();
  }

  List<String> _getUniqueAuthors() {
    final authors =
        _tracks.map((t) => t['artist']?['name'] ?? "Неизвестный").toSet().toList();
    authors.sort();
    return ["Все", ...authors];
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //const double inputWidth = 400;
    final filteredTracks = _filteredTracks();
    final currentTrack = _selectedTrackIndex != null
        ? filteredTracks[_selectedTrackIndex!]
        : null;
    final authors = _getUniqueAuthors();

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
        drawer: const DrawerPage(),
        appBar: AppBar(
          title: const Text(
            "Все треки",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Row для поиска и фильтрации на одном уровне
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        // Поисковое поле
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 45,
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Поиск треков",
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon: Icon(Icons.search, color: Colors.white),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Dropdown для фильтрации по автору
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 45,
                            child: DropdownButtonFormField<String>(
                              value: _selectedAuthor,
                              dropdownColor: Colors.blueGrey,
                              iconEnabledColor: Colors.white,
                              decoration: const InputDecoration(
                                labelText: 'Автор',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Colors.white),
                              items: authors.map((author) {
                                return DropdownMenuItem<String>(
                                  value: author,
                                  child: Text(author),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAuthor = value ?? "Все";
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Сетка треков
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(6.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredTracks.length,
                      itemBuilder: (context, index) {
                        final track = filteredTracks[index];
                        final trackId = track['id'];
                        final isFavorite = _favoriteTracks.contains(trackId);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade800.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            image: track['image'] != null
                                ? DecorationImage(
                                    image: NetworkImage(track['image']),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.25),
                                      BlendMode.darken,
                                    ),
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        track['name'] ?? 'Без названия',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14, // увеличенный размер
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        track['artist']?['name'] ?? 'Неизвестный',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12, // увеличенный размер
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : Colors.white,
                                    size: 16,
                                  ),
                                  onPressed: () => _toggleFavorite(trackId!),
                                ),
                              ),
                              Center(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    size: 26,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => _playTrack(index),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Плеер
                  if (_selectedTrackIndex != null) ...[
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 1.2),
                        borderRadius: BorderRadius.circular(12),
                        image: currentTrack != null && currentTrack['image'] != null
                            ? DecorationImage(
                                image: NetworkImage(currentTrack['image']),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.4),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              currentTrack?['name'] ?? 'Без названия',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            min: 0,
                            max: _totalDuration.inSeconds.toDouble() > 0
                                ? _totalDuration.inSeconds.toDouble()
                                : 1,
                            value: _currentPosition.inSeconds
                                .clamp(0, _totalDuration.inSeconds)
                                .toDouble(),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white38,
                            onChanged: (value) async {
                              await _audioPlayer.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_currentPosition),
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _formatDuration(_totalDuration),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _closePlayer,
                            ),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
      ),
    );
  }
}
