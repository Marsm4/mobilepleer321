// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  String? _avatarUrl;
  bool _isLoading = true;
  bool _isPasswordLoading = false;
  bool _showPasswordFields = false;
  PlatformFile? _avatarFile;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .rpc('get_user_data', params: {'user_id': user.id}).single();

      setState(() {
        _nameController.text = response['name'] ?? '';
        _avatarUrl = response['avatar'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _avatarFile = result.files.first;
          _avatarPath = _avatarFile?.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      String? newAvatarUrl;
      if (_avatarPath != null) {
        final file = File(_avatarPath!);
        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';

        // Загружаем файл в правильный путь
        await _supabase.storage
            .from('storages') // Указываем только имя bucket
            .upload('images/$fileName', file); // Путь внутри bucket

        // Получаем публичный URL
        newAvatarUrl =
            _supabase.storage.from('storages').getPublicUrl('images/$fileName');
      }

      await _supabase.rpc('update_user_data', params: {
        'user_id': user.id,
        'name': _nameController.text,
        'avatar': newAvatarUrl ?? _avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новые пароли не совпадают')),
      );
      return;
    }

    try {
      setState(() => _isPasswordLoading = true);

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      // Проверка валидности email перед отправкой
      if (!_isValidEmail(user.email!)) {
        throw Exception('Недопустимый email адрес');
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успешно изменен')),
        );
        setState(() {
          _showPasswordFields = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка изменения пароля: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки профиля'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarPath != null
                            ? FileImage(File(_avatarPath!))
                            : (_avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const AssetImage('assets/default_avatar.png')
                                    as ImageProvider),
                        child: _avatarPath == null && _avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Никнейм',
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите никнейм';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // OutlinedButton(
                    //   onPressed: () => setState(
                    //       () => _showPasswordFields = !_showPasswordFields),
                    //   child: Text(_showPasswordFields
                    //       ? 'Скрыть смену пароля'
                    //       : 'Изменить пароль'),
                    // ),
                    // if (_showPasswordFields) ...[
                    //   const SizedBox(height: 20),
                    //   TextFormField(
                    //     controller: _currentPasswordController,
                    //     obscureText: true,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Текущий пароль',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //     validator: (value) {
                    //       if (_showPasswordFields &&
                    //           (value == null || value.isEmpty)) {
                    //         return 'Введите текущий пароль';
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    //   const SizedBox(height: 10),
                    //   TextFormField(
                    //     controller: _newPasswordController,
                    //     obscureText: true,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Новый пароль',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //     validator: (value) {
                    //       if (_showPasswordFields &&
                    //           (value == null || value.isEmpty)) {
                    //         return 'Введите новый пароль';
                    //       }
                    //       if (value != null && value.length < 6) {
                    //         return 'Пароль должен быть не менее 6 символов';
                    //       }
                    //       return null;
                    //     },
                    //   ),
                    //   const SizedBox(height: 10),
                    //   TextFormField(
                    //     controller: _confirmPasswordController,
                    //     obscureText: true,
                    //     decoration: const InputDecoration(
                    //       labelText: 'Повторите новый пароль',
                    //       border: OutlineInputBorder(),
                    //     ),
                    //   ),
                    //   const SizedBox(height: 10),
                    //   ElevatedButton(
                    //     onPressed: _isPasswordLoading ? null : _updatePassword,
                    //     child: _isPasswordLoading
                    //         ? const CircularProgressIndicator()
                    //         : const Text('Изменить пароль'),
                    //   ),
                    //   const SizedBox(height: 20),
                    // ],
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Сохранить изменения'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
