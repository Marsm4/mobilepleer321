import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userPhotoUrl;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Профиль'),
        ),
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Фото
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(userPhotoUrl),
            ),
            SizedBox(height: 20),
            // Имя
            Text(
              userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            // Email
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}