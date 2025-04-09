import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';
import 'package:flutter_player/database/users_table.dart';
import 'package:flutter_player/drawer.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/music/player.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> lists = [];
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tracks = [];
  final TextEditingController _searchController = TextEditingController();
  final String currentUser = Supabase.instance.client.auth.currentUser!.id.toString();
  UsersTable usersTable = UsersTable();

  @override
  void initState() {
    super.initState();
    getLists();
    getTracks();
  }

  Future<void> getLists() async {
    try {
      final response = await _supabase
          .from('list')
          .select('id, list_name, user_id')
          .eq('user_id', currentUser);

      setState(() {
        lists = response.map((item) => {
              'id': item['id']?.toString() ?? "",
              'list_name': item['list_name']?.toString() ?? 'Без названия',
              'user_id': item['user_id']?.toString() ?? '',
            }).toList();
      });
    } catch (e) {
      print('Ошибка загрузки плейлистов: $e');
    }
  }

  Future<void> getTracks() async {
    try {
      final response =
          await _supabase.from('track').select('id, name, author, image, musicUrl');

      setState(() {
        tracks = response.map((item) => {
              'id': item['id'],
              'name': item['name']?.toString() ?? 'Без названия',
              'author': item['author']?.toString() ?? 'Неизвестный исполнитель',
              'image': item['image']?.toString() ?? '',
              'musicUrl': item['musicUrl']?.toString() ?? '',
            }).toList();
      });
    } catch (e) {
      print('Ошибка загрузки треков: $e');
    }
  }

  void _showPlaylistDialog(int trackId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blue,
          title: Text('Добавить в плейлист', style: TextStyle(color: Colors.white)),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(lists[index]['list_name']!,
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      usersTable.addTrackToPlaylist(lists[index]['id']!, trackId);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get filteredTracks => tracks
      .where((track) =>
          track['author']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          track['name']!.toLowerCase().contains(_searchController.text.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text("Главная", style: TextStyle(color: Colors.white)),
        ),
        drawer: DrawerPage(),
        bottomNavigationBar: Footer(),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  labelText: 'Поиск по названию или исполнителю',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Треки",
                    style: TextStyle(fontSize: 32, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: filteredTracks.map((track) {
                    return Container(
                      width: (MediaQuery.of(context).size.width - 60) / 2,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              track['image']!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(track['name']!,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(track['author']!,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.white70),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: const Icon(CupertinoIcons.heart_fill,
                                    color: Colors.white),
                                onPressed: () async {
                                  final result = await _supabase
                                      .from('usertrack')
                                      .select()
                                      .eq('user_id', currentUser)
                                      .eq('track_id', track['id']);
                                  if (result.isEmpty) {
                                    usersTable.addUserTrack(currentUser, track['id']);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.playlist_add,
                                    color: Colors.white),
                                onPressed: () {
                                  _showPlaylistDialog(track['id']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => PlayerPage(
                                        nameSound: track['name']!,
                                        author: track['author']!,
                                        urlMusic: track['musicUrl']!,
                                        urlPhoto: track['image']!,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
