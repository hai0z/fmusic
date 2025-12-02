class SongArtist {
  final String id;
  final String name;
  final String alias;
  final String? thumbnail;

  SongArtist({
    required this.id,
    required this.name,
    required this.alias,
    this.thumbnail,
  });

  factory SongArtist.fromJson(Map<String, dynamic> json) {
    return SongArtist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      alias: json['alias'] ?? '',
      thumbnail: json['thumbnail'],
    );
  }
}

class Song {
  final String id;
  final String title;
  final String artistsNames;
  final String thumbnail;
  final String thumbnailM;
  final int duration;
  final String? streamUrl;
  final bool isVip;
  final List<SongArtist> artists;

  Song({
    required this.id,
    required this.title,
    required this.artistsNames,
    required this.thumbnail,
    required this.thumbnailM,
    required this.duration,
    this.streamUrl,
    this.isVip = false,
    this.artists = const [],
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    List<SongArtist> artists = [];
    if (json['artists'] != null) {
      artists = (json['artists'] as List)
          .map((e) => SongArtist.fromJson(e))
          .toList();
    }

    return Song(
      id: json['encodeId'] ?? '',
      title: json['title'] ?? '',
      artistsNames: json['artistsNames'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      thumbnailM: json['thumbnailM'] ?? json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      isVip: json['streamingStatus'] == 2,
      artists: artists,
    );
  }

  String get durationText {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Song copyWith({String? streamUrl}) {
    return Song(
      id: id,
      title: title,
      artistsNames: artistsNames,
      thumbnail: thumbnail,
      thumbnailM: thumbnailM,
      duration: duration,
      streamUrl: streamUrl ?? this.streamUrl,
      isVip: isVip,
      artists: artists,
    );
  }
}
