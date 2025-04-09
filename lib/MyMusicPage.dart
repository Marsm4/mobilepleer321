import 'package:flutter/material.dart';
import 'package:music_player/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/TrackList.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _tracksFuture;
  late SharedPreferences _prefs;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPrefsAndLoadData();
  }

  Future<void> _initPrefsAndLoadData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка инициализации: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tracks = await _fetchFavoriteTracks();
      setState(() {
        _tracksFuture = Future.value(tracks);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteTracks() async {
    final userId = _prefs.getInt('userId');
    if (userId == null) {
      throw Exception('Пользователь не авторизован');
    }

    final favoritesResponse = await supabase
        .from('Favourite_Tracks')
        .select('Id_track')
        .eq('Id_user', userId)
        .then((response) {
          if (response.isEmpty) return [];
          return response;
        })
        .catchError((error) {
          throw Exception('Ошибка получения треков: $error');
        });

    final trackIds = favoritesResponse.map((item) => item['Id_track'] as int).toList();
    if (trackIds.isEmpty) return [];

    final tracksResponse = await supabase
        .from('Track')
        .select('*, Author (Name)')
        .inFilter('id', trackIds)
        .then((response) => response)
        .catchError((error) {
          throw Exception('Ошибка получения информации о треках: $error');
        });

    return tracksResponse;
  }

  Future<void> _removeFromFavorites(int trackId) async {
    try {
      final userId = _prefs.getInt('userId');
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      await supabase
          .from('Favourite_Tracks')
          .delete()
          .eq('Id_user', userId)
          .eq('Id_track', trackId);

      await _loadData();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Трек удален из моей музыки'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Неизвестная ошибка',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Повторить попытку'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 50, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Нет треков в моей музыке',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Вернуться назад',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Моя музыка',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : FutureBuilder(
                      future: _tracksFuture,
                      builder: (context, snapshot) {
                        final tracks = snapshot.data ?? [];
                        if (tracks.isEmpty) return _buildEmptyState();

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                '${tracks.length} ${tracks.length == 1 ? 'трек' : tracks.length < 5 ? 'трека' : 'треков'} в моей музыке',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TrackList(
                                tracks: tracks,
                                canDelete: true,
                                onDelete: _removeFromFavorites,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}