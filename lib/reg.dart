import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegPage extends StatefulWidget {
  const RegPage({super.key});

  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _supabase = Supabase.instance.client;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, заполните все поля')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пароли не совпадают')),
      );
      return;
    }

    try {
      // Используем встроенную аутентификацию Supabase
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      if (response.user == null) {
        throw Exception('Пользователь не создан');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Регистрация успешна!')),
      );

      Navigator.popAndPushNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при регистрации: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/logo.png'),
            Text(
              "Регистрация",
              textScaler: TextScaler.linear(3),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Имя',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  TextField(
                    controller: _emailController,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password, color: Colors.white),
                      labelText: 'Пароль',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password, color: Colors.white),
                      labelText: 'Подтвердите пароль',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: ElevatedButton(
                onPressed: _register,
                child: Text("Создать аккаунт"),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/');
                },
                child: Text("Войти"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}