import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isFavorite = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.black87, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Now Playing",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Ảnh đại diện bài hát với Hero animation
              Hero(
                tag: 'album-art',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    audio.thumbnailUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 240,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.grey,
                          size: 80,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio.currentSong,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          audio.currentArtist,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      color:
                      isFavorite ? Colors.redAccent : const Color(0xFF94A3B8),
                      size: 28,
                    ),
                    onPressed: () =>
                        setState(() => isFavorite = !isFavorite),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Thanh tiến trình
              Slider(
                value: audio.progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  final newPosition = Duration(
                    milliseconds: (v * audio.duration.inMilliseconds).round(),
                  );
                  audio.setPosition(newPosition);
                },
                activeColor: const Color(0xFF6366F1),
                inactiveColor: const Color(0xFFE2E8F0),
              ),

              // Thời lượng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(audio.position),
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  Text(
                    _formatDuration(audio.duration),
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nút điều khiển phát nhạc
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.repeat, color: Color(0xFF475569)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        size: 36, color: Color(0xFF475569)),
                    onPressed: () {
                      audio.previousSong();
                    },
                  ),
                  GestureDetector(
                    onTap: () => audio.togglePlay(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6366F1),
                      ),
                      child: Icon(
                        audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        size: 36, color: Color(0xFF475569)),
                    onPressed: () {
                      audio.nextSong();
                    },
                  ),
                  Row(
                    children: const [
                      Icon(Icons.timer_outlined, color: Color(0xFF475569)),
                      Text(
                        "1x",
                        style: TextStyle(color: Color(0xFF475569), fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
