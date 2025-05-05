import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecoveryPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _supabase = Supabase.instance.client;

  RecoveryPage({super.key});

  Future<void> _sendRecoveryEmail(BuildContext context) async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пожалуйста, введите email')),
      );
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Письмо для восстановления отправлено на $email')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[600],
        title: Text("Восстановление пароля", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () {
            Navigator.popAndPushNamed(context, '/');
          },
          icon: Icon(CupertinoIcons.back, color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: TextField(
                controller: _emailController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  suffixIcon: IconButton(
                    onPressed: () => _sendRecoveryEmail(context),
                    icon: Icon(Icons.send, color: Colors.white),
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Text(
              "Для восстановления доступа к своему аккаунту, пожалуйста введите свою почту",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}