class LyricLine {
  final int startTime; // milliseconds
  final int endTime;
  final String text;

  LyricLine({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      startTime: (json['startTime'] ?? 0) as int,
      endTime: (json['endTime'] ?? 0) as int,
      text: json['data'] ?? '',
    );
  }
}

class Lyric {
  final List<LyricLine> lines;
  final String? defaultLyric;

  Lyric({required this.lines, this.defaultLyric});

  factory Lyric.fromJson(Map<String, dynamic> json) {
    List<LyricLine> lines = [];

    // Parse synced lyrics (sentences)
    if (json['sentences'] != null) {
      for (var sentence in json['sentences']) {
        final words = sentence['words'] as List? ?? [];
        if (words.isNotEmpty) {
          final text = words.map((w) => w['data'] ?? '').join(' ');
          // startTime từ API đã là milliseconds
          final startTime = (words.first['startTime'] ?? 0) as int;
          final endTime = (words.last['endTime'] ?? 0) as int;
          lines.add(
            LyricLine(startTime: startTime, endTime: endTime, text: text),
          );
        }
      }
    }

    return Lyric(
      lines: lines,
      defaultLyric: json['file'] != null ? null : json['content'],
    );
  }

  bool get hasSyncedLyrics => lines.isNotEmpty;
}
