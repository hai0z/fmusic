import 'package:flutter/material.dart';
import 'mini_player.dart';

class ScreenWithMiniPlayer extends StatelessWidget {
  final Widget child;

  const ScreenWithMiniPlayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
      ],
    );
  }
}
