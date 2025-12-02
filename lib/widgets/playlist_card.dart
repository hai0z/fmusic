import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const PlaylistCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.music_note,
                      size: 40,
                      color: Colors.white54,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.music_note,
                      size: 40,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
