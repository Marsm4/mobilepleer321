import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_player/player_state.dart';
import 'package:music_player/player_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // Фиксированный ID для примера
      const fixedUserId = '63bb2011-9d00-497d-ac51-b16cc26c8ca4';
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', fixedUserId)
          .single();

      setState(() {
        _userData = response;
        _nameController.text = response['name'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      const fixedUserId = '63bb2011-9d00-497d-ac51-b16cc26c8ca4';
      
      setState(() {
        _isLoading = true;
      });

      await _supabase
          .from('users')
          .update({'name': _nameController.text.trim()})
          .eq('id', fixedUserId);

      setState(() {
        _isEditing = false;
        _userData = {
          ...?_userData,
          'name': _nameController.text.trim()
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Provider.of<PlayerState>(context);

    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Профиль',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Аватар пользователя
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _userData?['avatar'] != null
                            ? NetworkImage(_userData!['avatar'])
                            : null,
                        child: _userData?['avatar'] == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Email (не редактируется)
                      Text(
                        _userData?['email'] ?? 'Нет email',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Форма редактирования имени
                      Form(
                        key: _formKey,
                        child: _isEditing
                            ? SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Имя',
                                    labelStyle: const TextStyle(color: Colors.blueGrey),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blueGrey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blueGrey[100]!),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите имя';
                                    }
                                    return null;
                                  },
                                ),
                              )
                            : Text(
                                _userData?['name'] ?? 'Без имени',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 30),
                      // Кнопки редактирования/сохранения
                      if (_isEditing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[700],
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Сохранить'),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _nameController.text = _userData?['name'] ?? '';
                                });
                              },
                              child: const Text('Отмена'),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                          ),
                          child: const Text('Редактировать профиль', 
                          style: TextStyle(fontSize: 14, color: Colors.white),),
                        ),
                      const SizedBox(height: 40),
                      // Кнопки разделов
                      SizedBox(
                        width: 300,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Ваши плейлисты',
                              style: TextStyle(fontSize: 14, color: Colors.white),),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Ваши альбомы',
                              style: TextStyle(fontSize: 14, color: Colors.white),),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey[800],
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Любимые исполнители',
                              style: TextStyle(fontSize: 14, color: Colors.white),),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: InkWell(
        onTap: () {
          if (playerState.currentTrackUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerPage()),
            );
          }
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blueGrey[800]!,
            border: Border(top: BorderSide(
              color: Colors.blueGrey[600]!,
              width: 1,
            )),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: playerState.currentTrackImage != null
                      ? Image.network(
                          playerState.currentTrackImage!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.blueGrey[600],
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playerState.currentTrackName ?? 'Название трека',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      playerState.currentTrackAuthor ?? 'Исполнитель',
                      style: TextStyle(color: Colors.blueGrey[300], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (playerState.currentTrackUrl != null) {
                    if (playerState.isPlaying) {
                      playerState.pause();
                    } else {
                      playerState.resume();
                    }
                  }
                },
                icon: Icon(
                  playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}