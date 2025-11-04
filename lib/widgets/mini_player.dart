import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/player');
      },
      child: Container(
        height: 70,
        color: Colors.deepPurple.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.music_note, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ":${audio.currentSong}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(audio.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: audio.togglePlay,
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
          ],
        ),
      ),
    );
  }
}
