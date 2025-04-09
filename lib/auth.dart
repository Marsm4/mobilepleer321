import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _resetPassword() async {
  try {
    final response = await _supabase
          .from('User')
          .select()
          .or('login.eq.${_loginController.text.trim()},email.eq.${_loginController.text.trim()}')
          .maybeSingle();

    if(response == null) {
      throw Exception('Email не найден');
    }

    await _supabase.auth.resetPasswordForEmail(response['email']);
    setState(() {
      _errorMessage = 'Письмо для сброса пароля отправлено на ${response['email']}';
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Ошибка при сбросе пароля: $e';
    });
  }
}
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _supabase
          .from('User')
          .select()
          .or('login.eq.${_loginController.text.trim()},email.eq.${_loginController.text.trim()}')
          .maybeSingle();

      if (response == null) {
        throw Exception('Пользователь не найден');
      }

      if(response['password'] != _passwordController.text.trim()) {
        throw Exception('Неверный пароль');
      }
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: response['email'],
        password: _passwordController.text.trim(),
      );

      if (res.user == null) {
        throw Exception('Ошибка при входе: Пользователь не найден');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', response['id']);
      
      if (mounted) {
        Navigator.popAndPushNamed(context, "/home");
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при входе: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              "Вход",
              textScaler: TextScaler.linear(3),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _loginController,
                style: TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.email,
                    color: Colors.white,
                  ),
                  labelText: 'Email or Login',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.015,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _passwordController,
                style: TextStyle(color: Colors.white),
                obscureText: true,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.password,
                    color: Colors.white,
                  ),
                  labelText: 'Пароль',
                  labelStyle: TextStyle(color: Colors.white),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              alignment: Alignment.centerRight,
              child: InkWell(
                child: Text("Забыли пароль?"),
                onTap: () {_resetPassword();},
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.015,
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: !_isLoading ? ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: Text("Войти"),
              ) : Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.width * 0.015,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/reg');
                },
                child: Text("Создать аккаунт"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}