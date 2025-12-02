class Artist {
  final String id;
  final String name;
  final String alias;
  final String thumbnail;
  final String thumbnailM;
  final String? biography;
  final int totalFollow;
  final String? birthday;
  final String? realname;
  final String? national;

  Artist({
    required this.id,
    required this.name,
    required this.alias,
    required this.thumbnail,
    required this.thumbnailM,
    this.biography,
    this.totalFollow = 0,
    this.birthday,
    this.realname,
    this.national,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? json['encodeId'] ?? '',
      name: json['name'] ?? '',
      alias: json['alias'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      thumbnailM: json['thumbnailM'] ?? json['thumbnail'] ?? '',
      biography: json['biography'],
      totalFollow: json['totalFollow'] ?? 0,
      birthday: json['birthday'],
      realname: json['realname'],
      national: json['national'],
    );
  }

  String get followText {
    if (totalFollow >= 1000000) {
      return '${(totalFollow / 1000000).toStringAsFixed(1)}M người theo dõi';
    } else if (totalFollow >= 1000) {
      return '${(totalFollow / 1000).toStringAsFixed(1)}K người theo dõi';
    }
    return '$totalFollow người theo dõi';
  }
}
