import 'package:flutter/material.dart';
import 'package:musik_player/database/auth.dart';
import 'package:musik_player/database/user_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegPage extends StatefulWidget {
  const RegPage({super.key});

  @override
  State<RegPage> createState() => _RegPageState();
}

class _RegPageState extends State<RegPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController repeatController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  AuthService authService = AuthService();
  UsersTable usersTable = UsersTable();
  
  @override
  Widget build(BuildContext context) {
      return Container(
        height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C3E50),
              Color(0xFF4CA1AF),],
            ),
          ),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('images/icon.png'),
                Text(
                  "Вход",
                  textScaler: TextScaler.linear(3),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.white),
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white))),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password, color: Colors.white),
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white))),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: passController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password, color: Colors.white),
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white))),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: repeatController,
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.password, color: Colors.white),
                        labelText: 'Repeat Password',
                        labelStyle: TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.white))),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
               
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty ||
                      passController.text.isEmpty ||
                      repeatController.text.isEmpty ||
                      nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Зарегистрирован",
                          style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.white,
                          ),
                        );
                        } else {
                            if (passController.text == repeatController.text) {
                                var user = await authService.sighUp(
                                    emailController.text, passController.text);
                                if (user != null) {
                                  await usersTable.addUser(nameController.text,
                                      emailController.text, passController.text);
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('isLoggedIn', true);
                                    Navigator.popAndPushNamed(context, '/home');
                                } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Пользователь не создан: ${user!.email}",
                                      style: TextStyle(color: Colors.black),
                                      ),
                                      backgroundColor: Colors.white,
                                      ),
                                    );
                                }
                            } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Пароли не совпадают",
                                  style: TextStyle(color: Colors.black),
                                  ),
                                  backgroundColor: Colors.white,
                                  ),
                                );
                            }
                          }
                    }, child: Text("Создать"),
                   
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popAndPushNamed(context, '/reg');
                    },
                    child: Text("Войти"),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popAndPushNamed(context, '/');
                    },
                    child: Text("Назад"),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}