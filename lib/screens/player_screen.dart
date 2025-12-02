import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';
import '../main.dart';
import 'lyric_screen.dart';
import 'artist_screen.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Không có bài hát',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Tăng saturation để màu rõ hơn (giống mini player)
        final hsl = HSLColor.fromColor(provider.dominantColor);
        final topColor = hsl
            .withLightness(0.35)
            .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
            .toColor();
        final bottomColor = hsl
            .withLightness(0.1)
            .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
            .toColor();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor, Colors.black],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Đang phát', style: TextStyle(fontSize: 14)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.queue_music),
                  onPressed: () => _showQueue(context, provider),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Album art with shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailM,
                        width: 280,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Song info
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Artist name - tap to go to artist page
                  GestureDetector(
                    onTap: song.artists.isNotEmpty
                        ? () {
                            Navigator.pop(context); // Close player first
                            navigateInShell(
                              context,
                              ArtistScreen(
                                artistAlias: song.artists.first.alias,
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      song.artistsNames,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 15,
                        decoration: song.artists.isNotEmpty
                            ? TextDecoration.underline
                            : null,
                        decorationColor: Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mini Lyric
                  _buildMiniLyric(context, provider),
                  const SizedBox(height: 20),
                  // Progress bar
                  _buildProgressBar(context, provider),
                  const SizedBox(height: 12),
                  // Controls
                  _buildControls(provider),
                  const SizedBox(height: 20),
                  // Artist info card
                  if (song.artists.isNotEmpty)
                    _buildArtistCard(context, song.artists.first),
                  const SizedBox(height: 16),
                  // Song info
                  if (provider.songInfo != null)
                    _buildSongInfo(provider.songInfo!),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, PlayerProvider provider) {
    return StreamBuilder<Duration?>(
      stream: provider.player.durationStream,
      builder: (_, durationSnap) {
        final duration = durationSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: provider.player.positionStream,
          builder: (_, positionSnap) {
            final position = positionSnap.data ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: position.inMilliseconds.toDouble().clamp(
                      0,
                      duration.inMilliseconds.toDouble(),
                    ),
                    max: duration.inMilliseconds.toDouble() > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (value) =>
                        provider.seek(Duration(milliseconds: value.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls(PlayerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: provider.isShuffled ? Colors.green : Colors.white,
          ),
          onPressed: provider.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 40),
          color: Colors.white,
          onPressed: provider.playPrevious,
        ),
        StreamBuilder<PlayerState>(
          stream: provider.player.playerStateStream,
          builder: (_, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final loading = provider.isLoading;
            return Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                      color: Colors.black,
                      onPressed: provider.togglePlay,
                    ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 40),
          color: Colors.white,
          onPressed: provider.playNext,
        ),
        IconButton(
          icon: Icon(
            provider.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
            color: provider.loopMode != LoopMode.off
                ? Colors.green
                : Colors.white,
          ),
          onPressed: provider.toggleLoopMode,
        ),
      ],
    );
  }

  Widget _buildMiniLyric(BuildContext context, PlayerProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LyricScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: provider.isLoadingLyric
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
              )
            : provider.currentLyric == null ||
                  !provider.currentLyric!.hasSyncedLyrics
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Không có lời bài hát',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              )
            : StreamBuilder<Duration>(
                stream: provider.player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final currentIndex = provider.getCurrentLyricIndex(position);
                  final currentLine = currentIndex >= 0
                      ? provider.currentLyric!.lines[currentIndex].text
                      : '';
                  final nextLine =
                      currentIndex + 1 < provider.currentLyric!.lines.length
                      ? provider.currentLyric!.lines[currentIndex + 1].text
                      : '';

                  return Column(
                    children: [
                      Text(
                        currentLine.isNotEmpty ? currentLine : '♪ ♪ ♪',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (nextLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          nextLine,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, dynamic artist) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close player first
        navigateInShell(context, ArtistScreen(artistAlias: artist.alias));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (artist.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  imageUrl: artist.thumbnail!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nghệ sĩ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo(Map<String, dynamic> info) {
    final genres =
        (info['genres'] as List?)?.map((g) => g['name']).join(', ') ?? '';
    final album = info['album']?['title'] ?? '';
    final releaseDate = info['releaseDate']?.toString() ?? '';
    final listen = info['listen'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin bài hát',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (album.isNotEmpty) _buildInfoRow('Album', album),
          if (genres.isNotEmpty) _buildInfoRow('Thể loại', genres),
          if (releaseDate.isNotEmpty) _buildInfoRow('Phát hành', releaseDate),
          _buildInfoRow('Lượt nghe', _formatNumber(listen)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showQueue(BuildContext context, PlayerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Danh sách phát',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.playlist.length} bài',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey, height: 1),
              // Queue list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.playlist.length,
                  itemBuilder: (context, index) {
                    final song = provider.playlist[index];
                    final isPlaying = provider.currentIndex == index;
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          song.thumbnail,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? Colors.green : Colors.white,
                          fontWeight: isPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        song.artistsNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                      trailing: isPlaying
                          ? const Icon(Icons.equalizer, color: Colors.green)
                          : Text(
                              song.durationText,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                      onTap: () {
                        provider.playPlaylist(
                          provider.playlist,
                          startIndex: index,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
