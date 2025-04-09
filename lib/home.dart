import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/drawer.dart';
import 'package:flutter_player/playlist_tracks_page.dart';
import 'package:flutter_player/artist_tracks_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_player/player_state.dart';
import 'dart:typed_data';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Состояние загрузки
  bool _isLoadingArtists = true;
  bool _isLoadingPlaylists = true;
  bool _isLoadingTracks = true;
  
  // Данные
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _myPlaylists = [];
  List<Map<String, dynamic>> _popularTracks = [];
  List<Map<String, dynamic>> _currentPlaylist = [];
  
  bool mounted = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await _fetchArtists();
    await _fetchMyPlaylists();
    await _fetchPopularTracks();
  }

  Future<bool> _isTrackLiked(int trackId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;
      
      final response = await _supabase
          .from('user_liked_tracks')
          .select()
          .eq('user_id', userId)
          .eq('track_id', trackId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Ошибка проверки лайка: $e');
      return false;
    }
  }

  Future<void> _toggleLikeTrack(Map<String, dynamic> track) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Необходимо авторизоваться')),
        );
        return;
      }
      
      final trackId = track['id'] as int;
      final isLiked = await _isTrackLiked(trackId);
      
      if (isLiked) {
        await _supabase
            .from('user_liked_tracks')
            .delete()
            .eq('user_id', userId)
            .eq('track_id', trackId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "${track['name']}" удален из избранного')),
        );
      } else {
        await _supabase
            .from('user_liked_tracks')
            .insert({
              'user_id': userId,
              'track_id': trackId,
            });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Трек "${track['name']}" добавлен в избранное')),
        );
      }
      
      setState(() {});
    } catch (e) {
      print('Ошибка при обновлении лайка: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchPopularTracks() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('''
            *,
            author:author_id (name)
          ''')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _popularTracks = List<Map<String, dynamic>>.from(response);
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке популярных треков: $e');
      if (mounted) {
        setState(() => _isLoadingTracks = false);
      }
    }
  }

  Future<void> _fetchArtists() async {
    try {
      final response = await _supabase
          .from('author')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _artists = List<Map<String, dynamic>>.from(response);
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке исполнителей: $e');
      if (mounted) {
        setState(() => _isLoadingArtists = false);
      }
    }
  }

  Future<void> _fetchMyPlaylists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('list')
          .select('''
            *, 
            play_list(count)
          ''')
          .eq('id_user', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myPlaylists = List<Map<String, dynamic>>.from(response);
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке плейлистов: $e');
      if (mounted) {
        setState(() => _isLoadingPlaylists = false);
      }
    }
  }

  Future<void> _showAddToPlaylistDialog() async {
    final playerState = Provider.of<AppPlayerState>(context, listen: false);
    if (playerState.currentTrackUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет трека для добавления')),
      );
      return;
    }

    if (_myPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас нет плейлистов')),
      );
      return;
    }

    final selectedPlaylist = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey[800],
        title: const Text('Добавить в плейлист', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _myPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = _myPlaylists[index];
              final imageUrl = playlist['image'] ?? 
                  'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';
              final trackCount = playlist['play_list']?[0]['count'] ?? 0;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(imageUrl),
                  radius: 25,
                ),
                title: Text(
                  playlist['list_name'] ?? 'Без названия',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '$trackCount треков',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () => Navigator.pop(context, playlist['id']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (selectedPlaylist != null) {
      await _addTrackToPlaylist(selectedPlaylist, playerState.currentTrackUrl!);
    }
  }

  Future<void> _addTrackToPlaylist(int playlistId, String trackUrl) async {
    try {
      setState(() => _isLoadingPlaylists = true);
      
      final trackResponse = await _supabase
          .from('tracks')
          .select('id')
          .eq('url', trackUrl)
          .single();

      final trackId = trackResponse['id'] as int;

      final existingResponse = await _supabase
          .from('play_list')
          .select()
          .eq('list_id', playlistId)
          .eq('track_id', trackId);

      if (existingResponse.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Этот трек уже есть в плейлисте')),
        );
        return;
      }

      await _supabase
          .from('play_list')
          .insert({
            'list_id': playlistId,
            'track_id': trackId,
          });

      await _fetchMyPlaylists();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Трек добавлен в плейлист!')),
      );
    } catch (e) {
      print('Ошибка при добавлении трека: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingPlaylists = false);
    }
  }

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile?.readAsBytes();
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final filePath = 'imagelist/$fileName';
      await _supabase.storage.from('storage').uploadBinary(filePath, imageBytes);
      return _supabase.storage.from('storage').getPublicUrl(filePath);
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      return null;
    }
  }

  Future<void> _createPlaylist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Необходимо авторизоваться')),
      );
      return;
    }

    final textController = TextEditingController();
    final imageBytes = await _pickImage();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать плейлист'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(hintText: 'Название плейлиста'),
            ),
            if (imageBytes != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                height: 100,
                child: Image.memory(imageBytes),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      setState(() => _isLoadingPlaylists = true);
      
      final imageUrl = imageBytes != null
          ? await _uploadImage(imageBytes, '${DateTime.now().millisecondsSinceEpoch}.jpg')
          : 'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';

      await _supabase.from('list').insert({
        'list_name': result,
        'id_user': userId,
        'image': imageUrl,
      });

      await _fetchMyPlaylists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Плейлист "$result" создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlaylists = false);
      }
    }
  }

  Widget _buildArtistAvatar(String artistName, int artistId, String? imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistTracksPage(
              artistId: artistId,
              artistName: artistName,
              artistImageUrl: imageUrl,
              onTrackSelected: (url, title, author, image) {
                final playerState = Provider.of<AppPlayerState>(context, listen: false);
                _currentPlaylist = (_artists
                    .where((a) => a['id'] == artistId)
                    .expand((a) => (a['tracks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[])
                    .toList()).cast<Map<String, dynamic>>();
                playerState.playTrack(url, title, author, image);
              },
            ),
          ),



          
        );
      },
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.person, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index) {
    final authorName = track['author']?['name'] ?? 'Неизвестный исполнитель';
    final imageUrl = track['image'] ?? 
        'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';

    return FutureBuilder<bool>(
      future: _isTrackLiked(track['id'] as int),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () {
            final playerState = Provider.of<AppPlayerState>(context, listen: false);
            _currentPlaylist = _popularTracks;
            playerState.playTrack(
              track['url'],
              track['name'] ?? 'Без названия',
              authorName,
              imageUrl,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.blueGrey[700],
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              title: Text(
                track['name'] ?? 'Без названия',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                authorName,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: () => _toggleLikeTrack(track),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      final playerState = Provider.of<AppPlayerState>(context, listen: false);
                      _currentPlaylist = _popularTracks;
                      playerState.playTrack(
                        track['url'],
                        track['name'] ?? 'Без названия',
                        authorName,
                        imageUrl,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final trackCount = playlist['play_list']?[0]['count'] ?? 0;
    final imageUrl = playlist['image'] ?? 
        'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistTracksPage(
              playlistId: playlist['id'],
              playlistName: playlist['list_name'],
              onTrackSelected: (url, title, author, image) {
                final playerState = Provider.of<AppPlayerState>(context, listen: false);
                _currentPlaylist = (_myPlaylists
                    .where((p) => p['id'] == playlist['id'])
                    .expand((p) => (p['tracks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[])
                    .toList()).cast<Map<String, dynamic>>();
                playerState.playTrack(url, title, author, image);
              },
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blueGrey[700],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    return loadingProgress == null 
                        ? child 
                        : const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.blueGrey[700],
                      child: const Center(
                        child: Icon(Icons.music_note, color: Colors.white, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${playlist['list_name']?.trim() ?? 'Без названия'} ($trackCount)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerPage(),
      appBar: AppBar(
        title: const Text('Главная', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.blueGrey],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Раздел "Популярные исполнители"
                const Text(
                  'Популярные исполнители',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 190,
                  child: _isLoadingArtists
                      ? const Center(child: CircularProgressIndicator())
                      : _artists.isEmpty
                          ? const Center(child: Text('Нет исполнителей', style: TextStyle(color: Colors.white)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _artists.length,
                              itemBuilder: (context, index) {
                                final artist = _artists[index];
                                return Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    children: [
                                      _buildArtistAvatar(
                                        artist['name'] ?? 'Неизвестный',
                                        artist['id'] ?? 0,
                                        artist['image'],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        artist['name'] ?? 'Неизвестный',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Мои плейлисты',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: _isLoadingPlaylists
                      ? const Center(child: CircularProgressIndicator())
                      : _myPlaylists.isEmpty
                          ? Column(
                              children: [
                                const Text(
                                  'У вас пока нет плейлистов',
                                  style: TextStyle(color: Colors.white)),
                                const SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: _createPlaylist,
                                  child: const Text('Создать плейлист'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 38, 255),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _myPlaylists.length,
                              itemBuilder: (context, index) {
                                return _buildPlaylistCard(_myPlaylists[index]);
                              },
                            ),
                ),
                const SizedBox(height: 24),                
                const Text(
                  'Популярные треки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoadingTracks
                    ? const Center(child: CircularProgressIndicator())
                    : _popularTracks.isEmpty
                        ? const Center(
                            child: Text(
                             'Нет популярных треков',
                              style: TextStyle(color: Colors.white)),
                            )
                          
                        : Column(
                            children: _popularTracks
                                .asMap()
                                .entries
                                .map((entry) => _buildTrackItem(entry.value, entry.key))
                                .toList(),
                          ),
                          
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
      ),
    );
  }
}