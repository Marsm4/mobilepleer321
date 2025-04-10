import 'package:flutter/material.dart';
import 'package:musik_player/database/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  AuthService authService = AuthService();
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
              Color(0xFF4CA1AF),]
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
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    child: Text("Забыли пароль?"),
                    onTap: () {
                      Navigator.popAndPushNamed(context, '/recovery');
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: ()async {
                      if(emailController.text.isEmpty || passController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Поля пустые!",
                          style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.white,
                          ),
                        );
          
                      }else {
                        var user = await authService.sighIN(
                          emailController.text , passController.text
                        );
          
                        if (user!= null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);
                          Navigator.popAndPushNamed(context, '/');
                        }else {
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Зарегестрирован: ${user!.email}",
                          style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.white,
                          ),
                        );
                       }
                      }
                    },
                    child: Text("Войти"),
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
                    child: Text("Создать аккаунт"),
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
