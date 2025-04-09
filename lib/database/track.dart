class Track {
  final String id;
  final String name;
  final String imageUrl;
  final String musicUrl;
  final String authorId;
  final String authorName;
  final String userId;
  final String? albumId;
  final String? genreId;
  bool isFavorite;

  Track({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.musicUrl,
    required this.authorId,
    required this.authorName,
    required this.userId,
    this.albumId,
    this.genreId,
    this.isFavorite = false,
  });

  factory Track.fromSupabase(Map<String, dynamic> data) {
    return Track(
      id: data['id'].toString(),
      name: data['name'] as String? ?? 'Без названия',
      imageUrl: data['image'] as String? ?? '',
      musicUrl: data['url_music'] as String? ?? '',
      authorId: data['author_id']?.toString() ?? '',
      authorName: data['author']?['name'] as String? ?? 'Неизвестный исполнитель',
      userId: data['user_id']?.toString() ?? '',
      albumId: data['album_id']?.toString(),
      genreId: data['genre_id']?.toString(),
      isFavorite: false,
    );
  }
}