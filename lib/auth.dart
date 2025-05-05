import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Не удалось войти. Пользователь не найден.');
      }

      // Проверяем, подтвержден ли email пользователя
      if (response.user?.emailConfirmedAt == null) {
        await _supabase.auth.signOut();
        throw Exception('Email не подтвержден. Пожалуйста, проверьте вашу почту.');
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on AuthException catch (e) {
      String errorMessage;
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = 'Неверный email или пароль';
          break;
        case 'Email not confirmed':
          errorMessage = 'Email не подтвержден. Проверьте вашу почту.';
          break;
        default:
          errorMessage = 'Ошибка при входе: ${e.message}';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('images/logo.png'),
                  Text(
                    "Вход",
                    textScaler: TextScaler.linear(3),
                    style: const TextStyle(color: Colors.white),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email, color: Colors.white),
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
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
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
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      child: const Text("Забыли пароль?"),
                      onTap: () {
                        Navigator.popAndPushNamed(context, '/recovery');
                      },
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: const Text("Войти"),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.popAndPushNamed(context, '/reg');
                            },
                      child: const Text("Зарегистрироваться"),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}