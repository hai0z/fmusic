import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        // Tăng saturation để màu rõ hơn
        final hsl = HSLColor.fromColor(provider.dominantColor);
        final bgColor = hsl
            .withLightness(0.25)
            .withSaturation((hsl.saturation + 0.2).clamp(0.0, 1.0))
            .toColor();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 64,
            decoration: BoxDecoration(color: bgColor),
            child: Column(
              children: [
                // Progress bar
                StreamBuilder<Duration?>(
                  stream: provider.player.durationStream,
                  builder: (_, durationSnap) {
                    final duration = durationSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: provider.player.positionStream,
                      builder: (_, positionSnap) {
                        final position = positionSnap.data ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;
                        return LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.black26,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                          minHeight: 2,
                        );
                      },
                    );
                  },
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: song.thumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                song.artistsNames,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<PlayerState>(
                          stream: provider.player.playerStateStream,
                          builder: (_, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            final loading = provider.isLoading;
                            return Row(
                              children: [
                                if (loading)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: Icon(
                                      playing ? Icons.pause : Icons.play_arrow,
                                    ),
                                    color: Colors.white,
                                    onPressed: provider.togglePlay,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next),
                                  color: Colors.white,
                                  onPressed: provider.playNext,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
