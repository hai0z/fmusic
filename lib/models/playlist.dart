import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String thumbnail;
  final String thumbnailM;
  final String artistsNames;
  final int songCount;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.thumbnailM,
    required this.artistsNames,
    required this.songCount,
    this.songs = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    List<Song> songs = [];
    if (json['song'] != null && json['song']['items'] != null) {
      songs = (json['song']['items'] as List)
          .map((e) => Song.fromJson(e))
          .toList();
    }

    return Playlist(
      id: json['encodeId'] ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      thumbnailM: json['thumbnailM'] ?? json['thumbnail'] ?? '',
      artistsNames: json['artistsNames'] ?? '',
      songCount: json['song']?['total'] ?? 0,
      songs: songs,
    );
  }
}
