class Playlist {
  final int id;
  final String listName;
  final String? coverUrl;

  Playlist({
    required this.id,
    required this.listName,
    this.coverUrl,
  });

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'],
      listName: map['list_name'],
      coverUrl: map['cover_url'],
    );
  }
}