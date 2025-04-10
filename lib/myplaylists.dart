import 'package:flutter/material.dart';
import 'package:musik_player/drawer.dart';
import 'package:musik_player/play_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:musik_player/widgets/mini_player.dart';

class MyPlaylistsPage extends StatefulWidget {
  const MyPlaylistsPage({super.key});

  @override
  _MyPlaylistsPageState createState() => _MyPlaylistsPageState();
}

class _MyPlaylistsPageState extends State<MyPlaylistsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _playlists = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _createController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('list')
          .select('''
            id,
            list_name,
            created_at,
            user_id
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _playlists = (response as List).map((playlist) {
          return {
            'id': playlist['id'].toString(),
            'title': playlist['list_name']?.toString() ?? 'Без названия',
            'created_at': playlist['created_at']?.toString(),
            'user_id': playlist['user_id']?.toString(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки плейлистов: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createPlaylist() async {
    if (_createController.text.isEmpty) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('list').insert({
          'list_name': _createController.text,
          'user_id': user.id,
          'created_at': DateTime.now().toIso8601String(),
        });

        await _fetchPlaylists();
        _createController.clear();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Плейлист создан'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showCreateDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3E50),
          title: const Text(
            'Создать плейлист',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _createController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Название плейлиста',
              hintStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: _createPlaylist,
              child: const Text(
                'Создать',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50), // Темный серо-голубой
            Color(0xFF4CA1AF), // Голубовато-серый
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Мои Плейлисты',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _showCreateDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : _playlists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'У вас пока нет плейлистов',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2C3E50),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: _showCreateDialog,
                              child: const Text('Создать первый плейлист'),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.7, // Уменьшенное соотношение сторон
                          ),
                          itemCount: _playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = _playlists[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaylistPage(
                                      playlistId: playlist['id'],
                                      playlistName: playlist['title'],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white.withOpacity(0.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60, // Уменьшенная ширина иконки
                                      height: 60, // Уменьшенная высота иконки
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.queue_music,
                                        color: Colors.white,
                                        size: 30, // Уменьшенный размер иконки
                                      ),
                                    ),
                                    const SizedBox(height: 8), // Уменьшенный отступ
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        playlist['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14, // Уменьшенный размер текста
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Плейлист',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 10, // Уменьшенный размер текста
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      drawer: const DrawerPage(),
      ),
    );
  }
}