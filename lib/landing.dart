import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'home.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late Future<bool> _isLoggedInFuture;

  Future<bool> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        // Пока идет загрузка, показываем индикатор
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если произошла ошибка, выводим сообщение
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Text(
                'Ошибка загрузки',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Если пользователь аутентифицирован, переходим на HomePage, иначе на AuthPage
        bool isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const HomePage() : const AuthPage();
      },
    );
  }
}
