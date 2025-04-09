// ignore_for_file: unnecessary_to_list_in_spreads, deprecated_member_use, no_leading_underscores_for_local_identifiers, unused_field

import 'package:flutter/material.dart';
import 'package:music_player/database/track.dart';
import 'package:music_player/playlist.dart';
import 'package:music_player/services/audio_service.dart';
import 'package:music_player/services/favorite_service.dart';
import 'package:music_player/services/playlist_service.dart';
import 'package:music_player/services/track_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MediaLibraryPage extends StatefulWidget {
  const MediaLibraryPage({super.key});

  @override
  State<MediaLibraryPage> createState() => _MediaLibraryPageState();
}

class _MediaLibraryPageState extends State<MediaLibraryPage> {
  final FavoriteService _favoriteService = FavoriteService();
  final PlaylistService _playlistService = PlaylistService();
  final TrackService _trackService = TrackService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _playlists = [];
  List<Track> _favoriteTracks = [];
  List<Track> _filteredTracks = [];
  bool _isLoading = true;
  String? _selectedArtist;
  List<String> _artists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUserData(),
      _loadPlaylists(),
      _loadFavoriteTracks(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {}

  Future<void> _loadPlaylists() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final playlists = await _playlistService.getUserPlaylists(user.id);
        setState(() {
          _playlists = playlists;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки плейлистов: $e')),
        );
      }
    }
  }

  Future<void> _loadFavoriteTracks() async {
    try {
      final favoriteIds = await _favoriteService.getUserFavorites();
      final allTracks = await _trackService.getAllTracks();
      final favoriteTracks =
          allTracks.where((track) => favoriteIds.contains(track.id)).toList();
      final artists = favoriteTracks.map((t) => t.authorName).toSet().toList();

      setState(() {
        _favoriteTracks = favoriteTracks;
        _artists = artists;
        if (_selectedArtist != null &&
            !favoriteTracks.any((t) => t.authorName == _selectedArtist)) {
          _selectedArtist = null;
          _filteredTracks = favoriteTracks;
        } else if (_selectedArtist != null) {
          _filteredTracks = favoriteTracks
              .where((t) => t.authorName == _selectedArtist)
              .toList();
        } else {
          _filteredTracks = favoriteTracks;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки избранных треков: $e')),
        );
      }
    }
  }
  void _filterByArtist(String? artist) {
    setState(() {
      _selectedArtist = artist;
      _filteredTracks = artist == null
          ? _favoriteTracks
          : _favoriteTracks.where((t) => t.authorName == artist).toList();
    });
  }
  Future<void> _removeFavorite(String trackId) async {
    try {
      final currentArtist = _selectedArtist;
      await _favoriteService.removeFavorite(trackId);
      if (mounted) {
        await _loadData();
        if (currentArtist != null &&
            !_favoriteTracks.any((t) => t.authorName == currentArtist)) {
          _resetArtistFilter();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _playTrack(Track track, BuildContext context) {
    final audioService =
        Provider.of<AudioPlayerService>(context, listen: false);
    audioService.loadTrack(
      track,
      trackList: _filteredTracks,
      autoPlay: true,
    );
  }

  void _openPlaylist(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistPage(
          playlistId: playlist['id'].toString(),
          playlistName: playlist['name'] ?? 'Без названия',
          playlistImage: playlist['image'],
          onBack: () => Navigator.pop(context),
          onPlaylistDeleted: _loadData,
        ),
      ),
    );
  }

  Future<void> _createNewPlaylist() async {
    final nameController = TextEditingController();
    String? imageUrl;
    PlatformFile? playlistImageFile;
    String? playlistImagePath;

    Future<void> _pickPlaylistImage() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null) {
          setState(() {
            playlistImageFile = result.files.first;
            playlistImagePath = playlistImageFile?.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка выбора изображения: $e')),
          );
        }
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.blueGrey[900],
            title: const Text('Новый плейлист',
                style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Название плейлиста',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                    onPressed: _pickPlaylistImage,
                    child: Text(
                      playlistImageFile?.name ?? 'Выбрать изображение',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  if (playlistImageFile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Размер: ${(playlistImageFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text('Отмена', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    try {
                      // Загружаем изображение если оно выбрано
                      if (playlistImagePath != null) {
                        final file = File(playlistImagePath!);
                        final fileName =
                            'playlist_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
                        await _supabase.storage
                            .from('storages')
                            .upload('images/$fileName', file);
                        imageUrl = _supabase.storage
                            .from('storages')
                            .getPublicUrl('images/$fileName');
                      }

                      await _playlistService.createPlaylist(
                        nameController.text,
                        _supabase.auth.currentUser!.id,
                        imageUrl: imageUrl,
                      );

                      await _loadData();

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Плейлист создан')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: ${e.toString()}')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Создать',
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _resetArtistFilter() {
    setState(() {
      _selectedArtist = null;
      _filteredTracks = _favoriteTracks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Мои плейлисты',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.white),
                            onPressed: _createNewPlaylist,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: _playlists.isEmpty
                          ? Center(
                              child: Text(
                                'Нет плейлистов',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _playlists.length,
                              itemBuilder: (context, index) {
                                final playlist = _playlists[index];
                                return GestureDetector(
                                  onTap: () => _openPlaylist(playlist),
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: playlist['image'] != null
                                              ? Image.network(
                                                  playlist['image'],
                                                  width: 160,
                                                  height: 160,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    width: 160,
                                                    height: 160,
                                                    color: Colors.grey[800],
                                                    child: const Icon(
                                                        Icons.music_note,
                                                        color: Colors.white),
                                                  ),
                                                )
                                              : Container(
                                                  width: 160,
                                                  height: 160,
                                                  color: Colors.grey[800],
                                                  child: const Icon(
                                                      Icons.music_note,
                                                      color: Colors.white),
                                                ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          playlist['name'] ?? 'Без названия',
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
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedArtist == null
                                ? 'Избранные треки'
                                : 'Избранные треки: $_selectedArtist',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedArtist != null)
                            TextButton(
                              onPressed: _resetArtistFilter,
                              child: const Text(
                                'Сбросить',
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_artists.isNotEmpty && _selectedArtist == null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _artists.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final artist = _artists[index];
                              return ChoiceChip(
                                label: Text(artist),
                                selected: _selectedArtist == artist,
                                onSelected: (selected) {
                                  _filterByArtist(selected ? artist : null);
                                },
                                selectedColor: Colors.blueAccent,
                                labelStyle: TextStyle(
                                  color: _selectedArtist == artist
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (_filteredTracks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _selectedArtist == null
                              ? 'Нет избранных треков'
                              : 'Нет треков этого исполнителя',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = _filteredTracks[index];
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
                              icon:
                                  const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _removeFavorite(track.id),
                            ),
                          );
                        },
                        childCount: _filteredTracks.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
