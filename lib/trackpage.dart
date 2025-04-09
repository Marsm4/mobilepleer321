import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drawer.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedAuthor = "Все";

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _selectedTrackIndex;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteTracks();
    _initAudioPlayer();
  }

  Future<void> _fetchFavoriteTracks() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final response = await Supabase.instance.client
          .from('favorites')
          .select(
              'id, track_id, track(id, name, musicurl, image, artist:author_id(name))')
          .eq('user_id', userId);

      final favoriteTracks = (response as List<dynamic>)
          .map<Map<String, dynamic>>((e) => {
                ...Map<String, dynamic>.from(e['track']),
                'favorite_id': e['id'],
              })
          .toList();

      setState(() {
        _tracks = favoriteTracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки избранного: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromFavorites(int favoriteId) async {
    try {
      await Supabase.instance.client
          .from('favorites')
          .delete()
          .eq('id', favoriteId);
      await _fetchFavoriteTracks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления трека: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPosition = _totalDuration;
      });
    });
  }

  Future<void> _playTrack(int index) async {
    final track = _filteredTracks()[index];
    _selectedTrackIndex = index;
    try {
      await _audioPlayer.play(UrlSource(track['musicurl']));
      setState(() {
        _isPlaying = true;
      });
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
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pauseTrack();
    } else if (_selectedTrackIndex != null) {
      await _audioPlayer.resume();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _stopPlayer() {
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
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  /// Возвращает список уникальных исполнителей
  List<String> _getUniqueAuthors() {
    final authors = _tracks
        .map((t) => t['artist']?['name'] ?? "Неизвестный")
        .toSet()
        .toList();
    authors.sort();
    return ["Все", ...authors];
  }

  /// Фильтрация по названию и исполнителю
  List<Map<String, dynamic>> _filteredTracks() {
    final lowerQuery = _searchQuery.toLowerCase();
    return _tracks.where((track) {
      final name = track['name']?.toString().toLowerCase() ?? "";
      final author =
          track['artist']?['name']?.toString().toLowerCase() ?? "неизвестный";
      final matchesSearch = name.contains(lowerQuery);
      final matchesAuthor = _selectedAuthor == "Все" ||
          author == _selectedAuthor.toLowerCase();
      return matchesSearch && matchesAuthor;
    }).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTracks = _filteredTracks();
    final currentTrack =
        _selectedTrackIndex != null ? filteredTracks[_selectedTrackIndex!] : null;
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
            "Моя музыка",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Row для поиска и фильтрации по исполнителям
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 10),
                    child: Row(
                      children: [
                        // Поле поиска
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 45,
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Поиск треков",
                                hintStyle: TextStyle(color: Colors.white70),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Dropdown фильтр по исполнителям
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 45,
                            child: DropdownButtonFormField<String>(
                              value: _selectedAuthor,
                              dropdownColor: Colors.blueGrey,
                              iconEnabledColor: Colors.white,
                              decoration: const InputDecoration(
                                labelText: 'Исполнитель',
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
                  // Список избранных треков
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTracks.length,
                      itemBuilder: (context, index) {
                        final track = filteredTracks[index];
                        final authorName =
                            track['artist']?['name'] ?? 'Неизвестный';
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade700.withOpacity(0.5),
                            border: Border.all(
                                color: Colors.blueGrey.shade900, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: track['image'] != null
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      image: DecorationImage(
                                        image: NetworkImage(track['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.music_note,
                                    size: 16, color: Colors.white),
                            title: Text(
                              track['name'] ?? 'Без названия',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            subtitle: Text(
                              authorName,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            onTap: () => _playTrack(index),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _removeFromFavorites(track['favorite_id']),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Плеер слайдер, оформленный как в "всех треках"
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  filteredTracks[_selectedTrackIndex!]['name'] ??
                                      'Без названия',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.white),
                                onPressed: _stopPlayer,
                              ),
                            ],
                          ),
                          Slider(
                            min: 0,
                            max: _totalDuration.inSeconds.toDouble() > 0
                                ? _totalDuration.inSeconds.toDouble()
                                : 1,
                            value: _currentPosition.inSeconds.clamp(
                                    0, _totalDuration.inSeconds)
                                .toDouble(),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white38,
                            onChanged: (value) async {
                              await _audioPlayer
                                  .seek(Duration(seconds: value.toInt()));
                              setState(() {});
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
                                  size: 36,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ],
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
