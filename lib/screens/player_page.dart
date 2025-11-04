import 'package:flutter/material.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool isPlaying = true;
  double progress = 0.03; // 3s / 30s demo
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
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

              // Ảnh đại diện bài hát
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  "https://picsum.photos/400?tech",
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Tên bài hát và tác giả
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tech",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tech Insights",
                          style: TextStyle(
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
              const SizedBox(height: 10),

              // Thanh tiến trình
              Slider(
                value: progress,
                onChanged: (v) => setState(() => progress = v),
                activeColor: const Color(0xFF6366F1),
                inactiveColor: const Color(0xFFE2E8F0),
              ),

              // Thời lượng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("0:03", style: TextStyle(color: Color(0xFF94A3B8))),
                  Text("30:45", style: TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 24),

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
                    onPressed: () {},
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isPlaying = !isPlaying),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6366F1),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        size: 36, color: Color(0xFF475569)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded,
                        color: Color(0xFF475569)),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Dòng dưới cùng: tốc độ và chia sẻ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.timer_outlined, color: Color(0xFF475569)),
                      SizedBox(width: 6),
                      Text(
                        "1x",
                        style: TextStyle(color: Color(0xFF475569), fontSize: 16),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined,
                        color: Color(0xFF475569)),
                    label: const Text(
                      "Share",
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 16,
                      ),
                    ),
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
