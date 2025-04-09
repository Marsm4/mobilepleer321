import 'package:flutter/material.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/favorite_service.dart';
import 'package:music_player/services/track_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FavoriteService _favoriteService = FavoriteService();
  final TrackService _trackService = TrackService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Track> _favoriteTracks = [];
  bool _isLoading = true;
  String _userName = "Загрузка...";
  String? _userAvatarUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _fetchUserData();
    await _loadFavoriteTracks();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _userName = response['name'] ?? "Пользователь";
        _userAvatarUrl = response['avatar'];
      });
    } catch (e) {
      print("Ошибка загрузки данных пользователя: $e");
    }
  }

  Future<void> _loadFavoriteTracks() async {
    try {
      final favoriteIds = await _favoriteService.getUserFavorites();
      final allTracks = await _trackService.getAllTracks();
      setState(() {
        _favoriteTracks = allTracks.where((track) => favoriteIds.contains(track.id)).toList();
      });
    } catch (e) {
      print("Ошибка загрузки избранных треков: $e");
    }
  }

  void _playTrack(Track track, BuildContext context) {
    final audioService = Provider.of<AudioPlayerService>(context, listen: false);
    audioService.loadTrack(track, trackList: _favoriteTracks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      _userAvatarUrl ?? 'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//Default_pfp.jpg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Избранные треки',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _favoriteTracks.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Нет избранных треков',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _favoriteTracks.length,
                          itemBuilder: (context, index) {
                            final track = _favoriteTracks[index];
                            return ListTile(
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
                                    child: const Icon(
                                      Icons.music_note, 
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                track.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                track.authorName,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () async {
                                  await _favoriteService.removeFavorite(track.id);
                                  await _loadFavoriteTracks();
                                },
                              ),
                              onTap: () => _playTrack(track, context),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}