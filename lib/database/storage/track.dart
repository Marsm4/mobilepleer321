class Track {
  final int id;
  final String name;
  final String imageUrl;
  final String musicUrl;
  final int genreId;
  final int authorId;
  final DateTime createdAt;
  final String? artistName;

  Track({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.musicUrl,
    required this.genreId,
    required this.authorId,
    required this.createdAt,
    this.artistName,
  });

  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int,
      name: map['name'] as String,
      imageUrl: map['image'] as String,
      musicUrl: map['url_music'] as String,
      genreId: map['genre_id'] as int,
      authorId: map['author_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      artistName: map['artist_name'] as String?,
    );
  }
}