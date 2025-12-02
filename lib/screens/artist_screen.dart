import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/zing_mp3_api.dart';
import '../models/artist.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../main.dart';
import 'playlist_screen.dart';
import 'artist_songs_screen.dart';

class ArtistScreen extends StatefulWidget {
  final String artistAlias;

  const ArtistScreen({super.key, required this.artistAlias});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Artist? _artist;
  List<Song> _songs = [];
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtist();
  }

  Future<void> _loadArtist() async {
    final data = await zing.getArtist(widget.artistAlias);
    if (mounted && data != null && data['err'] == 0) {
      final artistData = data['data'];
      setState(() {
        _artist = Artist.fromJson(artistData);
        // Get songs
        final sections = artistData['sections'] as List? ?? [];
        for (var section in sections) {
          if (section['sectionType'] == 'song') {
            _songs = (section['items'] as List? ?? [])
                .map((e) => Song.fromJson(e))
                .toList();
          }
          if (section['sectionType'] == 'playlist') {
            _playlists = section['items'] as List? ?? [];
          }
        }
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
                // Header with artist image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.grey[900],
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => mainScreenKey.currentState?.popScreen(),
                  ),
                  title: Text(
                    _artist!.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _artist!.thumbnailM,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.9),
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
                                _artist!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _artist!.followText,
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Biography
                if (_artist!.biography != null &&
                    _artist!.biography!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giới thiệu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _artist!.biography!,
                            style: TextStyle(
                              color: Colors.grey[400],
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Songs section
                if (_songs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Bài hát nổi bật',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              navigateInShell(
                                context,
                                ArtistSongsScreen(
                                  artistId: _artist!.id,
                                  artistName: _artist!.name,
                                ),
                              );
                            },
                            child: const Text(
                              'Xem tất cả',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final song = _songs[index];
                      return Consumer<PlayerProvider>(
                        builder: (context, provider, _) {
                          return SongTile(
                            song: song,
                            isPlaying: provider.currentSong?.id == song.id,
                            onTap: () => provider.playPlaylist(
                              _songs,
                              startIndex: index,
                            ),
                          );
                        },
                      );
                    }, childCount: _songs.length > 5 ? 5 : _songs.length),
                  ),
                ],

                // Playlists section
                if (_playlists.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: const Text(
                        'Album & Playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = _playlists[index];
                          return GestureDetector(
                            onTap: () {
                              navigateInShell(
                                context,
                                PlaylistScreen(
                                  playlistId: playlist['encodeId'],
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          playlist['thumbnailM'] ??
                                          playlist['thumbnail'] ??
                                          '',
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    playlist['title'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
              ],
            ),
    );
  }
}
