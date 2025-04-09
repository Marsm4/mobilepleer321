import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/database/users_table.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/music/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  _TrackPageState createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tracks = []; 
  int currentTrackIndex = 0;
  bool isPlaying = true;
  final TextEditingController _searchController = TextEditingController();
  final String currentUser = Supabase.instance.client.auth.currentUser!.id.toString();
  UsersTable usersTable = UsersTable();
  
  @override
  void initState() {
    super.initState();
    getTracks();
  }

  Future<void> getTracks() async {
    try {
      final response = await _supabase.from('usertrack')
      .select('id, track(name, author, image, musicUrl), user_id')
      .eq('user_id', currentUser);
      
      setState(() {
        tracks = response.map((item) {
          final track = item['track'] as Map<String, dynamic>;
          return {
            'id': item['id'],
            'name': track['name']?.toString() ?? 'Без названия',
            'author': track['author']?.toString() ?? 'Неизвестный исполнитель',
            'image': track['image']?.toString() ?? 'Без названия',
            'musicUrl': track['musicUrl']?.toString() ?? 'Неизвестный исполнитель',
          };
        }).toList();
      });
      
      print('Загружено ${tracks.length} треков');
    } catch (e) {
      print('Ошибка загрузки треков: $e');
    }
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
        appBar: AppBar(
          title: Text('Ваши треки', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.transparent,
        ),
        
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    hintText: 'Поиск по названию или исполнителю',
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
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
            ),
            // Основной контент
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
                                        ElevatedButton(onPressed: () {
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
                                        }, child: Text("Прослушать")),
                                        IconButton(onPressed: () {
                                            usersTable.deleteUserTrack(track['id']);
                                            Navigator.of(context).popAndPushNamed('/tracks');
                                            setState(() {
                                            });
                                        }, icon: Icon(CupertinoIcons.heart_fill, color: Colors.white,))
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
            SizedBox(height: 20), 
          ],
        ),
        bottomNavigationBar: Footer(

        ),
      ),
    );
  }
}