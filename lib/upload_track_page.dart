// upload_track_page.dart
// ignore_for_file: unused_field, prefer_final_fields

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadTrackPage extends StatefulWidget {
  const UploadTrackPage({super.key});

  @override
  State<UploadTrackPage> createState() => _UploadTrackPageState();
}

class _UploadTrackPageState extends State<UploadTrackPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _albumNameController = TextEditingController();

  String? _authorImagePath;
  String? _selectedGenre;
  String? _selectedAlbum;
  String? _selectedAuthor;
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _albums = [];
  List<Map<String, dynamic>> _authors = [];

  bool _isLoading = false;
  bool _isUploading = false;
  bool _showAddAuthorField = false;
  bool _showAddAlbumField = false;

  String? _audioFilePath;
  String? _imageFilePath;
  PlatformFile? _audioFile;
  PlatformFile? _imageFile;
  PlatformFile? _authorImageFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorNameController.dispose();
    _albumNameController.dispose();
    super.dispose();
  }

  Future<void> _addNewAuthor() async {
    if (_authorNameController.text.isEmpty) {
      _showError('Введите имя автора');
      return;
    }

    try {
      setState(() => _isLoading = true);

      String? imageUrl;
      if (_authorImagePath != null) {
        final file = File(_authorImagePath!);
        final fileName =
            'author_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
        await Supabase.instance.client.storage
            .from('storages')
            .upload('images/$fileName', file);
        imageUrl = Supabase.instance.client.storage
            .from('storages')
            .getPublicUrl('images/$fileName');
      }

      await Supabase.instance.client.from('author').insert({
        'name': _authorNameController.text,
        'image': imageUrl ??
            'https://nmidcmsxkqbgsjhhnvfo.supabase.co/storage/v1/object/public/storages//Default_pfp.jpg'
      });

      await _loadData();
      setState(() {
        _authorNameController.clear();
        _authorImagePath = null;
        _authorImageFile = null;
        _showAddAuthorField = false;
      });
    } catch (e) {
      _showError('Ошибка добавления автора: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAuthorImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _authorImageFile = result.files.first;
          _authorImagePath = _authorImageFile?.path;
        });
      }
    } catch (e) {
      _showError('Ошибка выбора изображения: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final genresResponse = await Supabase.instance.client
          .from('genre')
          .select()
          .order('name', ascending: true);

      final albumsResponse = await Supabase.instance.client
          .from('album')
          .select()
          .order('name', ascending: true);

      final authorsResponse = await Supabase.instance.client
          .from('author')
          .select()
          .order('name', ascending: true);

      setState(() {
        _genres = List<Map<String, dynamic>>.from(genresResponse);
        _albums = List<Map<String, dynamic>>.from(albumsResponse);
        _authors = List<Map<String, dynamic>>.from(authorsResponse);
      });
    } catch (e) {
      _showError('Ошибка загрузки данных: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadFile(String filePath, String folderName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) throw Exception('Файл не найден');

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
      final fullPath = '$folderName/$fileName';

      await Supabase.instance.client.storage
          .from('storages')
          .upload(fullPath, file);

      return Supabase.instance.client.storage
          .from('storages')
          .getPublicUrl(fullPath);
    } catch (e) {
      _showError('Ошибка загрузки файла: $e');
      return null;
    }
  }

  Future<String?> _createNewAlbum(
      String albumName, String? imageUrl, String authorId) async {
    try {
      final response = await Supabase.instance.client
          .from('album')
          .insert({
            'name': albumName,
            'author_id': authorId,
            'image': imageUrl,
          })
          .select('id')
          .single();

      return response['id'].toString();
    } catch (e) {
      _showError('Ошибка создания альбома: $e');
      return null;
    }
  }

  Future<void> _uploadTrack() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFilePath == null) {
      _showError('Пожалуйста, выберите аудиофайл');
      return;
    }
    if (_selectedAuthor == null) {
      _showError('Пожалуйста, выберите автора');
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');
      final audioUrl = await _uploadFile(_audioFilePath!, 'audios');
      if (audioUrl == null) return;

      String? imageUrl;
      if (_imageFilePath != null) {
        imageUrl = await _uploadFile(_imageFilePath!, 'images');
      }
      String? albumId;
      if (_selectedAlbum == 'new_album') {
        albumId = await _createNewAlbum(
            _nameController.text, imageUrl, _selectedAuthor!);
        if (albumId == null) return;
      } else {
        albumId = _selectedAlbum;
      }
      await Supabase.instance.client.from('track').insert({
        'name': _nameController.text,
        'genre_id': _selectedGenre,
        'album_id': albumId,
        'author_id': _selectedAuthor,
        'url_music': audioUrl,
        'image': imageUrl,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      _showSuccess('Трек успешно загружен!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Ошибка загрузки трека: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Загрузить трек')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      style: const TextStyle(color: Colors.white),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название трека',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 221, 221, 221)),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите название трека';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Автор:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedAuthor,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        ..._authors.map((author) {
                          return DropdownMenuItem<String>(
                            value: author['id'].toString(),
                            child: Text(author['name']),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedAuthor = value),
                      validator: (value) {
                        if (value == null) return 'Выберите автора';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => setState(
                          () => _showAddAuthorField = !_showAddAuthorField),
                      child: const Text('Добавить нового автора'),
                    ),
                    if (_showAddAuthorField) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _authorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя нового автора',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _pickAuthorImage,
                        child: Text(_authorImageFile?.name ??
                            'Выбрать изображение автора'),
                      ),
                      if (_authorImageFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Размер: ${(_authorImageFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addNewAuthor,
                        child: const Text('Сохранить автора'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedGenre,
                      decoration: const InputDecoration(
                        labelText: 'Жанр',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 221, 221, 221)),
                        border: OutlineInputBorder(),
                      ),
                      items: _genres.map((genre) {
                        return DropdownMenuItem<String>(
                          value: genre['id'].toString(),
                          child: Text(
                            genre['name'] ?? 'Без названия',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGenre = value),
                    ),
                    const SizedBox(height: 20),

                    // Выбор альбома с возможностью создания нового
                    DropdownButtonFormField<String>(
                      value: _selectedAlbum,
                      decoration: const InputDecoration(
                        labelText: 'Альбом',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 221, 221, 221)),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'new_album',
                          child: Text('Создать новый альбом'),
                        ),
                        ..._albums.map((album) {
                          return DropdownMenuItem<String>(
                            value: album['id'].toString(),
                            child: Text(album['name'] ?? 'Без названия'),
                          );
                        }),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedAlbum = value),
                    ),
                    const SizedBox(height: 20),

                    // Загрузка аудио
                    Text(
                      'Аудиофайл:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _pickAudioFile,
                      child: Text(_audioFile?.name ?? 'Выбрать аудиофайл'),
                    ),
                    if (_audioFile != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Размер: ${(_audioFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Загрузка обложки
                    Text(
                      'Обложка:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _pickImageFile,
                      child: Text(_imageFile?.name ?? 'Выбрать изображение'),
                    ),
                    const SizedBox(height: 30),

                    // Кнопка загрузки
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadTrack,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Загрузить трек',
                              style: TextStyle(color: Colors.black),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _audioFile = result.files.first;
          _audioFilePath = _audioFile?.path;
        });
      }
    } catch (e) {
      _showError('Ошибка выбора аудиофайла: $e');
    }
  }

  Future<void> _pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _imageFile = result.files.first;
          _imageFilePath = _imageFile?.path;
        });
      }
    } catch (e) {
      _showError('Ошибка выбора изображения: $e');
    }
  }
}
