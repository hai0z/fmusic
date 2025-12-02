import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../api/zing_mp3_api.dart';
import '../models/song.dart';

// Custom AudioSource để lazy load URL từ ZingMP3
class ZingAudioSource extends StreamAudioSource {
  final Song song;
  String? _cachedUrl;

  ZingAudioSource({required this.song, dynamic tag}) : super(tag: tag);

  Future<String?> _getStreamUrl() async {
    if (_cachedUrl != null) return _cachedUrl;

    try {
      final data = await zing.getSong(song.id);
      if (data != null && data['err'] == 0) {
        final url = data['data']['128'] ?? data['data']['320'];
        if (url != null && url != 'VIP') {
          _cachedUrl = url;
          return url;
        }
      }
    } catch (e) {
      debugPrint('Error getting stream URL: $e');
    }
    return null;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final url = await _getStreamUrl();
    if (url == null) {
      throw Exception('Cannot get stream URL for ${song.title}');
    }

    final request = await HttpClient().getUrl(Uri.parse(url));
    if (start != null || end != null) {
      request.headers.add('Range', 'bytes=${start ?? 0}-${end ?? ''}');
    }

    final response = await request.close();
    final contentLength = response.contentLength;

    return StreamAudioResponse(
      sourceLength: end != null ? null : contentLength,
      contentLength: contentLength,
      offset: start ?? 0,
      stream: response,
      contentType: 'audio/mpeg',
    );
  }
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource? _playlist;

  AudioPlayer get player => _player;
  ConcatenatingAudioSource? get playlist => _playlist;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _player.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            _player.play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  // Phát playlist từ list Song
  Future<void> playPlaylistFromSongs(
    List<Song> songs, {
    int initialIndex = 0,
  }) async {
    try {
      final sources = songs.map((song) {
        // Tạo MediaItem cho notification (Android/iOS)
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artistsNames,
          artUri: Uri.parse(song.thumbnailM),
        );

        if (Platform.isAndroid || Platform.isIOS) {
          return ZingAudioSource(song: song, tag: mediaItem);
        }
        return ZingAudioSource(song: song);
      }).toList();

      _playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(_playlist!, initialIndex: initialIndex);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing playlist: $e');
    }
  }

  // Controls
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> seekToNext() => _player.seekToNext();
  Future<void> seekToPrevious() => _player.seekToPrevious();

  // Volume & Speed
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // Loop mode
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  // Streams
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  // Getters
  bool get playing => _player.playing;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;
  int? get currentIndex => _player.currentIndex;

  Future<void> dispose() => _player.dispose();
}

final audioPlayer = AudioPlayerService();
