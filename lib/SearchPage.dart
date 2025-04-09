import 'dart:async';
import 'package:flutter/material.dart';
import 'package:music_player/AuthorPage.dart';
import 'package:music_player/playerProvider';
import 'package:music_player/track.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _allTracks = [];
  List<Map<String, dynamic>> _allAuthors = [];
  List<Map<String, dynamic>> _filteredTracks = [];
  List<Map<String, dynamic>> _filteredAuthors = [];
  
  bool _isLoading = false;
  bool _isLoadingMoreTracks = false;
  bool _isLoadingMoreAuthors = false;
  bool _hasMoreTracks = true;
  bool _hasMoreAuthors = true;

  String _searchQuery = '';
  Timer? _debounceTimer;
  
  int _tracksPage = 0;
  int _authorsPage = 0;
  final int _itemsPerPage = 3;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _allTracks = [];
      _allAuthors = [];
      _filteredTracks = [];
      _filteredAuthors = [];
    });

    try {
      final tracksResponse = await supabase
          .from('Track')
          .select('*, Author (Name)')
          .range(0, _itemsPerPage - 1);

      final authorsResponse = await supabase
          .from('Author')
          .select()
          .range(0, _itemsPerPage - 1);

      setState(() {
        _allTracks = _removeDuplicates(tracksResponse, 'id');
        _allAuthors = _removeDuplicates(authorsResponse, 'id');
        _filteredTracks = _allTracks;
        _filteredAuthors = _allAuthors;
        _isLoading = false;
        _tracksPage = 1;
        _authorsPage = 1;
        _hasMoreTracks = tracksResponse.length == _itemsPerPage;
        _hasMoreAuthors = authorsResponse.length == _itemsPerPage;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> items, String idKey) {
    final ids = <dynamic>{};
    return items.where((item) => ids.add(item[idKey])).toList();
  }

  Future<void> _loadMoreTracks() async {
    if (_isLoadingMoreTracks || !_hasMoreTracks || _searchQuery.isNotEmpty) return;

    setState(() {
      _isLoadingMoreTracks = true;
    });

    try {
      final newTracks = await supabase
          .from('Track')
          .select('*, Author (Name)')
          .range(
            _tracksPage * _itemsPerPage,
            (_tracksPage + 1) * _itemsPerPage - 1,
          );

      final uniqueNewTracks = _removeDuplicates(newTracks, 'id')
          .where((newTrack) => !_allTracks.any((track) => track['id'] == newTrack['id']))
          .toList();

      setState(() {
        _allTracks = [];
        _allTracks.addAll(uniqueNewTracks);
        _filteredTracks.addAll(uniqueNewTracks);
        _tracksPage++;
        _hasMoreTracks = newTracks.length == _itemsPerPage;
        _isLoadingMoreTracks = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreTracks = false;
      });
    }
  }

  Future<void> _loadMoreAuthors() async {
    if (_isLoadingMoreAuthors || !_hasMoreAuthors) return;

    setState(() {
      _isLoadingMoreAuthors = true;
    });

    try {
      final newAuthors = await supabase
          .from('Author')
          .select()
          .range(
            _authorsPage * _itemsPerPage,
            (_authorsPage + 1) * _itemsPerPage - 1,
          );

      final uniqueNewAuthors = _removeDuplicates(newAuthors, 'id')
          .where((newAuthor) => !_allAuthors.any((author) => author['id'] == newAuthor['id']))
          .toList();

      setState(() {
        _allAuthors = [];
        _allAuthors.addAll(uniqueNewAuthors);
        if (_searchQuery.isEmpty) {
          _filteredAuthors.addAll(uniqueNewAuthors);
        } else {
          _filterAuthors();
        }
        _authorsPage++;
        _hasMoreAuthors = newAuthors.length == _itemsPerPage;
        _isLoadingMoreAuthors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreAuthors = false;
      });
    }
  }

  void _scrollListener() {
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;
    final double delta = MediaQuery.of(context).size.height * 0.2;

    if (maxScroll - currentScroll <= delta) {
      _loadMoreTracks();
    }
  }

  void _onSearchChanged() async{
    if(_searchController.text == '') return;
    final tracksResponse = await supabase
          .from('Track')
          .select('*, Author (Name)');

      final authorsResponse = await supabase
          .from('Author')
          .select();

      _allTracks = tracksResponse;
      _allAuthors = authorsResponse;

    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredTracks = _allTracks;
          _filteredAuthors = _allAuthors;
        } else {
          _filterTracks();
          _filterAuthors();
        }
      });
    });
  }

  void _filterTracks() {
    _filteredTracks = _allTracks.where((track) =>
        track['Name']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
    ).toList();
  }

  void _filterAuthors() {
    _filteredAuthors = _allAuthors.where((author) =>
        author['Name']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          title: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск треков и исполнителей...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filteredTracks = _allTracks;
                      _filteredAuthors = _allAuthors;
                    });
                  },
                ),
              ),
              cursorColor: Colors.white,
              autofocus: true,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_filteredAuthors.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _searchQuery.isEmpty ? 'Все исполнители' : 'Исполнители',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_hasMoreAuthors && _searchQuery.isEmpty)
                              TextButton(
                                onPressed: _loadMoreAuthors,
                                child: _isLoadingMoreAuthors
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Показать еще',
                                        style: TextStyle(color: Colors.white),
                                      ),
                              ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredAuthors.length,
                        itemBuilder: (context, index) => _buildAuthorCard(_filteredAuthors[index]),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_filteredTracks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _searchQuery.isEmpty ? 'Все треки' : 'Треки',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ..._filteredTracks.map((track) => _buildTrackCard(track)),
                      if (_isLoadingMoreTracks)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                    if (_filteredTracks.isEmpty && _filteredAuthors.isEmpty && _searchQuery.isNotEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 50, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить запрос',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(Map<String, dynamic> author) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.white),
        title: Text(
          author['Name'] ?? 'Неизвестный исполнитель',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuthorPage(
                authorId: author['id'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackCard(Map<String, dynamic> track) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.white),
        title: Text(
          track['Name'] ?? 'Неизвестный трек',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          track['Author']?['Name'] ?? 'Неизвестный исполнитель',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: const Icon(Icons.play_arrow, color: Colors.white),
        onTap: () {
          final player = Provider.of<PlayerProvider>(context, listen: false);

          player.setTracks(_filteredTracks, index: _filteredTracks.indexWhere((t) => t['id'] == track['id']));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackPage(
                trackList: _filteredTracks,
                currentTrackIndex: _filteredTracks.indexWhere((t) => t['id'] == track['id']),
                startPlaying: true,
              ),
            ),
          );
        },
      ),
    );
  }
}