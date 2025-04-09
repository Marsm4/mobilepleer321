import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:musicplayer52/auth_service.dart'; // Обновленный импорт

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Используем AuthService из файла auth_service.dart
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackbar('Все поля должны быть заполнены.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signIn(
        emailController.text,
        passwordController.text,
      );

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);

        _showSnackbar('Добро пожаловать, ${user.email}.');

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackbar('Ошибка аутентификации.');
      }
    } catch (e) {
      _showSnackbar('Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[700],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
        body: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('images/icon.png'),
                    const SizedBox(height: 10),
                    Text(
                      "Вход",
                      textScaleFactor: 3,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.password, color: Colors.white),
                        labelText: 'Пароль',
                        labelStyle: const TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.blueGrey,
                              )
                            : const Text("Войти"),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/reg');
                        },
                        child: const Text("Зарегистрироваться"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
