import 'package:flutter/material.dart';
import 'package:music_player/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/TrackList.dart';

class AuthorPage extends StatefulWidget {
  final int authorId;

  const AuthorPage({super.key, required this.authorId});

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  final supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _artistFuture;
  late Future<List<Map<String, dynamic>>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _artistFuture = _fetchArtist();
    _tracksFuture = _fetchTracks();
  }

  Future<Map<String, dynamic>> _fetchArtist() async {
    final response = await supabase
        .from('Author')
        .select()
        .eq('id', widget.authorId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    final response = await supabase
        .from('Track')
        .select('*, Author (Name, Image)')
        .eq('Id_Author', widget.authorId);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(child: Container(
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
          title: const Text(
            'Исполнитель',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {},
              style: const ButtonStyle(
                iconColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
          ],
        ),
        body: FutureBuilder(
          future: Future.wait([_artistFuture, _tracksFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Нет данных'));
            }

            final artist = snapshot.data![0] as Map<String, dynamic>;
            final tracks = snapshot.data![1] as List<Map<String, dynamic>>;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    backgroundImage: NetworkImage(artist['Image'] ?? ''),
                    radius: 60,
                    onBackgroundImageError: (_, __) => 
                      const AssetImage('assets/default_avatar.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    artist['Name'] ?? 'Неизвестный исполнитель',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        setState(_loadData);
                      },
                      child: TrackList(
                        tracks: tracks
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    )
    ); 
  }
}