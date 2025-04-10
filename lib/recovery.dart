import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musik_player/database/auth.dart';

class RecoveryPage
 extends StatelessWidget {
  const RecoveryPage
  ({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService();
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
        appBar: AppBar(
          title: Text("Восстановление пароля"),
          leading: IconButton(onPressed: (){
            Navigator.popAndPushNamed(context, '/');
          }, icon: Icon(CupertinoIcons.back, color: Colors.white)),
        ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextField(
                    controller: emailController,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.email,
                        color: Colors.white,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          if(emailController.text.isEmpty) {
                            print("Поле пустое");
                          } else {
                            await authService.recoveryPassword(emailController.text);
                            emailController.clear();
                          }
                        },
                        icon: Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Text("Для восстановления ддоступа к своему аккаунту, пожалуйста введите свлю почту ",
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
      ),
    );
  }
}
