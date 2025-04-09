import 'package:flutter/material.dart';
import 'package:flutter_player/database/auth.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
          title: Text("Профиль", style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Row(
              children: [
                Image.network(
                  'https://rjnwjeopknvsrqsetrsf.supabase.co/storage/v1/object/public/storages//usericon.png',
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("имя_пользователя", 
                      style: TextStyle(
                        fontSize: 32
                      ),
                    ),
                    Text("почта_пользователя@почта", 
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.5)
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
            ),
            Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: OutlinedButton(onPressed: () {
                    
                  }, child: Text("Редактировать"),),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: ElevatedButton(onPressed: () {
                    authService.logOut();
                    Navigator.popAndPushNamed(context, '/auth');
                  }, child: Text("Выйти"),),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}