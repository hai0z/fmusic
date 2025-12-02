import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../models/lyric.dart';
import '../services/audio_player_service.dart';
import '../api/zing_mp3_api.dart';

class PlayerProvider extends ChangeNotifier {
  List<Song> _playlist = [];
  int _currentIndex = 0;
  int? _lastEmittedIndex; // Track index từ just_audio
  bool _isLoading = false;
  bool _isShuffled = false;
  LoopMode _loopMode = LoopMode.off;
  Color _dominantColor = Colors.grey.shade900;
  String? _lastImageUrl;
  Lyric? _currentLyric;
  bool _isLoadingLyric = false;
  Map<String, dynamic>? _songInfo;

  Song? get currentSong =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  bool get isShuffled => _isShuffled;
  LoopMode get loopMode => _loopMode;
  Color get dominantColor => _dominantColor;
  Lyric? get currentLyric => _currentLyric;
  bool get isLoadingLyric => _isLoadingLyric;
  Map<String, dynamic>? get songInfo => _songInfo;

  AudioPlayer get player => audioPlayer.player;

  PlayerProvider() {
    _listenToCurrentIndex();
  }

  // Lắng nghe khi just_audio chuyển bài
  void _listenToCurrentIndex() {
    // Lắng nghe sequence state để biết bài hiện tại
    audioPlayer.sequenceStateStream.listen((state) {
      if (state == null || _playlist.isEmpty) return;

      final index = state.currentIndex;
      if (index >= 0 &&
          index < _playlist.length &&
          index != _lastEmittedIndex) {
        _lastEmittedIndex = index;
        _currentIndex = index;
        final song = _playlist[index];
        _updateDominantColor(song.thumbnailM);
        _loadLyric(song.id);
        _loadSongInfo(song.id);
        notifyListeners();
      }
    });

    // Lắng nghe trạng thái loading
    audioPlayer.playerStateStream.listen((state) {
      final newLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (newLoading != _isLoading) {
        _isLoading = newLoading;
        notifyListeners();
      }
    });
  }

  // Cập nhật màu từ ảnh album
  Future<void> _updateDominantColor(String imageUrl) async {
    if (_lastImageUrl == imageUrl) return;
    _lastImageUrl = imageUrl;

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
      );
      _dominantColor =
          paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          Colors.grey.shade900;
      notifyListeners();
    } catch (e) {
      _dominantColor = Colors.grey.shade900;
    }
  }

  // Phát playlist - dùng queue của just_audio
  Future<void> playPlaylist(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    _playlist = songs;
    _currentIndex = startIndex;
    _lastEmittedIndex = null; // Reset để listener có thể trigger
    notifyListeners();

    // Load metadata cho bài đầu tiên
    final firstSong = songs[startIndex];
    _updateDominantColor(firstSong.thumbnailM);
    _loadLyric(firstSong.id);
    _loadSongInfo(firstSong.id);

    // Phát playlist qua AudioPlayerService
    await audioPlayer.playPlaylistFromSongs(songs, initialIndex: startIndex);
  }

  // Next/Previous - dùng just_audio
  Future<void> playNext() async {
    await audioPlayer.seekToNext();
  }

  Future<void> playPrevious() async {
    await audioPlayer.seekToPrevious();
  }

  // Controls
  void togglePlay() {
    if (player.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    audioPlayer.setShuffleModeEnabled(_isShuffled);
    notifyListeners();
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }
    audioPlayer.setLoopMode(_loopMode);
    notifyListeners();
  }

  void seek(Duration position) {
    audioPlayer.seek(position);
  }

  // Load lyric
  Future<void> _loadLyric(String songId) async {
    _currentLyric = null;
    _isLoadingLyric = true;
    notifyListeners();

    try {
      final data = await zing.getSongLyric(songId);
      if (data != null && data['err'] == 0) {
        _currentLyric = Lyric.fromJson(data['data']);
      }
    } catch (e) {
      debugPrint('Error loading lyric: $e');
    }

    _isLoadingLyric = false;
    notifyListeners();
  }

  // Lấy index của lyric line hiện tại
  int getCurrentLyricIndex(Duration position) {
    if (_currentLyric == null || !_currentLyric!.hasSyncedLyrics) return -1;

    final posMs = position.inMilliseconds;
    for (int i = _currentLyric!.lines.length - 1; i >= 0; i--) {
      if (posMs >= _currentLyric!.lines[i].startTime) {
        return i;
      }
    }
    return -1;
  }

  // Load song info
  Future<void> _loadSongInfo(String songId) async {
    _songInfo = null;

    try {
      final data = await zing.getSongInfo(songId);
      if (data != null && data['err'] == 0) {
        _songInfo = data['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading song info: $e');
    }
  }
}
