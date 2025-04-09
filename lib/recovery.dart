import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService(); 
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text("Восстановление пароля", style: TextStyle(color: Colors.white,)),
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
                  style: TextStyle(color: Colors.white),
                  controller: emailController,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email,
                      color: Colors.white,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () async {
                        if (emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Email field is empty.', style: TextStyle(color: Colors.white),), 
                          backgroundColor: Colors.blueGrey[700],));
                        } else {
                          await authService.recoveryPassword(emailController.text);
                          emailController.clear();
      
                          ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Message sent to $emailController.', style: TextStyle(color: Colors.white),), 
                          backgroundColor: Colors.blueGrey[700],));
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
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),)
            ],
          ),
        ),
      ),
    );
  }
}