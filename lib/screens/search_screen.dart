import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/zing_mp3_api.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Song> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final data = await zing.searchAll(query);
    if (mounted) {
      setState(() {
        _results = (data?['data']?['songs'] as List? ?? [])
            .map((e) => Song.fromJson(e))
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm bài hát, nghệ sĩ...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _search,
            onChanged: (_) => setState(() {}),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : !_hasSearched
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 80, color: Colors.grey[700]),
                      const SizedBox(height: 16),
                      Text(
                        'Tìm kiếm bài hát yêu thích',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy kết quả',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final song = _results[index];
                    return Consumer<PlayerProvider>(
                      builder: (context, provider, _) {
                        return SongTile(
                          song: song,
                          isPlaying: provider.currentSong?.id == song.id,
                          onTap: () => provider.playPlaylist(
                            _results,
                            startIndex: index,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
