import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    AuthService authService = AuthService();

    return Container(
      // Градиент — поменяли порядок цветов
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blueGrey, Colors.blue],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            "Сброс пароля",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            onPressed: () {
              Navigator.popAndPushNamed(context, '/');
            },
            icon: const Icon(CupertinoIcons.back, color: Colors.white),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.white.withOpacity(0.1),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: emailController,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: Colors.white),
                        suffixIcon: IconButton(
                          onPressed: () async {
                            if (emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Email field is empty.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blueGrey[700],
                                ),
                              );
                            } else {
                              await authService.recoveryPassword(
                                emailController.text,
                              );
                              emailController.clear();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Message sent to ${emailController.text}.',
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.blueGrey[700],
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Для восстановления доступа к своему аккаунту, пожалуйста введите свою почту",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
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
