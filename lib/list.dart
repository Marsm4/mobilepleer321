import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:flutter_player/music/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListPage extends StatefulWidget {
  String? id_list;
  ListPage({
    super.key,
    this.id_list,
  });

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, String>> tracks = [];
  int currentTrackIndex = 0;
  bool isPlaying = true;
  String? _id_list;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _id_list = widget.id_list;
    getListTracks();
  }

  Future<void> getListTracks() async {
    try {
      final response = await _supabase.from('playlist').select('list_id, track(name, author, image, musicUrl)')
          .eq('list_id', _id_list as String);

      setState(() {
        tracks = response.map((item) {
          final track = item['track'] as Map<String, dynamic>;
          return {
            'name': track['name']?.toString() ?? 'Без названия',
            'author': track['author']?.toString() ?? 'Неизвестный исполнитель',
            'image': track['image']?.toString() ?? 'Без названия',
            'musicUrl': track['musicUrl']?.toString() ?? 'Неизвестный исполнитель',
          };
        }).toList();
      });
    } catch (e) {
      print('Ошибка загрузки треков: $e');
    }
  }

  List<Map<String, String>> get filteredTracks => tracks
      .where((track) =>
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
          colors: [Colors.blue.shade400, Colors.blue.shade800],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Ваши плейлисты', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.blueGrey[200]),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    hintText: 'Поиск по названию или исполнителю',
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[200]),
                    hintStyle: TextStyle(color: Colors.blueGrey[200]),
                    labelStyle: TextStyle(color: Colors.blueGrey[200]),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),]),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: filteredTracks.map((track) {
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 50) / 2,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          track['image']!,
                                          height: MediaQuery.of(context).size.height * 0.3,
                                          width: MediaQuery.of(context).size.width * 0.6,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.vertical(
                                                bottom: Radius.circular(20),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  track['name']!,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  track['author']!,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  FilledButton(
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
                                          ));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700, 
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      "Прослушать",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
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
        bottomNavigationBar: Footer(),
      ),
    );
  }
}
