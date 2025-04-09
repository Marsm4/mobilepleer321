import 'package:flutter/material.dart';
import 'package:flutter_player/footer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter_player/player_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  String? username;
  String? email;
  String? avatarUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      setState(() {
        username = response['name'] ?? 'Пользователь';
        email = user.email ?? 'Не указана';
        avatarUrl = response['avatar'] ?? 
            'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/images%20(1).png';
        isLoading = false;
      });
    } else {
      setState(() {
        username = 'Гость';
        email = 'Не авторизован';
        avatarUrl = 'https://qqqkrrkywhbxzukpuevw.supabase.co/storage/v1/object/public/storage/images%20(1).png';
        isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: username);
    File? selectedImage;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать профиль'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setState(() => selectedImage = File(pickedFile.path));
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : NetworkImage(avatarUrl!) as ImageProvider,
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: isSaving ? null : () async {
                    setState(() => isSaving = true);
                    try {
                      String? newAvatarUrl;
                      if (selectedImage != null) {
                        final fileExt = selectedImage!.path.split('.').last;
                        final fileName = '${user.id}.$fileExt';
                        await supabase.storage
                            .from('avatars')
                            .upload(fileName, selectedImage!);
                        newAvatarUrl = supabase.storage
                            .from('avatars')
                            .getPublicUrl(fileName);
                      }

                      await supabase.from('users').upsert({
                        'id': user.id,
                        'name': nameController.text,
                        if (newAvatarUrl != null) 'avatar': newAvatarUrl,
                      });

                      Navigator.pop(context);
                      _loadProfile();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    }
                  },
                  child: isSaving 
                      ? const CircularProgressIndicator()
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/auth', 
        (route) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выхода: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 38, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blueGrey],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(avatarUrl!),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      username!,
                      style: const TextStyle(
                        fontSize: 24, 
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[800],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, 
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Редактировать профиль'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _logout,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Выйти из аккаунта'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const Footer(), // Используем футер с Provider
    );
  }
}