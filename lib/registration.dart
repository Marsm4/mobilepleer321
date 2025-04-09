import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database/users_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegPage extends StatefulWidget {
  const RegPage({super.key});

  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatController = TextEditingController();

  final UsersTable usersTable = UsersTable();
  final AuthService authService = AuthService();

  bool _isLoading = false;

  Future<void> _handleRegistration() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        repeatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Все поля должны быть заполнены.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey[700],
        ),
      );
      return;
    }

    if (passwordController.text != repeatController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Пароли не совпадают.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey[700],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Попытка регистрации через AuthService
      final user = await authService.signUp(
        emailController.text,
        passwordController.text,
      );

      if (user != null) {
        // Добавление пользователя в таблицу
        await usersTable.addUser(
          nameController.text,
          emailController.text,
          passwordController.text,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("isLoggedIn", true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Добро пожаловать, ${user.email!}.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blueGrey[700],
          ),
        );

        // Переход на главную страницу без сохранения экрана регистрации в стеке
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Ошибка регистрации.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blueGrey[700],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey[700],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Фон с градиентом
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
              // Небольшая прозрачность, чтобы градиент фона был слегка виден
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              child: Container(
                width: 360, // Фиксированная ширина для более ровного вида
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/icon.png'),
                    const SizedBox(height: 10),
                    Text(
                      "Регистрация",
                      textScaler: TextScaler.linear(3),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: nameController,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Login',
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
                      style: const TextStyle(color: Colors.white),
                      controller: emailController,
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
                        prefixIcon:
                            const Icon(Icons.password, color: Colors.white),
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
                    const SizedBox(height: 15),
                    TextField(
                      controller: repeatController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.password, color: Colors.white),
                        labelText: 'Подтвердите пароль',
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
                        onPressed: _isLoading ? null : _handleRegistration,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.blueGrey,
                              )
                            : const Text("Создать аккаунт"),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 200,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/auth');
                        },
                        child: const Text("Войти"),
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
