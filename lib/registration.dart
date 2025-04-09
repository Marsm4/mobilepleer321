import 'dart:ui';
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatController = TextEditingController();

  final UsersTable usersTable = UsersTable();
  final AuthService authService = AuthService();

  Future<void> _handleRegistration() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        repeatController.text.isEmpty ||
        nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'All fields must be filled.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else if (passwordController.text != repeatController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Passwords do not match.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      final user = await authService.signUp(
        emailController.text,
        passwordController.text,
      );
      
      if (user != null) {
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
              'Welcome, ${user.email!}.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.popAndPushNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 2,
            colors: [
              Color(0xFF151515),
              Colors.blue,
              Colors.cyan,
            ],
            stops: [0.5, 0.6, 0.8],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/icon.png',
                  width: 150,
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  "Регистрация",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 30),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person, color: Colors.white),
                              labelText: 'Login',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                          Divider(color: Colors.white70),
                          TextField(
                            controller: emailController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email, color: Colors.white),
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                          Divider(color: Colors.white70),
                          TextField(
                            controller: passwordController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock, color: Colors.white),
                              labelText: 'Пароль',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                          Divider(color: Colors.white70),
                          TextField(
                            controller: repeatController,
                            style: TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.white),
                              labelText: 'Подтвердите пароль',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _handleRegistration,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white, width: 2),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Создать аккаунт",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.popAndPushNamed(context, '/');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Войти",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}