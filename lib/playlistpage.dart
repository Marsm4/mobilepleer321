import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/list.dart';
import 'package:flutter_player/database/users_table.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<Map<String, String>> lists = []; 
  bool isPlaying = true;
  UsersTable usersTable = UsersTable();

  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newPlaylistController = TextEditingController();
  final String currentUser = Supabase.instance.client.auth.currentUser!.id.toString();

  @override
  void initState() {
    super.initState();
    getLists();
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
      
      print('Загружено ${lists.length} треков');
    } catch (e) {
      print('Ошибка загрузки треков: $e');
    }
  }

  void _showAddPlaylistDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blue,
          title: Text('Новый плейлист', style: TextStyle(color: Colors.white),),
          content: TextField(
            style: TextStyle(color: Colors.white),
            controller: _newPlaylistController,
            decoration: InputDecoration(
              hintText: 'Введите название плейлиста',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              focusColor: Colors.white,
              hoverColor: Colors.white,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Создать', style: TextStyle(color: Colors.white),),
              onPressed: () {
                usersTable.addUserList(_newPlaylistController.text, currentUser);
                getLists();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  List<Map<String, String>> get filteredLists => lists
      .where((list) =>
          list['list_name']!.toLowerCase().contains(_searchController.text.toLowerCase()))
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
          title: Text('Ваши плейлисты', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.785,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: Colors.blueGrey[600]),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            filled: true,
                            hintText: 'Поиск по названию',
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
                    SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.blueGrey[600]),
                        onPressed: _showAddPlaylistDialog,
                      ),
                    ),
                  ],
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
                          children: filteredLists.map((list) {
                            return SizedBox(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(200, 0, 200, 0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: MediaQuery.of(context).size.height * 0.05,
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.music_note, color: Colors.white,),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Container(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              list['list_name']!,
                                              style: TextStyle(color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Container(
                                        alignment: Alignment.centerRight,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                  builder: (context) => ListPage(
                                                    id_list: list['id']
                                                  )
                                                )
                                              );
                                            }, child: Text("Прослушать")),
                                            IconButton(onPressed: () {
                                              usersTable.deleteUserList(list['id']!);
                                              getLists();
                                              Navigator.of(context).popAndPushNamed('/playlists');
                                            }, icon: Icon(Icons.delete, color: Colors.white,))
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
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
