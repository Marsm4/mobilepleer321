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
  final _supabase = Supabase.instance.client;
  
  List<Map<String, String>> lists = []; 
  List<Map<String, dynamic>> tracks = []; 
  List<Map<String, dynamic>> likedTracks = [];

  bool isPlaying = true;

  final TextEditingController _searchController = TextEditingController();
  AuthService authService = AuthService();
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
      final response = await _supabase.from('list').select('id, list_name, user_id')
      .eq('user_id', currentUser);
      
      setState(() {
        lists = response.map((item) => {
          'id':item['id']?.toString() ?? "",
          'list_name': item['list_name']?.toString() ?? 'Без названия',
          'user_id': item['user_id']?.toString() ?? 'Неизвестный исполнитель',
        }).toList();
      });
      
      print('Загружено ${lists.length} плейлистов');
    } catch (e) {
      print('Ошибка загрузки треков: $e');
    }
  }

  Future<void> getTracks() async {
    try {
      final response = await _supabase.from('track').select('id, name, author, image, musicUrl');
      
      setState(() {
        tracks = response.map((item) => {
          'id': item['id'],
          'name': item['name']?.toString() ?? 'Без названия',
          'author': item['author']?.toString() ?? 'Неизвестный исполнитель',
          'image': item['image']?.toString() ?? 'Без названия',
          'musicUrl': item['musicUrl']?.toString() ?? 'Неизвестный исполнитель',
          'isLiked': _supabase.from('usertrack').select('id').eq('track_id', item['id']).eq('user_id', currentUser) == 0 ? false : true,
        }).toList();
      });
      
      print('Загружено ${tracks.length} треков');
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
          title: Text('Добавить в плейлист', style: TextStyle(color: Colors.white),),
          content: Container(
            decoration:BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(10)
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lists.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(lists[index]['list_name']!, style: TextStyle(color: Colors.white),),
                    onTap: () {
                      usersTable.addTrackToPlaylist(lists[index]['id']!, trackId);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.white),),
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
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,        
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
                    labelText: 'Поиск по названию или исполнителю',
                    labelStyle: TextStyle(color: Colors.blueGrey[600]),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white)
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white)
                    )
                  ),
                  onChanged: (value) {
                    setState(() {
                  });
                },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  "Треки",
                  style: TextStyle(fontSize: 42),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            children: filteredTracks.map((track) {
                              return SizedBox(
                                width: (MediaQuery.of(context).size.width - 50) / 2, // 2 колонки
                                child: Column(
                                  children: [
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            track['image']!,
                                            height: MediaQuery.of(context).size.height * 0.3,
                                            width: MediaQuery.of(context).size.width * 0.6,
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.15,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            track['name']!,
                                            style: TextStyle(fontSize: 24, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          width: MediaQuery.of(context).size.width * 0.15,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            track['author']!,
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder: (context) => PlayerPage(
                                                  nameSound: track['name']!,
                                                  author: track['author']!,
                                                  urlMusic: track['musicUrl']!,
                                                  urlPhoto: track['image']!,
                                                )
                                              )
                                            );
                                          }, 
                                          child: Text("Прослушать")
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            if (await _supabase.from('usertrack')
                                                .count()
                                                .eq('user_id', currentUser)
                                                .eq('track_id', track['id'] as int) == 1) {
                                              print('track est');
                                              return;
                                            } else {
                                              usersTable.addUserTrack(currentUser, track['id']);
                                            }
                                          }, 
                                          icon: Icon(
                                            track['isLiked'] ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: Colors.white
                                          )
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _showPlaylistDialog(track['id']);
                                          },
                                          icon: Icon(Icons.playlist_add, color: Colors.white),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),    
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text("Главная", style: TextStyle(color: Colors.white),),
        ),
        bottomNavigationBar: Footer(

        ), 
        drawer: DrawerPage(),
      ),
    );
  }
}