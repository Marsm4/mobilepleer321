import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  dynamic userData;
  bool isLoading = true;
  bool isEditing = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await supabase.from('users').select().eq('id', userId).single();

      setState(() {
        userData = response;
        _nameController.text = userData?['name'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('users')
          .update({'name': _nameController.text}).eq('id', userId);

      setState(() => isEditing = false);
      await _fetchUserData();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: ${e.toString()}'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  Future<void> _updateAvatar() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null || !mounted) return;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final Uint8List bytes = await pickedFile.readAsBytes();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = pickedFile.path.split('.').last.toLowerCase();
      final fileName = 'avatars/user_$userId/$timestamp.$extension';

      String contentType = 'image/jpeg';
      if (extension == 'png')
        contentType = 'image/png';
      else if (extension == 'webp')
        contentType = 'image/webp';
      else if (extension == 'gif') contentType = 'image/gif';

      await supabase.storage.from('storages').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final String publicUrl =
          supabase.storage.from('storages').getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'avatar': publicUrl}).eq('id', userId);

      await _fetchUserData();
    } catch (e) {
      debugPrint('Ошибка загрузки аватара: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аватара: ${e.toString()}'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/home');
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Профиль',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _updateAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Color(0xFF282828),
                            child: userData?['avatar'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      userData!['avatar'],
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white.withOpacity(0.7),
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                          ),
                          if (isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1DB954),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    isEditing
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: TextField(
                              controller: _nameController,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF1DB954),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            userData?['name'] ?? 'Имя пользователя',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text(
                      userData?['email'] ?? 'email@example.com',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton(
                          onPressed: () {
                            if (isEditing) {
                              _updateProfile();
                            } else {
                              setState(() {
                                isEditing = true;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1DB954),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            isEditing ? "Сохранить" : "Редактировать профиль",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isEditing)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isEditing = false;
                            _nameController.text = userData?['name'] ?? '';
                          });
                        },
                        child: Text(
                          "Отменить",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF282828),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.phone,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            title: Text(
                              "+7 (937) 381-06-77",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withOpacity(0.1),
                            indent: 16,
                            endIndent: 16,
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            title: Text(
                              "Казань, Россия",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
