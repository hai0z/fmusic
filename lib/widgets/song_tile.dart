import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: song.thumbnail,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isPlaying ? Colors.green : Colors.white,
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        song.artistsNames,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.isVip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'VIP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            song.durationText,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
