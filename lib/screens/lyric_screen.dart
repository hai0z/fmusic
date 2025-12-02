import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';

class LyricScreen extends StatefulWidget {
  const LyricScreen({super.key});

  @override
  State<LyricScreen> createState() => _LyricScreenState();
}

class _LyricScreenState extends State<LyricScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (index < 0 || !_scrollController.hasClients) return;
    if (index == _lastIndex) return;
    _lastIndex = index;

    final targetOffset = index * 60.0 - MediaQuery.of(context).size.height / 3;
    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

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

        final hsl = HSLColor.fromColor(provider.dominantColor);
        final bgColor = hsl
            .withLightness(0.15)
            .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
            .toColor();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: bgColor,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    song.artistsNames,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
              centerTitle: true,
            ),
            body: provider.isLoadingLyric
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : provider.currentLyric == null ||
                      !provider.currentLyric!.hasSyncedLyrics
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lyrics_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không có lời bài hát',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildLyricList(provider),
            bottomNavigationBar: _buildMiniControls(provider),
          ),
        );
      },
    );
  }

  Widget _buildLyricList(PlayerProvider provider) {
    return StreamBuilder<Duration>(
      stream: provider.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final currentIndex = provider.getCurrentLyricIndex(position);

        // Auto scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(currentIndex);
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          itemCount: provider.currentLyric!.lines.length,
          itemBuilder: (context, index) {
            final line = provider.currentLyric!.lines[index];
            final isActive = index == currentIndex;
            final isPast = index < currentIndex;

            return GestureDetector(
              onTap: () =>
                  provider.seek(Duration(milliseconds: line.startTime)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  line.text,
                  style: TextStyle(
                    fontSize: isActive ? 28 : 22,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : isPast
                        ? Colors.white38
                        : Colors.white60,
                    height: 1.4,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniControls(PlayerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Album art
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: provider.currentSong!.thumbnail,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          // Progress
          Expanded(
            child: StreamBuilder<Duration?>(
              stream: provider.player.durationStream,
              builder: (_, durationSnap) {
                final duration = durationSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: provider.player.positionStream,
                  builder: (_, positionSnap) {
                    final position = positionSnap.data ?? Duration.zero;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: SliderComponentShape.noOverlay,
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
                            onChanged: (v) => provider.seek(
                              Duration(milliseconds: v.toInt()),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Play/Pause
          StreamBuilder<PlayerState>(
            stream: provider.player.playerStateStream,
            builder: (_, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow, size: 32),
                color: Colors.white,
                onPressed: provider.togglePlay,
              );
            },
          ),
        ],
      ),
    );
  }
}
