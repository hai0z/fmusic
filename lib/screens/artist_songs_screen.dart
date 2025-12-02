import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/zing_mp3_api.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../main.dart';

class ArtistSongsScreen extends StatefulWidget {
  final String artistId;
  final String artistName;

  const ArtistSongsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  final List<Song> _songs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadSongs() async {
    final data = await zing.getListArtistSong(widget.artistId, '$_page', '20');
    if (mounted && data != null && data['err'] == 0) {
      final items = data['data']['items'] as List? ?? [];
      setState(() {
        _songs.addAll(items.map((e) => Song.fromJson(e)));
        _isLoading = false;
        _hasMore = items.length >= 20;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _page++;

    final data = await zing.getListArtistSong(widget.artistId, '$_page', '20');
    if (mounted && data != null && data['err'] == 0) {
      final items = data['data']['items'] as List? ?? [];
      setState(() {
        _songs.addAll(items.map((e) => Song.fromJson(e)));
        _isLoadingMore = false;
        _hasMore = items.length >= 20;
      });
    } else {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => mainScreenKey.currentState?.popScreen(),
        ),
        title: Text(widget.artistName),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 140),
              itemCount: _songs.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _songs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  );
                }

                final song = _songs[index];
                return Consumer<PlayerProvider>(
                  builder: (context, provider, _) {
                    return SongTile(
                      song: song,
                      isPlaying: provider.currentSong?.id == song.id,
                      onTap: () =>
                          provider.playPlaylist(_songs, startIndex: index),
                    );
                  },
                );
              },
            ),
    );
  }
}
