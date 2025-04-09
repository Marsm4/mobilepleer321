import 'package:flutter/material.dart';
import 'package:flutter_player/artist_tracks_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class LikeService {
  final Supabase _supabase = Supabase.instance;

  Future<bool> isLiked(String trackId) async {
    final userId = _supabase.client.auth.currentUser?.id;
    if (userId == null) return false;
    
    final response = await _supabase.client
        .from('user_liked_tracks')
        .select()
        .eq('user_id', userId)
        .eq('track_id', trackId)
        .maybeSingle();

    return response != null;
  }

  Future<void> toggleLike(String trackId) async {
    final userId = _supabase.client.auth.currentUser?.id;
    if (userId == null) return;

    final isCurrentlyLiked = await isLiked(trackId);
    
    if (isCurrentlyLiked) {
      await _supabase.client
          .from('user_liked_tracks')
          .delete()
          .eq('user_id', userId)
          .eq('track_id', trackId);
    } else {
      await _supabase.client
          .from('user_liked_tracks')
          .insert({
            'user_id': userId,
            'track_id': trackId,
          });
    }
  }
}

class SearchPage extends StatefulWidget {
  final Function(String, String, String, String?) onTrackSelected;

  const SearchPage({super.key, required this.onTrackSelected});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final LikeService _likeService = LikeService();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _popularTracks = [];
  bool _isSearching = false;
  bool _isLoadingPopular = true;

  @override
  void initState() {
    super.initState();
    _fetchPopularTracks();
  }

  Future<void> _fetchPopularTracks() async {
    try {
      final response = await _supabase
          .from('tracks')
          .select('''
            *,
            author:author_id (name, image)
          ''')
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        _popularTracks = List<Map<String, dynamic>>.from(response);
        _isLoadingPopular = false;
      });
    } catch (e) {
      print('Ошибка при загрузке популярных треков: $e');
      setState(() => _isLoadingPopular = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final tracksResponse = await _supabase
          .from('tracks')
          .select('''
            *,
            author:author_id (name, image)
          ''')
          .ilike('name', '%$query%')
          .limit(10);

      final authorsResponse = await _supabase
          .from('author')
          .select()
          .ilike('name', '%$query%')
          .limit(10);

      setState(() {
        _searchResults = [
          ...List<Map<String, dynamic>>.from(tracksResponse),
          ...List<Map<String, dynamic>>.from(authorsResponse.map((author) {
            return {
              'id': author['id'],
              'name': author['name'],
              'image': author['image'],
              'is_author': true,
            };
          })),
        ];
        _isSearching = false;
      });
    } catch (e) {
      print('Ошибка поиска: $e');
      setState(() => _isSearching = false);
    }
  }

  void _navigateToArtistTracks(BuildContext context, int artistId, String artistName, String? artistImage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistTracksPage(
          artistId: artistId,
          artistName: artistName,
          artistImageUrl: artistImage,
          onTrackSelected: widget.onTrackSelected,
        ),
      ),
    );
  }

  Widget _buildTrackItem(Map<String, dynamic> track, int index) {
    final authorName = track['author']?['name'] ?? 'Неизвестный исполнитель';
    final imageUrl = track['image'] ?? 
        'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/imagelist/purple.jpg';
    final trackId = track['id'].toString();

    return FutureBuilder<bool>(
      future: _likeService.isLiked(trackId),
      builder: (context, snapshot) {
        final isLiked = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () {
            widget.onTrackSelected(
              track['url'],
              track['name'] ?? 'Без названия',
              authorName,
              imageUrl,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
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
                    onPressed: () async {
                      await _likeService.toggleLike(trackId);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      widget.onTrackSelected(
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

  Widget _buildSearchResultItem(Map<String, dynamic> item) {
    final isAuthor = item['is_author'] == true;
    final image = item['image'] as String?;
    final name = item['name'] ?? 'Без названия';
    final id = item['id'].toString();

    if (isAuthor) {
      return Card(
        color: const Color.fromARGB(255, 255, 255, 255),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.blue[800],
                ),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            'Исполнитель',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          onTap: () {
            _navigateToArtistTracks(
              context,
              int.parse(id),
              name,
              image,
            );
          },
        ),
      );
    } else {
      return FutureBuilder<bool>(
        future: _likeService.isLiked(id),
        builder: (context, snapshot) {
          final isLiked = snapshot.data ?? false;
          return Card(
            color: Colors.white.withOpacity(0.9),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        image,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.music_note,
                      size: 40,
                      color: Colors.blue[800],
                    ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                item['author']?['name'] ?? 'Неизвестный исполнитель',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.blue[800],
                    ),
                    onPressed: () async {
                      await _likeService.toggleLike(id);
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: Colors.blue[800],
                    ),
                    onPressed: () {
                      widget.onTrackSelected(
                        item['url'],
                        name,
                        item['author']?['name'] ?? 'Неизвестный исполнитель',
                        image,
                      );
                    },
                  ),
                ],
              ),
              onTap: () {
                if (item['url'] != null) {
                  widget.onTrackSelected(
                    item['url'],
                    name,
                    item['author']?['name'] ?? 'Неизвестный исполнитель',
                    image,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не удалось загрузить трек'),
                    ),
                  );
                }
              },
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск треков и исполнителей',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) => _performSearch(value),
              ),
              const SizedBox(height: 20),
              if (_searchController.text.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Популярные треки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingPopular
                        ? const Center(child: CircularProgressIndicator())
                        : _popularTracks.isEmpty
                            ? const Center(
                                child: Text(
                                  'Нет популярных треков',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              )
                            : Column(
                                children: _popularTracks
                                    .asMap()
                                    .entries
                                    .map((entry) => _buildTrackItem(entry.value, entry.key))
                                    .toList(),
                              ),
                    const SizedBox(height: 20),
                  ],
                ),
              if (_isSearching)
                const Center(child: CircularProgressIndicator())
              else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Ничего не найдено',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultItem(_searchResults[index]);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}