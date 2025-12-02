import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/zing_mp3_api.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/playlist_card.dart';
import '../widgets/song_tile.dart';
import '../main.dart';
import 'playlist_screen.dart';
import 'artist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _homeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final data = await zing.getHome();
    if (mounted) {
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    final items = _homeData?['data']?['items'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      color: Colors.green,
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.black,
            title: const Text(
              'FMusic',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          // Content
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = items[index];
              return _buildSection(section);
            }, childCount: items.length),
          ),
          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    final sectionType = section['sectionType'];
    final title = section['title'] ?? '';
    final sectionItems = section['items'];

    switch (sectionType) {
      case 'banner':
        return _buildBannerSection(sectionItems as List? ?? []);
      case 'playlist':
      case 'mix':
        return _buildPlaylistSection(title, sectionItems as List? ?? []);
      case 'newRelease':
        return _buildNewReleaseSection(title, sectionItems as Map? ?? {});
      case 'RTChart':
        return _buildChartSection(title, section);
      case 'artistSpotlight':
        return _buildArtistSpotlightSection(title, sectionItems as List? ?? []);
      case 'weekChart':
        return _buildWeekChartSection(sectionItems as List? ?? []);
      case 'newReleaseChart':
        return _buildNewReleaseChartSection(title, section);
      default:
        return const SizedBox.shrink();
    }
  }

  // Banner slider
  Widget _buildBannerSection(List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              final encodeId = item['encodeId'];
              if (encodeId != null) {
                navigateInShell(context, PlaylistScreen(playlistId: encodeId));
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item['banner'] ?? item['cover'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[900]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Playlist section
  Widget _buildPlaylistSection(String title, List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return PlaylistCard(
                title: item['title'] ?? '',
                subtitle: item['artistsNames'] ?? item['sortDescription'] ?? '',
                imageUrl: item['thumbnailM'] ?? item['thumbnail'] ?? '',
                onTap: () {
                  navigateInShell(
                    context,
                    PlaylistScreen(playlistId: item['encodeId']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // New release section
  Widget _buildNewReleaseSection(String title, Map items) {
    final allSongs = items['all'] as List? ?? [];
    final vPopSongs = items['vPop'] as List? ?? [];
    final otherSongs = items['others'] as List? ?? [];

    if (allSongs.isEmpty) return const SizedBox.shrink();

    return _NewReleaseSection(
      title: title,
      allSongs: allSongs,
      vPopSongs: vPopSongs,
      otherSongs: otherSongs,
    );
  }

  // Chart section (RTChart)
  Widget _buildChartSection(String title, Map<String, dynamic> section) {
    final chartItems = section['chart']?['items'] as Map? ?? {};
    final rankingItems = section['items'] as List? ?? [];

    if (rankingItems.isEmpty) return const SizedBox.shrink();

    final songs = rankingItems.take(5).map((e) => Song.fromJson(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              const Text(
                '#zingchart',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              return _ChartSongTile(
                rank: index + 1,
                song: song,
                isPlaying: provider.currentSong?.id == song.id,
                onTap: () => provider.playPlaylist(songs, startIndex: index),
              );
            },
          );
        }),
      ],
    );
  }

  // Artist spotlight
  Widget _buildArtistSpotlightSection(String title, List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final artist = items[index];
              return GestureDetector(
                onTap: () {
                  navigateInShell(
                    context,
                    ArtistScreen(artistAlias: artist['alias'] ?? ''),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              artist['thumbnailM'] ?? artist['thumbnail'] ?? '',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Week chart section
  Widget _buildWeekChartSection(List items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'BXH Tuần',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final chart = items[index];
              return _WeekChartCard(chart: chart);
            },
          ),
        ),
      ],
    );
  }

  // New release chart
  Widget _buildNewReleaseChartSection(
    String title,
    Map<String, dynamic> section,
  ) {
    final items = section['items'] as List? ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    final songs = items.take(5).map((e) => Song.fromJson(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title.isNotEmpty ? title : 'BXH Nhạc Mới',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              return SongTile(
                song: song,
                isPlaying: provider.currentSong?.id == song.id,
                onTap: () => provider.playPlaylist(songs, startIndex: index),
              );
            },
          );
        }),
      ],
    );
  }
}

// New Release Section với tabs
class _NewReleaseSection extends StatefulWidget {
  final String title;
  final List allSongs;
  final List vPopSongs;
  final List otherSongs;

  const _NewReleaseSection({
    required this.title,
    required this.allSongs,
    required this.vPopSongs,
    required this.otherSongs,
  });

  @override
  State<_NewReleaseSection> createState() => _NewReleaseSectionState();
}

class _NewReleaseSectionState extends State<_NewReleaseSection> {
  int _selectedTab = 0;

  List get _currentSongs {
    switch (_selectedTab) {
      case 1:
        return widget.vPopSongs;
      case 2:
        return widget.otherSongs;
      default:
        return widget.allSongs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _currentSongs.take(5).map((e) => Song.fromJson(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTab('Tất cả', 0),
              const SizedBox(width: 8),
              _buildTab('Việt Nam', 1),
              const SizedBox(width: 8),
              _buildTab('Quốc tế', 2),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Songs
        ...songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              return SongTile(
                song: song,
                isPlaying: provider.currentSong?.id == song.id,
                onTap: () => provider.playPlaylist(songs, startIndex: index),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Chart song tile với ranking
class _ChartSongTile extends StatelessWidget {
  final int rank;
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;

  const _ChartSongTile({
    required this.rank,
    required this.song,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: rank == 1
                    ? Colors.blue
                    : rank == 2
                    ? Colors.green
                    : rank == 3
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: song.thumbnail,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? Colors.green : Colors.white,
          fontWeight: FontWeight.w500,
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
          : null,
    );
  }
}

// Week chart card
class _WeekChartCard extends StatelessWidget {
  final Map<String, dynamic> chart;

  const _WeekChartCard({required this.chart});

  @override
  Widget build(BuildContext context) {
    final items = chart['items'] as List? ?? [];
    final country = chart['country'] ?? '';

    String title;
    Color bgColor;
    switch (country) {
      case 'vn':
        title = 'Việt Nam';
        bgColor = Colors.red.shade900;
        break;
      case 'us':
        title = 'US-UK';
        bgColor = Colors.blue.shade900;
        break;
      case 'korea':
        title = 'K-Pop';
        bgColor = Colors.purple.shade900;
        break;
      default:
        title = country.toUpperCase();
        bgColor = Colors.grey.shade900;
    }

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to week chart detail
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor, bgColor.withValues(alpha: 0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        song['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
