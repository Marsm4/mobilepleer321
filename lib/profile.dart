import 'package:flutter/material.dart';
//auth mb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ошибка загрузки профиля: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Градиентный фон
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
          title: const Text("Профиль", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userData == null
                ? Center(
                    child: Text(
                      "Нет данных о пользователе",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Аватар пользователя
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _userData!['avatar'] != null
                              ? NetworkImage(_userData!['avatar'])
                              : null,
                          child: _userData!['avatar'] == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Имя пользователя
                        Text(
                          _userData!['name'] ?? "Имя не указано",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Email
                        Text(
                          _userData!['email'] ?? "Email не указан",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: OutlinedButton(
                                onPressed: () {
                                  // Здесь можно реализовать переход на экран редактирования профиля
                                },
                                child: const Text("Редактировать"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await _authService.logOut();
                                  Navigator.pushReplacementNamed(context, '/auth');
                                },
                                child: const Text("Выйти"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
