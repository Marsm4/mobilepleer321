import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';
import 'package:flutter_player/database/users_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegPage extends StatefulWidget {
  const RegPage({super.key});

  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  // Контроллеры для текстовых полей
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatController = TextEditingController();

  // Сервисы для работы с аутентификацией и таблицей пользователей
  AuthService authService = AuthService();
  UsersTable usersTable = UsersTable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 3, 0, 58),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/icon.png'), // Логотип приложения
            Text(
              "Регистрация",
              textScaler: TextScaler.linear(3),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  // Поле для ввода имени
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
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
                  // Поле для ввода email
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Логин',
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
                  // Поле для ввода пароля
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
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
                  // Поле для подтверждения пароля
                  TextField(
                    controller: repeatController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
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
            // Кнопка "Создать аккаунт"
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: ElevatedButton(
                onPressed: () async {
                  print("Кнопка 'Создать аккаунт' нажата"); // Отладочный вывод
                   if (emailController.text.isEmpty || passwordController.text.isEmpty || repeatController.text.isEmpty || nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Все поля должны быть заполнены.', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.blueGrey[700],
                    ));
                  } else {
                    if (passwordController.text == repeatController.text) {
                      print("Пароли совпадают, пытаемся зарегистрировать пользователя"); // Отладочный вывод
                      var user = await authService.signUp(emailController.text, passwordController.text);
                      if (user != null) {
                        print("Пользователь успешно зарегистрирован, добавляем в таблицу users"); // Отладочный вывод
                        await usersTable.addUser(nameController.text, emailController.text, passwordController.text);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool("isLoggedIn", true);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Добро пожаловать, ${user.email!}.', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.blueGrey[700],
                        ));
                        Navigator.popAndPushNamed(context, '/');
                      } else {
                        print("Ошибка регистрации: пользователь не создан"); // Отладочный вывод
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Ошибка регистрации.', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.blueGrey[700],
                        ));
                      }
                    } else {
                      print("Пароли не совпадают"); // Отладочный вывод
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Пароли не совпадают.', style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.blueGrey[700],
                      ));
                    }
                  }
                },
                child: Text("Создать аккаунт"),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Кнопка "Войти"
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.popAndPushNamed(context, '/auth');
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