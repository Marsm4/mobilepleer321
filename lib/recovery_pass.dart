import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player/database/auth.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Восстановление пароля'),
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, '/');
          },
          icon: Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    cursorColor: Colors.white,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          if (emailController.text.isEmpty) {                            
                            print("Поле пустое");// ignore: avoid_print
                          } else {
                            await authService.recoveryPassword(emailController.text);
                            emailController.clear();
                          }
                        },
                        icon: Icon(Icons.send),
                        color: Colors.white,
                      ),
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Color(0xFFC0C0C0)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(                   
                    "Для восстановления доступа к своему аккаунту, пожалуйста, введите свою почту",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFFC0C0C0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}