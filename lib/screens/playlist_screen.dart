import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/zing_mp3_api.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../main.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Playlist? _playlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final data = await zing.getPlaylist(widget.playlistId);
    if (mounted && data != null && data['err'] == 0) {
      setState(() {
        _playlist = Playlist.fromJson(data['data']);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.grey[900],
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => mainScreenKey.currentState?.popScreen(),
                  ),
                  title: Text(
                    _playlist!.title,
                    style: const TextStyle(fontSize: 16),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _playlist!.thumbnailM,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _playlist!.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _playlist!.artistsNames,
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_playlist!.songs.length} bài hát',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_playlist!.songs.isNotEmpty) {
                                context.read<PlayerProvider>().playPlaylist(
                                  _playlist!.songs,
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Phát tất cả'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.shuffle, color: Colors.white),
                          onPressed: () {
                            if (_playlist!.songs.isNotEmpty) {
                              final shuffled = List<Song>.from(_playlist!.songs)
                                ..shuffle();
                              context.read<PlayerProvider>().playPlaylist(
                                shuffled,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _playlist!.songs[index];
                    return Consumer<PlayerProvider>(
                      builder: (context, provider, _) {
                        return SongTile(
                          song: song,
                          isPlaying: provider.currentSong?.id == song.id,
                          onTap: () => provider.playPlaylist(
                            _playlist!.songs,
                            startIndex: index,
                          ),
                        );
                      },
                    );
                  }, childCount: _playlist!.songs.length),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
              ],
            ),
    );
  }
}
